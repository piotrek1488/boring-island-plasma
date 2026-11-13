# Issues log

Post-mortems for bugs found in Boring Island and how they were fixed. One file
per issue, newest numbers last.

## Naming

`NNNN-short-slug.md` — zero-padded sequential number, then a short kebab-case
slug (e.g. `0001-plasmashell-segfault-notify-startup.md`).

## What each entry should contain

- **Symptom**: what the user saw, with the exact signal/log line.
- **Evidence**: the concrete proof (backtrace, journal lines, offsets) — not a
  guess. Say explicitly what was verified and what was not.
- **Root cause**: the mechanism, traced to a specific file/function.
- **Fix**: what changed and why it addresses the cause.
- **Verification**: how the fix was confirmed (test, runtime behaviour).
- **Open questions**: anything still unproven.

Keep it factual. If a conclusion rests on inference rather than a captured
artifact, label it as such.
