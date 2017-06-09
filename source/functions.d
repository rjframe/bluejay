/** Contains the functions that will be accessible in bluejay scripts. */
module bluejay.functions;

import luad.all;

/** Return values from executing a process.

	This must remain at the top-level to avoid access violations.
*/
struct ExecuteReturns {
	int ReturnCode;
	string Output;
	this(int r, string o) { ReturnCode = r; Output = o; }
}

/** Functions to run tests. */
struct TestFunctions {
	// It looks like this/self is being passed explicitly into the functions.
/*
	auto run(LuaObject self, LuaObject exe, LuaTable args) {
		assert(0);
	}

	auto run(LuaObject self, string exe, string args, string stdin) {

	}
*/
	@trusted
	auto run(LuaObject self, string command, string args) {
		import std.process : executeShell;
		auto output = executeShell(command ~ " " ~ args);
		return ExecuteReturns(output.status, output.output.dup);
	}

	@trusted
	unittest {
		import std.string : strip;

		auto t = TestFunctions();
		auto ret = t.run(LuaObject(), "echo", "asdf");
		assert(ret.Output.strip == "asdf");
		assert(ret.ReturnCode == 0);
	}
}

/** Generic helper functions. */
struct UtilFunctions {
	@safe
	string strip(LuaObject self, string str) {
		import std.string : strip;
		return str.strip;
	}

	@safe
	unittest {
		auto u = UtilFunctions();
		assert(u.strip(LuaObject(), " asdf\t ") == "asdf");
	}

	@safe
	bool fileExists(LuaObject self, string path) {
		import std.file : exists, isFile;
		return (path.exists && path.isFile);
	}

	@safe
	unittest {
		auto u = UtilFunctions();
		assert(u.fileExists(LuaObject(), "source/app.d"));
	}

	@safe
	bool dirExists(LuaObject self, string path) {
		import std.file : exists, isDir;
		return (path.exists && path.isDir);
	}

	@safe
	unittest {
		auto u = UtilFunctions();
		assert(u.dirExists(LuaObject(), "source"));
	}

	/** Recursively deletes the specified directory. */
	void removeDir(LuaObject self, string path) {
		import std.file : rmdirRecurse;
		rmdirRecurse(path);
	}

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

	@safe
	void removeFile(LuaObject self, string path) {
		import std.file : remove;
		remove(path);
	}

	@safe
	unittest {
		import std.file : exists, isFile, tempDir, write;

		immutable filePath = tempDir() ~ "util-removefile-this";

		filePath.write("a");
		assert(filePath.exists && filePath.isFile,
				"Failed to create a file to test UtilFunction's removeDir.");

		auto u = UtilFunctions();
		u.removeFile(LuaObject(), filePath);
		assert(! filePath.exists, "Failed to delete a file.");
	}

	/** Creates a directory in the system's temporary directory and returns
		the path.
	*/
	string getTempDir() {
		import std.file : exists, mkdirRecurse, tempDir;

		string dirName = "";
		while (true) {
			dirName = tempDir() ~ getName();
			if (! dirName.exists) break;
		}

		mkdirRecurse(dirName);
		return dirName;
	}

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
	string getTempFile() {
		import std.file : exists, tempDir, write;

		string fileName = "";
		while (true) {
			fileName = tempDir() ~ getName() ~ ".tmp";
			if (! fileName.exists) break;
		}

		fileName.write(['\0']);
		return fileName;
	}

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
	private auto getName() {
		import std.algorithm : fill;
		import std.conv : to;
		import std.random : Random, randomCover, unpredictableSeed;

		enum dstring letters = "abcdefghijklmnopqrstuvwxyz";

		dchar[8] name;
		fill(name[], randomCover(letters, Random(unpredictableSeed)));
		return name.to!string();
	}

	@safe
	unittest {
		import std.file : exists;
		auto u = UtilFunctions();
		assert(! exists(u.getName));
	}

	// TODO: Pretty-print Lua table.
}
