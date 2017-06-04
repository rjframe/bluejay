/** Contains the functions that will be accessible in bluejay scripts. */
module bluejay.functions;

import luad.all;

class TestFunctions {
	private LuaState lua;
	LuaTable check;

	this(ref LuaState lua) {
		this.lua = lua;
		check = lua.newTable();
	}

	//LuaObject run(LuaObject command, LuaObject args) {
	void run(LuaObject command, LuaObject args) {
		import std.process : executeShell;
		auto output = executeShell(command.toString ~ " " ~ args.toString);

		check.set("ReturnCode", output.status);
		check.set("Output", output.output);
		//return check;
		lua["Check"] = check;
	}
}

class UtilFunctions {
	private LuaState lua;

	this(ref LuaState lua) {
		this.lua = lua;
	}

	// TODO: How do I pass values like this?
	string strip(LuaObject str) {
		import std.string : strip;
		return str.toString().strip;
	}
}
