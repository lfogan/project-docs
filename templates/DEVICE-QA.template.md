# Device QA - {{PROJECT_NAME}}

<!-- Read before any adb/device/emulator work. Each line names the command or
     observation that earned it; delete lines when the tool or device leaves
     the stack. Not lint-checked. -->

- Never eyeball tap coordinates from screenshots - `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml`, then tap the center of the resolved `bounds` rect.
- Account for device density/scaling before `adb shell input tap`.
- Keep taps 24dp clear of the nav bar (`24 × density / 160` px); scroll the target into the safe area first.

## Environments proven

<!-- Update the row the moment a run finishes. Never-run targets stay as ➖
     rows in this table - no separate gaps section. One row per target, one
     line each. -->

Status: ✅ pass · ⚠️ pass with a known open bug · ❌ blocked/fail · ➖ never run.

| Target | Spec | Last run | Result |
|---|---|---|---|
{{COVERAGE_ROWS}}
