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

	this(Options options) {
		__options = options;
	}

/*
	auto run(LuaObject self, LuaObject exe, LuaTable args) {
		assert(0);
	}

	auto run(LuaObject self, string exe, string args, string stdin) {

	}
*/
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
		auto t = new TestFunctions(Options());
		auto ret = t.run("echo", "asdf");
		assert(ret.Output.strip == "asdf");
		assert(ret.ReturnCode == 0);
	}

	/** Return true if the provided code throws an error; false otherwise. */
	//nothrow
	bool throws(string code) const {
		// pcall takes care of Lua errors, and the try/catch handled D exceptions.
		// Why isn't it catching anything?
		// TODO: I can't execute in a state that's already executing code; I need to
		// create a new LuaState, init it(?), then run the code on it. That's going
		// to make the statement largely worthless, won't it?

		try {
			import bluejay.execution_state : ExecutionState;
			auto lua = new ExecutionState(__options);
			auto failed = lua.doString("return pcall(" ~ code.dup ~ ")")[0];
			// TODO: If I make this `return(!ret.to!bool)` I get an InvalidMemoryOperationError
			//return ( ret.to!bool);
			return ret;
		} catch (Exception ex) {
			return true;
		}
		assert(0);
	}
}

/** Generic helper functions. */
struct UtilFunctions {
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

	@test("UtilFunctions.dirExists correctly reports whehter a directory exists.")
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
				"A directory that should not exist is present. Cannot test UtilFunction's removeDir.");

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
		return dirName;
	}

	@test("UtilFunctions.getTempDir creates a temporary directory.")
	unittest {
		// TODO: Grab list of directories in the temp dir, then verify something
		// new was created.
		import std.file : exists, isDir;
		auto u = UtilFunctions();
		auto dir = u.getTempDir;
		assert(dir.exists && dir.isDir);
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
		// TODO: Grab list of files in the temp dir, then verify something
		// new was created.
		import std.file : exists, isFile;
		auto u = UtilFunctions();
		auto f = u.getTempFile;
		assert(f.exists && f.isFile);
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

	// TODO: Pretty-print Lua table.
}
