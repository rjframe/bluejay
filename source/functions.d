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

	bool fileExists(LuaObject self, LuaObject path) {
		import std.file : exists, isFile;
		auto f = path.toString;
		if (f.exists && f.isFile) { return true; }
		return false;
	}

	bool dirExists(LuaObject self, LuaObject path) {
		import std.file : exists, isDir;
		auto d = path.toString;
		if (d.exists && d.isDir) { return true; }
		return false;
	}

	string getTempDir() {
		//assert(0);
		return "asdf";
	}

	string getTempFile() {
		assert(0);
	}

	// TODO: Print Lua table.
}
