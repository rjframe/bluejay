/** Contains the functions that will be accessible in bluejay scripts. */
module bluejay.functions;

import luad.all;
import tested : test = name;

/** Return values from executing a process.

  This must remain at the top-level to avoid access violations.
 */
struct ExecuteReturns {
    int ReturnCode;
    string Output;

    @safe pure nothrow @nogc
    this(int r, string o) { ReturnCode = r; Output = o; }
}

/** Functions to run tests. */
class TestFunctions {
    import bluejay.execution_state : Options;
    private Options __options;
    private LuaState __lua;

    @safe pure nothrow @nogc
    this(ref LuaState lua, Options options) {
        __options = options;
        __lua = lua;
    }

    // Optional parameter: args.
    @safe
    auto run(string command, string[] args...) const {
        import std.process : executeShell;
        if (args.length > 1)
            throw new Exception("Too many arguments given for args.");

        string arg;
        if (args.length == 1) arg = args[0];

        auto output = executeShell(command ~ " " ~ arg);
        return ExecuteReturns(output.status, output.output);
    }

    @test("TestFunctions.run executes a file.")
    unittest {
        import std.string : strip;
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() @safe {
            auto ret = t.run("echo", "asdf");
            assert(ret.Output.strip == "asdf");
            assert(ret.ReturnCode == 0);
        } func();
    }

    // Optional parameter: args.
    auto spawn(string command, string[] args...) {
        import std.process : spawnShell;
        if (args.length > 1)
            throw new Exception("Too many arguments given for args.");

        string arg;
        if (args.length == 1) arg = args[0];
        return spawnShell(command ~ " " ~ arg).processID;
    }

    @test("TestFunctions.spawn executes a file and returns its PID.")
    unittest {
        import std.string : strip;
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());
        auto ret = t.spawn("echo", "asdf");
        assert(ret > 0);
    }

    /** Return true if the provided code throws an error; false otherwise.

        pcall takes care of Lua errors, and the try/catch handled D exceptions.
    */
    nothrow
    bool throws(string code) {
        import luad.error : LuaErrorException;
        try {
            auto ret = __lua.doString("return pcall(" ~ __pcallFunc(code)
                    ~ ")")[0];
            return (! ret.to!bool);
        } catch (LuaErrorException ex) {
            return true;
        } catch (Exception ex) {
            return true;
        }
        assert(0);
    }

    @test("TestFunctions.throws returns true when Lua throws.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() nothrow {
            assert(t.throws("assert(true)"));
        } func();
    }

    @test("TestFunctions.throws returns false when Lua does not throw.")
    unittest {
        import bluejay.execution_state : ExecutionState;
        auto lua = new ExecutionState(Options());
        auto t = new TestFunctions(lua, Options());

        void func() nothrow {
            assert(! t.throws("getfenv()"));
        } func();
    }

    @test("Issue 1: TestFunctions.throws properly handles host function.")
    unittest {
        import bluejay.execution_state;
        auto lua = new ExecutionState(Options());
        auto t = new TestFunctions(lua, Options());

        void func() nothrow {
            assert(t.throws("Util:listDir('test/nonexistent')"));
        } func();
    }

    /** Convert a function call to arguments for the pcall function. */
    // TODO: This needs to be well-tested with error handling.
    // Since we're testing for failure, we can't let this fail due to bad input.
    @safe pure
    private string __pcallFunc(string code) const {
        import std.algorithm.searching : balancedParens, findSplit;
        import std.algorithm.iteration : map, splitter;
        import std.array : join;
        import std.string : strip;

        if (! balancedParens(code, '(', ')'))
            throw new Exception("Missing parenthesis in function call.");

        auto func = code.findSplit("(");
        string args = func[2]
            .splitter(',')
            .map!(a => a.strip)
            .join(',');

        // Remove the outermost closing parenthesis.
        if (args[$-1] != ')')
            throw new Exception("Function is missing a closing parenthesis.");

        args = args[0 .. $-1];
        if (args.length == 0) {
            return func[0];
        } else return [func[0], args].join(',');
    }

    @test("TestFunctions.pcallFunc returns the currect pcall arguments with " ~
            "no parameters.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() @safe pure {
            auto ret = t.__pcallFunc("getfenv()");
            assert(ret == "getfenv");
        } func();
    }

    @test("TestFunctions.pcallFunc returns the currect pcall arguments with " ~
            "one parameter.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() @safe pure {
            auto ret = t.__pcallFunc("print('some string')");
            assert(ret == "print,'some string'");
        }
    }

    @test("TestFunctions.pcallFunc returns the currect pcall arguments with " ~
            "two parameters.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() @safe pure {
            auto ret = t.__pcallFunc("print('some string', some_var)");
            assert(ret == "print,'some string',some_var");
        }
    }

    @test("Issue 1: TestFunctions.pcallFunc properly handles host function.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() @safe pure {
            auto ret = t.__pcallFunc("Util:listDir('test/nonexistent')");
            assert(ret == "Util:listDir,'test/nonexistent'");
        }
    }
}

