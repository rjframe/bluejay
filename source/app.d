import luad.all;

import bluejay.execution_state : Options;

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

	import std.file;
	if (! scriptPath.exists) {
		import std.stdio : writeln;
		writeln("Error: You must pass the path to a script to execute.");
		return 1;
	}

	if (scriptPath.isFile) {
		runScript(options, scriptPath);
	} else {
		foreach (script; dirEntries(scriptPath, "*.bj", SpanMode.shallow)) {
		import std.stdio:writeln;
		writeln("Running ", script);
			runScript(options, script);
		writeln("Finished.");
		}
	}

	return 0;
}

void runScript(Options options, string path) {
	import std.stdio : writeln;
	import luad.error;
	import bluejay.execution_state : ExecutionState;

	auto lua = new ExecutionState(options);
	try {
		auto retMessage = lua.doFile(path);
		if (retMessage.length > 0) {
			foreach (msg; retMessage) {
				writeln("\t", msg);
			}
		}
	} catch (LuaErrorException ex) {
		import std.algorithm.iteration : splitter;
		import std.string : lastIndexOf, lineSplitter;

		auto firstLine = (ex.msg).lineSplitter().front;
		if (firstLine[0] == '[') {
			import std.range : dropExactly;
			import std.string : join;
			auto str = firstLine.splitter(':');
			writeln(path, ":", str.dropExactly(4).join(":"));
		} else writeln(firstLine);
	} finally {
		auto cleanup = lua.get!LuaFunction("cleanup");
		cleanup.call();
	}
}

mixin template setOptions(alias args, alias options) {
	import std.getopt : getopt;
	auto helpInfo = getopt(args,
			"luastd", "\tUse the full lua standard library.", &options.luastd
		);
}
