#!/usr/bin/env bluejay

-- We print the OS and architecture of the system to screen.

assert(string.len(System.OS) > 0)
print(System.OS)

if System.OS == 'Windows' then
    assert(string.len(System.endl) == 2)
else
    assert(string.len(System.endl) == 1)
end
print(System.endl)

assert(string.len(System.Arch) > 0)
print(System["Arch"])

-- If this is non-zero, we'll assume it's right. At least it didn't crash.
assert(string.len(Env["PATH"]) > 0)
