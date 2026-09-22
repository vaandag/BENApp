# BENApp V171 — Comment Isolation Fix

- Preserve the V168/V171 turquoise circular + button and existing add-memory/live flow.
- Preserve the BEN master logo branding changes.
- Fix comment leakage between memories.
- Persist `memory_id` with local comments.
- Ignore legacy local comments without a matching `memory_id` when viewing a real memory.
- Reject API comment rows that do not contain the requested `memory_id`, preventing an aggregated endpoint response from leaking comments from other memories.
