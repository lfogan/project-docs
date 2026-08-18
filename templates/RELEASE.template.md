# Release - {{PROJECT_NAME}}

<!-- Activity guide: read before any release, store, or deployment work.
     This file exists because of one gap TODO.md cannot cover: a task whose
     completion leaves NO trace in the repo. Code work is self-evidencing -
     the commit and the file prove it happened, so its TODO row is deleted.
     External state (store console, signing keys, accounts, DNS, review
     queues) is invisible to git, so the tick IS the only record and it lives
     here, dated, permanently.
     Two kinds of step, and the difference matters:
       - One-time setup: done once for the life of the product. Mark
         `[done YYYY-MM-DD]` inline and never delete it - that mark is the
         record.
       - Per-release: re-run every ship. Leave unmarked; they are a
         procedure, not a checklist to tick.
     Per-release progress belongs in TODO.md as ONE row naming the step
     ("release 1.0.3 - at step 4"), deleted when the release lands. -->

## One-time setup

<!-- Each line: what was done, where it lives, and the date. -->
{{RELEASE_SETUP}}

## Per-release steps

<!-- Ordered. Each step names the exact command or console screen. -->
{{RELEASE_STEPS}}

## Facts worth not re-deriving

<!-- Package id, track names, key alias location, listing URLs - the details
     a release session otherwise re-hunts every time. Never secrets: cite
     where a credential lives, never its value. -->
