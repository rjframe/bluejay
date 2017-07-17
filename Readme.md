# Bluejay

### Cross-platform test script runner.

Bluejay allows you to write test scripts for command-line applications that run
on multiple platforms (currently Windows and Linux), so you don't need to write
something in both batch and shell scripts (or worse, leave no or few tests for
Windows).

Bluejay embeds a Lua interpreter, with a small test library. The library is not
yet documented, but everything is tested in the ./test directory.

You can run a single test via `bluejay my-test.bj` or specify a directory to
test all bj files within.

```Lua
#!/usr/bin/env bluejay

-- Test that bluejay executes a program and reads its standard output.

local ret = Test:run("echo", "asdf")

-- We don't care about the whitespace, which is system-dependent.
assert(Util:strip(ret.Output) == "asdf")
assert(ret.ReturnCode == 0)

-- We can also make the assertion based on the host operating system.
if (System.OS == "Windows") then
	assert(ret.Output == "asdf\r\n")
else
	assert(ret.Output == "asdf\n")
end
```

```Lua
#!/bin/env bluejay

-- Test that Util:writeFile() writes text to the filesystem.

-- cleanup() will run once the test finishes, regardless of success or failure.
function cleanup()
    Util:removeFile(path)
end

-- Note: If path is declared as local, the cleanup function won't see it.
path = Util:getTempFile()
Util:writeFile(path, "This is some text.")
local text = Util:readFile(path)

assert(text == "This is some text.")
```
