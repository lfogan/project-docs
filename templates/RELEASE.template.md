# Release - {{PROJECT_NAME}}

<!-- Read before any release, store, or deploy work. Records state git cannot
     show (console state, keys, accounts, DNS, review queues).
     One-time setup: mark `[done YYYY-MM-DD]` inline; never delete the line.
     Per-release steps: leave unmarked; they re-run every ship.
     Per-release progress = ONE row in TODO.md ("release X - at step N"),
     moved to DONE.md when the release lands. -->

## One-time setup

<!-- What was done, where it lives, date. Never shipped yet: seed the rows
     below unmarked - each earns its [done YYYY-MM-DD] as it happens. For an
     Android app that means, at minimum: upload keystore created + alias/path
     recorded here (never the password) · Play Console developer account ·
     app created in the console · internal testing track opened · store
     listing drafted · content rating questionnaire · data safety form.
     Delete rows that do not apply; add platform rows this list cannot know. -->
{{RELEASE_SETUP}}

## Per-release steps

<!-- Ordered; each step names the exact command or console screen. Never
     shipped yet: leave this as `TBD - locked at first ship`, then write the
     real list DURING the first release while the commands are on screen -
     a list typed from memory before ever shipping is guesswork. -->
{{RELEASE_STEPS}}

## Versioning

<!-- Pre-1.0 default unless the owner overrides: versionCode starts at 1 and
     increments by 1 every store upload (internal track included - Play
     rejects a reused code); versionName 0.x.y, bumped when the owner says
     so, 1.0.0 reserved for the first production release. Record the current
     values here after each upload; git tags mirror versionName. -->

## Facts worth not re-deriving

<!-- Package id, track names, key alias location, listing URLs. Cite where a
     credential lives, never its value. -->