/** Generic helper functions. */
struct UtilFunctions {
    LuaState __lua;

    @safe pure nothrow @nogc
    this(ref LuaState lua) {
        __lua = lua;
    }

    @safe pure
    string strip(ref LuaObject self, string str) const {
        import std.string : strip;
        return str.strip;
    }

    @test("UtilFunctions.strip removes whitespace surrounding text.")
    @safe
    unittest {
        auto u = UtilFunctions();
        auto l = LuaObject();

        void func() pure {
            assert(u.strip(l, "\n asdf\t ") == "asdf");
        } func();
    }

    @safe pure
    string[] split(ref LuaObject self, string str) const {
        import std.string : splitLines;
        return str.splitLines;
    }

    @test("UtilFunctions.split properly splits a string by newlines.")
    @safe
    unittest {
        auto l = LuaObject();
        auto u = UtilFunctions();
        auto str = "1 and\n2 and\n3 and\ndone.";

        void func() pure {
            auto ret = u.split(l, str);

            assert(ret[0] == "1 and", "Failed on first line.");
            assert(ret[1] == "2 and", "Failed on second line.");
            assert(ret[2] == "3 and", "Failed on third line.");
            assert(ret[3] == "done.", "Failed on fourth line.");
        } func();
    }

    string cwd() const {
        import std.file : getcwd;
        return getcwd();
    }

    @test("UtilFunctions.cwd returns the application's current working directory.")
    unittest {
        import std.file : getcwd;
        auto u = UtilFunctions();
        assert(u.cwd() == getcwd);
    }

    /+ Access violation. Other attempts have OutOfMemoryError and
       MemoryOperationException.

    // baseDir is the directory containing the script, which will generally be
    // more useful than cwd().
    string baseDir() {
        import std.path : dirName;
        return __scriptDir.dirName;
    }

    @test("UtilFunctions.baseDir returns a directory name.")
    unittest {
        import std.path : isDir;
        import bluejay.execution_state : ExecutionState, Options;
        auto lua = new ExecutionState(Options(), "/some/dir");
        auto u = UtilFunctions(lua);
        // Note that the actual value of baseDir is platform-specific.
        // There's no reason to care about the actual value.
        assert(u.baseDir().length > 0);
        assert(u.baseDir().isDir, "The returned value is not a directory.");
    }
    +/

    // One optional param: filter.
    string[] listDir(ref LuaObject self, string dir, string[] filter...) const {
        import std.file;

        if (filter.length > 1)
            throw new Exception(
                    "Too many arguments passed to listDir(dir, [filter]).");
        if (! dir.exists)
            throw new Exception("The directory " ~ dir ~ " does not exist.");
        string[] files;

        if (dir.isFile) {
            files ~= dir;
            return files;
        }

        auto f = "*";
        if (filter.length == 1) {
            f = filter[0];
        }
        foreach (entry; dirEntries(dir, f, SpanMode.shallow)) {
            files ~= entry;
        }
        return files;
    }

    @test("UtilFunctions.listDir returns directory listing without filter.")
    unittest {
        import std.array : array;
        import std.file : getcwd, dirEntries, SpanMode;
        auto l = LuaObject();
        auto u = UtilFunctions();
        auto dir = getcwd();
        string[] f = [];
        assert(u.listDir(l, dir, f) == dirEntries(dir, SpanMode.shallow).array);
    }

    @test("UtilFunctions.listDir returns a filtered directory listing.")
    unittest {
        import std.array : array;
        import std.file : getcwd, dirEntries, SpanMode;
        auto l = LuaObject();
        auto u = UtilFunctions();
        auto dir = getcwd();
        string[] f = ["*.json"];
        assert(u.listDir(l, dir, f) == dirEntries(dir, f[0], SpanMode.shallow).array);
    }

    @safe
    string fixPath(ref LuaObject self, string path) const {
        import std.array : array;
        import std.path : asNormalizedPath;
        return path.asNormalizedPath.array;
    }

    version(Windows) {
        @test("Windows: UtilFunctions.fixPath converts POSIX path to Windows " ~
                "path.")
        unittest {
            auto l = LuaObject();
            auto u = UtilFunctions();
            assert(u.fixPath(l, "/some/dir") == "\\some\\dir");
            assert(u.fixPath(l, "/some/dir/") == "\\some\\dir");
        }
    } else version(Posix) {
        @test("POSIX: UtilFunctions.fixPath converts Windows path to POSIX path.")
        unittest {
            auto l = LuaObject();
            auto u = UtilFunctions();
            assert(u.fixPath(l, "\\some\\dir") == "/some/dir");
            assert(u.fixPath(l, "\\some\\dir\\") == "/some/dir");
            assert(u.fixPath(l, "c:\\some\\dir") == "/some/dir");
        }
    }

