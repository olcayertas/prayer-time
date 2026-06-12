# NamazVakti — Claude Code guide

macOS **menu bar** app for Diyanet prayer times (SwiftUI + WidgetKit). UI is Turkish.

## Build / test / run

This is an **XcodeGen** project — `NamazVakti.xcodeproj` is generated and **gitignored**.

```sh
xcodegen generate          # REQUIRED after adding/removing any source file
# build (app + embedded widget)
xcodebuild -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData build
# test (pure Core logic, no network)
xcodebuild test -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData
# run
open build/DerivedData/Build/Products/Debug/NamazVakti.app
```

Slash commands wrap these: `/build`, `/test`, `/run`. Signing is local **ad-hoc** — no Apple
Developer account or team is required.

## Layout

- `Sources/Core/` — UI-free logic (model, `PrayerSchedule`, providers, `PrayerStore`, cache),
  compiled into the app, widget, and test targets.
- `Sources/App/` — `MenuBarExtra` + main window (Today / Month / Settings) + `AppDelegate`.
- `Sources/Widget/` — WidgetKit timeline + views.
- `Tests/CoreTests/` — schedule + JSON-decoding tests.

## Conventions

- UI strings are Turkish; all times are **Europe/Istanbul** (`Config.timeZone`).
- Networking is **completion-handler `URLSession` + GCD**, not async/await (async continuations
  were unreliable in this menu-bar/sandbox context).
- **No App Group** (avoids needing a paid account) — the app and the widget cache independently.
- Data comes from the keyless **EzanVakti** wrapper behind `PrayerTimesProvider` (the official
  Diyanet `AwqatSalah` API is a future drop-in).

<important>
The MenuBarExtra status item MUST use a plain `String` title (`MenuBarExtra(store.menuTitle)`).
NEVER give it a rendered SwiftUI label / `Image`-in-`Text` / `TimelineView`: on macOS 26 that hangs
AppKit's status-item sizing and wedges the main thread — which masquerades as broken
async/networking. Diagnose with `sample <pid>` (main thread stuck in `setImage`/`cellSize` vs idle
in `mach_msg`).
</important>

<important>
After adding or removing any source file, run `xcodegen generate` before building — otherwise the
new file is not in the project.
</important>

## Done checklist

1. `xcodegen generate` (if files were added/removed)
2. `/test` is green
3. For UI changes: `/run`, then confirm the menu bar counts down and the main thread is idle.
