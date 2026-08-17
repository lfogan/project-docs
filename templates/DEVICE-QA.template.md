# Device QA — {{PROJECT_NAME}}

<!-- Activity guide (Android module): read before any adb/device/emulator
     work. Each line names the command or observation that earned it; delete
     lines when the tool or device leaves the stack — git remembers. Not
     lint-checked by design: this file is cold, and bytes landing here instead
     of CLAUDE.md are the system working. -->

- Never eyeball tap coordinates from screenshots — `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml`, then tap the center of the resolved `bounds` rect.
- Account for device density/scaling before `adb shell input tap`.
- Keep taps 24dp clear of the nav bar (`24 × density / 160` px); scroll the target into the safe area first.