    @safe
    bool fileExists(ref LuaObject self, string path) const {
        import std.file : exists, isFile;
        return (path.exists && path.isFile);
    }

    @test("UtilFunctions.fileExists correctly reports whether a file exists.")
    @safe
    unittest {
        auto l = LuaObject();
        auto u = UtilFunctions();
        assert(u.fileExists(l, "source/app.d"));
        assert(! u.fileExists(l, "source/this-is-not-there.qwe"));
    }

    @safe
    bool dirExists(ref LuaObject self, string path) const {
        import std.file : exists, isDir;
        return (path.exists && path.isDir);
    }

    @test("UtilFunctions.dirExists correctly reports whether a directory exists.")
    @safe
    unittest {
        auto l = LuaObject();
        auto u = UtilFunctions();
        assert(u.dirExists(l, "source"));
        assert(! u.dirExists(l, "nodirhere"));
    }

    /** Recursively deletes the specified directory. */
    void removeDir(ref LuaObject self, string path) const {
        import std.file : exists, isDir, rmdirRecurse;
        if (path.exists && path.isDir) rmdirRecurse(path);
    }

    @test("UtilFunctions.removeDir correctly removes a directory.")
    unittest {
        import std.file : exists, isDir, mkdir, tempDir;
        import std.path : dirSeparator;

        immutable dirPath = tempDir() ~ dirSeparator ~ "util-removedir-this";
        mkdir(dirPath);
        assert(dirPath.exists && dirPath.isDir,
                "Failed to create a directory to test UtilFunction's removeDir.");

        auto l = LuaObject();
        auto u = UtilFunctions();
        u.removeDir(l, dirPath);
        assert(! dirPath.exists, "Failed to delete a directory.");
    }

    @test("UtilFunctions.removeDir on a nonexistent path does not throw.")
    unittest {
        import std.file : exists, tempDir;
        import std.path : dirSeparator;

        immutable dirPath = tempDir() ~ dirSeparator ~  "this-dir-is-not-here";
        assert(! dirPath.exists,
                "A directory that should not exist is present. " ~
                "Cannot test UtilFunction's removeDir.");

        auto l = LuaObject();
        auto u = UtilFunctions();
        u.removeDir(l, dirPath);
    }

    @safe nothrow
    bool removeFile(ref LuaObject self, string path) const {
        import std.file : exists, remove;

        try {
            if (path.exists) remove(path);
        } catch (Exception) /* FileException */ {}
        return (! path.exists);
    }

    @test("UtilFunctions.removeFile deletes a file and returns true.")
    @safe
    unittest {
        import std.file : exists, isFile, tempDir, write;
        import std.path : dirSeparator;

        immutable filePath = tempDir() ~ dirSeparator ~ "util-removefile-this";
        filePath.write("a");
        assert(filePath.exists && filePath.isFile,
                "Failed to create a file to test UtilFunction's removeDir.");

        void func() nothrow {
            auto l = LuaObject();
            auto u = UtilFunctions();
            assert(u.removeFile(l, filePath), "removeFile failed.");
        } func();

        assert(! filePath.exists, "Failed to delete a file.");
    }

    @test("UtilFunctions.removeFile does not throw if the file doesn't exist.")
    @safe
    unittest {
        import std.file : exists, isFile, tempDir;

        immutable filePath = tempDir() ~ "this-file-should-not-be-here.txt";
        assert(! filePath.exists,
                "A file that should not exist is present. Cannot test removeFile.");
        void func() nothrow {
            auto l = LuaObject();
            auto u = UtilFunctions();
            assert(u.removeFile(l, filePath), "removeFile failed.");
        } func();
    }

    void writeFile(ref LuaObject self, string path, string content) const {
        import std.stdio : toFile;
        content.toFile(path);
    }

    @test("UtilFunctions.writeFile writes text to the specified file.")
    unittest {
        auto l = LuaObject();
        auto u = UtilFunctions();
        auto f = u.__getName;
        u.writeFile(l, f, "This is a test.");

        import std.file : readText, remove;
        string text = readText(f);
        remove(f);
        assert(text == "This is a test.");
    }

    @safe
    string readFile(ref LuaObject self, string path) const {
        import std.file : readText;
        return readText(path);
    }

    @test("UtilFunctions.readFile reads the text of a file.")
    @safe
    unittest {
        import std.file : write, remove;

        auto l = LuaObject();
        auto u = UtilFunctions();
        auto f = u.__getName;
        f.write("This is a test.");
        auto text = u.readFile(l, f);
        remove(f);
        assert(text == "This is a test.");
    }

