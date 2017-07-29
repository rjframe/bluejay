#!/usr/bin/env bluejay

-- Test that the cleanup function is called after the script exits.
-- This is called by test-cleanup.bj

function cleanup()
	print("In cleanup.")
end


