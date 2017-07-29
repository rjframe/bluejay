#!/usr/bin/env bluejay

-- TODO: Meta this.

function cleanup()
	print('In cleanup after Script:exit().')
end

Script:exit()
assert(false, 'Did not exit script.')
