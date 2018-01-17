/** Manages a LuaState object.*/
module bluejay.execution_state;

import luad.all;

struct Options {
    bool luastd = false;
    bool recurse = false;
    string scriptPath;
}

class ExecutionState {
    import bluejay.functions;
    private:

    TestFunctions _testFunctions;
    UtilFunctions _utilFunctions;
    ScriptFunctions _scriptFunctions;

    public:

    // It would be nice to make this `package` but alias this won't work.
    LuaState _lua;
    alias _lua this;

    this(Options options) {
        this._lua = new LuaState;

        if (options.luastd) {
            _lua.openLibs();
        } else {
            import luad.c.all;
            // TODO: Add utf8, table?
            luaopen_base(_lua.state);
            luaopen_string(_lua.state);
        }

        setVariables(_lua);
        _testFunctions = new TestFunctions(_lua, options);
        _utilFunctions = UtilFunctions(_lua);
        _scriptFunctions = new ScriptFunctions(_lua);
        _lua["Test"] = _testFunctions;
        _lua["Util"] = _utilFunctions;
        _lua["Script"] = _scriptFunctions;
        _lua.doString("function cleanup() end");
    }

    private void setVariables(ref LuaState lua) {
        import std.typecons : Tuple, tuple;

        Tuple!(string, string)[] system;
        version(Windows) {
            system ~= tuple("OS", "Windows");
            system ~= tuple("endl", "\r\n");
        } else version(linux) {
            system ~= tuple("OS", "Linux");
            system ~= tuple("endl", "\n");
        } else version(OSX) {
            system ~= tuple("OS", "macOS");
            system ~= tuple("endl", "\n");
        }
        version(X86) {
            system ~= tuple("Arch", "x86");
        } else version(X86_64) {
            system ~= tuple("Arch", "x86_64");
        } else version(ARM) {
            system ~= tuple("Arch", "ARM");
        }
        lua["System"] = lua.newTable(system);

        import std.process : environment;
        Tuple!(string, string)[] environ;
        foreach (env; environment.toAA.byKeyValue) {
            environ ~= tuple(env.key, env.value);
        }
        lua["Env"] = lua.newTable(environ);
    }
}
