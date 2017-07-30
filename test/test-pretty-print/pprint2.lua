#!/usr/bin/env bluejay

-- Pretty-print a bluejay table.

t = {"asdf", sdfg={1, 2, 3, 4}, qwer={"asdf", wer={3,4,5,6}}}

-- Only print one sublevel.
-- print("\nOnly print two levels of tables:")
Util:pprint(t, 2)
