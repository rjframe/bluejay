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
    this(int r, string o) { ReturnCode = r; Output = o; }
}

/** Functions to run tests. */
class TestFunctions {
    import bluejay.execution_state : Options;
    private Options __options;
    private LuaState __lua;

    this(ref LuaState lua, Options options) {
        __options = options;
        __lua = lua;
    }

    @trusted
    auto run(string command, string args) const {
        import std.process : executeShell;
        auto output = executeShell(command ~ " " ~ args);
        return ExecuteReturns(output.status, output.output.dup);
    }

    @test("TestFunctions.run executes a file.")
    @trusted
    unittest {
        import std.string : strip;

        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());
        auto ret = t.run("echo", "asdf");
        assert(ret.Output.strip == "asdf");
        assert(ret.ReturnCode == 0);
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

    /** Convert a function call to arguments for the pcall function. */
    // TODO: This needs to be well-tested with error handling.
    // Since we're testing for failure, we can't let this fail due to bad input...
    @safe pure
    private string __pcallFunc(string code) {
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

    @test("pcallFunc returns the currect pcall arguments with no parameters.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());

        void func() @safe pure {
            auto ret = t.__pcallFunc("getfenv()");
            assert(ret == "getfenv");
        } func();
    }

    @test("pcallFunc returns the currect pcall arguments with one parameter.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());
        auto ret = t.__pcallFunc("print('some string')");
        assert(ret == "print,'some string'");
    }

    @test("pcallFunc returns the currect pcall arguments with two parameters.")
    unittest {
        auto lua = new LuaState();
        auto t = new TestFunctions(lua, Options());
        auto ret = t.__pcallFunc("print('some string', some_var)");
        assert(ret == "print,'some string',some_var");
    }
}

/** Generic helper functions. */
struct UtilFunctions {
    LuaState __lua;

    this(LuaState lua) {
        __lua = lua;
    }

    @safe
    string strip(LuaObject self, string str) const {
        import std.string : strip;
        return str.strip;
    }

    @test("UtilFunctions.strip removes whitespace surrounding text.")
    @safe
    unittest {
        auto u = UtilFunctions();
        assert(u.strip(LuaObject(), " asdf\t ") == "asdf");
    }

    @safe
    bool fileExists(LuaObject self, string path) const {
        import std.file : exists, isFile;
        return (path.exists && path.isFile);
    }

    @test("UtilFunctions.fileExists correctly reports whether a file exists.")
    @safe
    unittest {
        auto u = UtilFunctions();
        assert(u.fileExists(LuaObject(), "source/app.d"));
        assert(! u.fileExists(LuaObject(), "source/this-is-not-there.qwe"));
    }

    @safe
    bool dirExists(LuaObject self, string path) const {
        import std.file : exists, isDir;
        return (path.exists && path.isDir);
    }

    @test("UtilFunctions.dirExists correctly reports whether a directory exists.")
    @safe
    unittest {
        auto u = UtilFunctions();
        assert(u.dirExists(LuaObject(), "source"));
        assert(! u.dirExists(LuaObject(), "nodirhere"));
    }

    /** Recursively deletes the specified directory. */
    void removeDir(LuaObject self, string path) const {
        import std.file : exists, isDir, rmdirRecurse;
        if (path.exists && path.isDir) rmdirRecurse(path);
    }

    @test("UtilFunctions.removeDir correctly removes a directory.")
    unittest {
        import std.file : exists, isDir, mkdir, tempDir;

        immutable dirPath = tempDir() ~ "util-removedir-this";
        mkdir(dirPath);
        assert(dirPath.exists && dirPath.isDir,
                "Failed to create a directory to test UtilFunction's removeDir.");

        auto u = UtilFunctions();
        u.removeDir(LuaObject(), dirPath);
        assert(! dirPath.exists, "Failed to delete a directory.");
    }

    @test("UtilFunctions.removeDir on a nonexistent path does not throw.")
    unittest {
        import std.file : exists, tempDir;

        immutable dirPath = tempDir() ~ "this-dir-is-not-here";
        assert(! dirPath.exists,
                "A directory that should not exist is present. " ~
                "Cannot test UtilFunction's removeDir.");

        auto u = UtilFunctions();
        u.removeDir(LuaObject(), dirPath);
    }

    @safe nothrow
    bool removeFile(LuaObject self, string path) const {
        import std.file : exists, remove;
        try {
            remove(path);
            return true;
        } catch (Exception) /* FileException */ {
            // If the file didn't exist, return true; if we failed to delete it,
            // return true;
            return (! path.exists);
        }
    }

    @test("UtilFunctions.removeFile deletes a file.")
    @safe
    unittest {
        import std.file : exists, isFile, tempDir, write;

        immutable filePath = tempDir() ~ "util-removefile-this";
        filePath.write("a");
        assert(filePath.exists && filePath.isFile,
                "Failed to create a file to test UtilFunction's removeDir.");

        void func() nothrow {
            auto u = UtilFunctions();
            u.removeFile(LuaObject(), filePath);
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
            auto u = UtilFunctions();
            u.removeFile(LuaObject(), filePath);
        } func();
    }

    /** Creates a directory in the system's temporary directory and returns
      the path.
     */
    string getTempDir() const {
        import std.file : exists, mkdirRecurse, tempDir;

        string dirName = "";
        while (true) {
            dirName = tempDir() ~ __getName();
            if (! dirName.exists) break;
        }

        mkdirRecurse(dirName);
        import std.path : dirSeparator;
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

        string fileName = "";
        while (true) {
            fileName = tempDir() ~ __getName() ~ ".tmp";
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
/+
    string[] getFilesInDir(string dirName, string filter = "") {
        import std.file : dirEntries;
    }
+/

    // We have an optional parameter for maxLength.
    void pprint(LuaObject self, LuaObject obj, int[] params...) {
        if (params.length == 0) {
            __pprint(self, obj, 4, 1);
        } else if (params.length == 1) {
            __pprint(self, obj, params[0], 1);
        } else {
            throw new Exception("Too many arguments were provided to pprint.");
        }
    }

    private void __pprint(LuaObject self, LuaObject obj, int maxLevel,
            int indent) {
        if (maxLevel == 0) return;

        import std.stdio : write, writeln;
        auto tbl = cast(LuaTable) obj;
        if (tbl.typeName != "table") {
            // Not a table; we'll just print it as a string.
            writeln(tbl.toString);
            return;
        }

        import std.range : repeat, take;
        import std.conv : text;
        auto spaces = ' '.repeat().take(indent*4).text;
        foreach (LuaObject key, LuaObject val; tbl) {
            if (val.typeName == "table") {
                write(spaces, key, ":");
                if (maxLevel == 1) writeln(" [table]");
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
    import bluejay.execution_state : Options;
    private Options __options;
    private LuaState __lua;

    this(ref LuaState lua, Options options) {
        __options = options;
        __lua = lua;
    }

    void exit(int returnCode = 0) {
        import std.conv : text;
        //luaopen_os(__lua.state);
        __lua.doString("cleanup()");
       __lua.doString("os.exit(" ~ returnCode.text ~ ")");
    }
}
