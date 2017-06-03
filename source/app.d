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
	auto script = args[1];

	auto lua = new LuaState;
	setup(lua, options);

	// TODO: If a directory is passed, run all scripts in it.
	import std.file : exists, isDir, isFile;
	if (script.exists) {
		if (script.isFile) {
			lua.doFile(script);
		} else if (script.isDir) {

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
		// TODO: Add modules, utf8, table?
		luaopen_base(lua.state);
		luaopen_string(lua.state);
		// TODO: throws exception - No calling environment.
		//luaopen_io(lua.state);
	}

	import std.typecons : Tuple, tuple;
	Tuple!(string, string)[] system;

	version(Windows) {
		system ~= tuple("OS", "Windows");
	} else version(linux) {
		system ~= tuple("OS", "Linux");
	} else version(OSX) {
		system ~= tuple("OS", "maxOS");
	}
	version(X86) {
		// TODO: At runtime, determine whether the OS is 32 or 64-bit.
		// We want the system arch, not the application arch.
		system ~= tuple("Arch", "x86");
	} else version(X86_64) {
		system ~= tuple("Arch", "x86-64");
	} else version(ARM) {
		system ~= tuple("Arch", "ARM");
	}
	auto t = lua.newTable(system);
	lua["System"] = t;
	lua.doString("print(System.OS)");
}

mixin template setOptions(alias args, alias options) {
	import std.getopt : getopt, defaultGetoptPrinter, config;
	// TODO: How do I add the script path to this?
	auto helpInfo = getopt(args,
			"luastd", "\tUse the full lua standard library.", &options.luastd
		);
}
