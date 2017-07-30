#!/usr/bin/env bluejay

-- Pretty-print a bluejay table.

t = {"asdf", sdfg={1, 2, 3, 4}, qwer={"asdf", wer={3,4,5,6}}}

print("\nPrint nothing:")
Util:pprint(t, 0)

