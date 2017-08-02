import std.stdio : writeln;
import luad.all;
import bluejay.execution_state : Options;

int main(string[] args)
{
    auto options = Options();
    mixin setOptions!(args, options);
    if (helpInfo.helpWanted) {
        writeln("Usage:");
        writeln("    bluejay [--luastd] PATH\n");
        writeln("\t--luastd\tUse the full lua standard library.");
        writeln("\t-r|--recurse\tTest files in the specified directory recursively.");
        writeln("\tPATH (Required)\tThe path to the script file or directory.");
        writeln("\n\t-h, --help\tThis help information.");
        return 0;
    }
    auto scriptPath = args[1];

    import std.file;
    if (! scriptPath.exists) {
        writeln("Error: You must pass the path to a script to execute.");
        return 1;
    }

    if (scriptPath.isFile) {
        if (options.recurse)
            writeln("Ignoring --recurse option (testing a single file).");
        writeln("\033[32mRunning\033[0m ", scriptPath);
        runScript(options, scriptPath);
    } else {
        SpanMode mode = SpanMode.shallow;
        if (options.recurse) mode = SpanMode.depth;

        foreach (script; dirEntries(scriptPath, "*.bj", mode)) {
            writeln("\033[32mRunning\033[0m ", script);
            runScript(options, script);
            writeln("Finished.");
        }
    }
    return 0;
}

void runScript(Options options, string path) {
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
            import std.range : drop;
            import std.string : join;
            auto str = firstLine.splitter(':');
            writeln("\033[31m" ~ path, ":\033[0m", str.drop(4).join(":"));
        } else writeln("\033[31m", firstLine, "\033[0m");
    } finally {
        auto cleanup = lua.get!LuaFunction("cleanup");
        cleanup.call();
    }
}

mixin template setOptions(alias args, alias options) {
    import std.getopt : getopt;
    auto helpInfo = getopt(args,
            "luastd", "\tUse the full lua standard library.", &options.luastd,
            "r|recurse", "\tRecursively test subdirectories.", &options.recurse
            );
}
