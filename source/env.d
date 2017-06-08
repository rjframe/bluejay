/** The environment-related variables to make available in the Lua environment. */
module bluejay.env;

import luad.all;

void setVariables(ref LuaState lua) {
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
	lua["System"] = lua.newTable(system);

	// TODO: CWD. Allow setting? Or should all of these be considered immutable?
}
