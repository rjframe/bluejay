/** Manages a LuaState object.*/
module bluejay.execution_state;

import luad.all;

struct Options {
    bool luastd = false;
    bool recurse = false;
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
        TestFunctions t = new TestFunctions(lua, options);
        UtilFunctions u = UtilFunctions(lua);
        ScriptFunctions s = new ScriptFunctions(lua);
        lua["Test"] = t;
        lua["Util"] = u;
        lua["Script"] = s;
        lua.doString("function cleanup() end");
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
            system ~= tuple("Arch", "x86-64");
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
