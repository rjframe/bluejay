import luad.all;

struct Options {
	bool luastd = false;
	string scriptPath;
}

int main(string[] args)
{
	auto options = Options();
	mixin setOptions!(args, options);
	if (helpInfo.helpWanted) {
		import std.stdio : writeln;
		writeln("Usage:");
		writeln("    bluejay [--luastd] PATH\n");
		writeln("\t--luastd\tUse the full lua standard library.");
		writeln("\tPATH (Required)\tThe path to the script file or directory.");
		writeln("\n\t-h, --help\tThis help information.");
		return 0;
	}
	auto scriptPath = args[1];

	auto lua = new LuaState;
	setup(lua, options);

	// TODO: This needs to report test success/failures too.
	import std.file;
	if (! scriptPath.exists) {
		import std.stdio : writeln;
		writeln("Error: You must pass the path to a script to execute.");
		return 1;
	}

	if (scriptPath.isFile) {
		runScript(lua, scriptPath);
	} else {
		foreach (script; dirEntries(scriptPath, "*.bj", SpanMode.shallow)) {
			runScript(lua, script);
		}
	}

	return 0;
}

void runScript(LuaState lua, string path) {
	pragma(inline, true)

	import std.stdio : writeln;
	import luad.error;

	// We need to reset the cleanup function prior to each script.
	lua.doString("function cleanup() end");
	writeln("Testing ", path, ".");
	try {
		auto retMessage = lua.doFile(path);
		if (retMessage.length > 0) {
			foreach (msg; retMessage) {
				writeln("\t", msg);
			}
		}
		// TODO: Print retMessage if returned.
	} catch (LuaErrorException ex) {
		writeln(ex.msg);
	} finally {
		auto cleanup = lua.get!LuaFunction("cleanup");
		cleanup.call();
	}
}

void setup(LuaState lua, Options options) {
	if (options.luastd) {
		lua.openLibs();
	} else {
		import luad.c.all;
		// TODO: Add utf8, table?
		luaopen_base(lua.state);
		luaopen_string(lua.state);
	}

	import bluejay.env;
	lua.setVariables;

	import bluejay.functions;

	// TODO: Fully reset the lua state for every test.
	// TODO: I need to pass the executable path to the scripts.
	// Either a setup script or environment variables - probably the latter.
	TestFunctions t;
	UtilFunctions u;
	lua["Test"] = t;
	lua["Util"] = u;
}

mixin template setOptions(alias args, alias options) {
	import std.getopt : getopt;
	auto helpInfo = getopt(args,
			"luastd", "\tUse the full lua standard library.", &options.luastd
		);
}
