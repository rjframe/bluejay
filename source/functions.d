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

	auto run(LuaObject self, LuaObject command, LuaObject args) {
		// TODO: This needs to take input to pass to the command's STDIN as well.
		import std.process : executeShell;
		auto output = executeShell(command.toString() ~ " " ~ args.toString());
		return ExecuteReturns(output.status, output.output.dup);
	}
}

/** Generic helper functions. */
struct UtilFunctions {
	@safe
	string strip(LuaObject self, LuaObject str) {
		import std.string : strip;
		return str.toString().strip;
	}

	@safe
	bool fileExists(LuaObject self, LuaObject path) {
		import std.file : exists, isFile;
		auto f = path.toString;
		if (f.exists && f.isFile) { return true; }
		return false;
	}

	@safe
	bool dirExists(LuaObject self, LuaObject path) {
		import std.file : exists, isDir;
		auto d = path.toString;
		if (d.exists && d.isDir) { return true; }
		return false;
	}

	/** Recursively deletes the specified directory. */
	void removeDir(LuaObject self, LuaObject path) {
		import std.file : rmdirRecurse;
		rmdirRecurse(path.toString);
	}

	@safe
	void removeFile(LuaObject self, LuaObject path) {
		import std.file : remove;
		remove(path.toString);
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
	private auto getName() {
		import std.algorithm : fill;
		import std.conv : to;
		import std.random : Random, randomCover, unpredictableSeed;

		enum dstring letters = "abcdefghijklmnopqrstuvwxyz";

		dchar[8] name;
		fill(name[], randomCover(letters, Random(unpredictableSeed)));
		return name.to!string();
	}
	// TODO: Pretty-print Lua table.
}
