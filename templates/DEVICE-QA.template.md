# Device QA - {{PROJECT_NAME}}

<!-- Activity guide (Android module): read before any adb/device/emulator
     work. Each line names the command or observation that earned it; delete
     lines when the tool or device leaves the stack - git remembers. Not
     lint-checked by design: this file is cold, and bytes landing here instead
     of CLAUDE.md are the system working. -->

- Never eyeball tap coordinates from screenshots - `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml`, then tap the center of the resolved `bounds` rect.
- Account for device density/scaling before `adb shell input tap`.
- Keep taps 24dp clear of the nav bar (`24 × density / 160` px); scroll the target into the safe area first.

## Environments proven

<!-- Coverage state: what this project is PROVEN against, and what has never
     been run. Update the row the moment a run finishes - the date and result
     are external-world facts no test can assert and git cannot show, which is
     why they live in a file rather than being derived.
     Never-run targets stay as ➖ rows in this same table. v1 kept them in a
     separate "coverage gaps" section, which is a second surface that drifts
     from the first; an empty gaps list is also a claim, and one nobody
     maintains. A ➖ row is the honest version and cannot fall out of sync.
     One row per target, one line each. -->

Status: ✅ pass · ⚠️ pass with a known open bug · ❌ blocked/fail · ➖ never run.

| Target | Spec | Last run | Result |
|---|---|---|---|
{{COVERAGE_ROWS}}
