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
	if (scriptPath.exists) {
		if (scriptPath.isFile) {
			lua.doFile(scriptPath);
		} else if (scriptPath.isDir) {
			foreach (script; dirEntries(scriptPath, "*.bj", SpanMode.shallow)) {
				lua.doFile(script);
			}
		}
	} else {
		import std.stdio : writeln;
		writeln("Error: You must pass the path to a script to execute.");
		return 1;
	}

	return 0;
}

void setup(LuaState lua, Options options) {
	if (options.luastd) {
		lua.openLibs();
	} else {
		import luad.c.all;
		// TODO: Add utf8, table?
		luaopen_base(lua.state);
		luaopen_string(lua.state);
		// TODO: throws exception - No calling environment.
		//luaopen_io(lua.state);
	}

	import bluejay.env;
	lua.setVariables;

	import bluejay.functions;
	lua["Test"] = new TestFunctions(lua);
	lua["Util"] = new UtilFunctions(lua);
}

mixin template setOptions(alias args, alias options) {
	import std.getopt : getopt, defaultGetoptPrinter, config;
	// TODO: How do I add the script path to this?
	auto helpInfo = getopt(args,
			"luastd", "\tUse the full lua standard library.", &options.luastd
		);
}
