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
	auto run(LuaObject command, LuaObject args) {
		import std.process : executeShell;
		auto output = executeShell(command.toString ~ " " ~ args.toString);
		return ExecuteReturns(output.status, output.output.dup);
	}
}

/** Generic helper functions. */
struct UtilFunctions {
	@safe
	string strip(LuaObject str) {
		import std.string : strip;
		return str.toString().strip;
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
