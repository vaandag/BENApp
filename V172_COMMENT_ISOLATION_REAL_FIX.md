# BENApp V172 — Comment Isolation Real Fix

- Based on the V171 working project.
- Keeps the V168/V171 turquoise circular + button and existing navigation behavior.
- Fixes the inline feed comment state leaking when PageView reuses a `_LiveMemoryCard` State for a different memory.
- Adds a `ValueKey` per memory so each feed card has stable state identity.
- Inline comment local storage now uses a memory-specific key and legacy records without `memory_id` are ignored.
- API comment rows are accepted only when their `memory_id` matches the displayed memory.
- Newly submitted inline comments persist their `memory_id`.
- Does not alter the separate full CommentsScreen behavior.