    void copyFile(ref LuaObject self, string source, string dest) {
        import std.file : copy;
        copy(source, dest);
    }

    @test("UtilFunctions.copyFile copies a file.")
    unittest {
        import std.file : exists, tempDir, readText, write;
        import std.path : dirSeparator;
        auto l = LuaObject();
        auto u = UtilFunctions();
        auto src = tempDir ~ dirSeparator ~ u.__getName;
        auto dest = tempDir ~ dirSeparator ~ u.__getName;

        assert(! dest.exists, "The destination file already exists. " ~
                "Cannot test UtilFunctions.copyFile.");

        src.write("some text");
        u.copyFile(l, src, dest);
        assert(dest.exists, "Failed to copy the file.");
        assert(dest.readText == "some text", "File improperly copied.");
    }

    /** Creates a directory in the system's temporary directory and returns
      the path.
     */
    // In DMD 2.075.0+ this can be @safe.
    string getTempDir() const {
        import std.file : exists, mkdirRecurse, tempDir;
        import std.path : dirSeparator;

        string dirName = "";
        while (true) {
            dirName = tempDir() ~ dirSeparator ~ __getName();
            if (! dirName.exists) break;
        }

        mkdirRecurse(dirName);
        return dirName ~ dirSeparator;
    }

    @test("UtilFunctions.getTempDir creates a temporary directory.")
    unittest {
        import std.file : exists, isDir, rmdirRecurse;
        auto u = UtilFunctions();
        auto dir = u.getTempDir;
        assert(dir.exists && dir.isDir);

        rmdirRecurse(dir);
    }

    /** Creates a file in the system's temporary directory and returns the
        path.
     */
    @safe
    string getTempFile() const {
        import std.file : exists, tempDir, write;
        import std.path : dirSeparator;

        string fileName = "";
        while (true) {
            fileName = tempDir() ~ dirSeparator ~ __getName() ~ ".tmp";
            if (! fileName.exists) break;
        }

        fileName.write(['\0']);
        return fileName;
    }

    @test("UtilFunctions.getTempFile creates a temporary file.")
    @safe
    unittest {
        import std.file : exists, isFile, remove;
        auto u = UtilFunctions();
        auto f = u.getTempFile;
        assert(f.exists && f.isFile);

        remove(f);
    }

    @safe
    private auto __getName() const {
        import std.algorithm : fill;
        import std.conv : to;
        import std.random : Random, randomCover, unpredictableSeed;

        enum dstring letters = "abcdefghijklmnopqrstuvwxyz";

        dchar[8] name;
        fill(name[], randomCover(letters, Random(unpredictableSeed)));
        return name.to!string();
    }

    @test("UtilFunctions.__getName returns the name of a file that doesn't exist.")
    @safe
    unittest {
        import std.file : exists;
        auto u = UtilFunctions();
        assert(! exists(u.__getName));
    }

    // We have an optional parameter for maxLength.
    void pprint(ref LuaObject self, LuaObject obj, int[] params...) const {
        if (params.length == 0) {
            __pprint(self, obj, 4, 1);
        } else if (params.length == 1) {
            __pprint(self, obj, params[0], 1);
        } else {
            throw new Exception("Too many arguments were provided to pprint.");
        }
    }

    private void __pprint(ref LuaObject self, LuaObject obj, int maxLevel,
            int indent) const {
        if (maxLevel == 0) return;

        import std.stdio : write, writeln;
        if (obj.typeName != "table") {
            writeln(obj.toString);
            return;
        }
        auto tbl = obj.to!LuaTable;

        import std.range : repeat, take;
        import std.conv : text;
        auto spaces = ' '.repeat().take(indent*4).text;
        foreach (LuaObject key, LuaObject val; tbl) {
            if (val.typeName == "table") {
                write(spaces, key, ":");
                if (maxLevel == 1) writeln(" {table}");
                else writeln();

                __pprint(self, val, maxLevel-1, indent+1);
            } else {
                writeln(spaces, key, ": ", val.toString);
            }
        }
    }
}

/** Functions to manage the test script. */
class ScriptFunctions {
    private LuaState __lua;

    @safe pure nothrow @nogc
    this(ref LuaState lua) {
        __lua = lua;
    }

    // One optional param: returnCode.
    void exit(int[] params...) {
        if (params.length > 1)
            throw new Exception("Too many arguments passed to exit([return code]).");
        int returnCode = params.length == 0 ? 0 : params[0];

        //import std.conv : text;
        //import luad.c.all : luaopen_os;
        //luaopen_os(__lua.state);
        __lua.doString("cleanup() return");
       //__lua.doString("os.exit(" ~ returnCode.text ~ ")");
    }
}
