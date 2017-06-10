/** Manages a LuaState object.*/
module bluejay.execution_state;

import luad.all;

struct Options {
	bool luastd = false;
	string scriptPath;
}

class ExecutionState {
	LuaState lua; // I can't alias this if it's private?
	alias lua this;

	this(Options options) {
		this.lua = new LuaState;

		if (options.luastd) {
			lua.openLibs();
		} else {
			import luad.c.all;
			// TODO: Add utf8, table?
			luaopen_base(lua.state);
			luaopen_string(lua.state);
		}

		import bluejay.functions;
		setVariables(lua);
		TestFunctions t = new TestFunctions(options);
		UtilFunctions u = UtilFunctions();
		lua["Test"] = t;
		lua["Util"] = u;
		lua.doString("function cleanup() end");
	}

	private void setVariables(ref LuaState lua) {
		import std.typecons : Tuple, tuple;

		// TODO: I need to pass the executable path to the scripts.
		// TODO: Add access to system environment variables.
		Tuple!(string, string)[] system;
		version(Windows) {
			system ~= tuple("OS", "Windows");
		} else version(linux) {
			system ~= tuple("OS", "Linux");
		} else version(OSX) {
			system ~= tuple("OS", "maxOS");
		}
		version(X86) {
			system ~= tuple("Arch", "x86");
		} else version(X86_64) {
			system ~= tuple("Arch", "x86-64");
		} else version(ARM) {
			system ~= tuple("Arch", "ARM");
		}
		lua["System"] = lua.newTable(system);
	}
}
