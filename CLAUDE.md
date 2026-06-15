# NamazVakti — Claude Code guide

macOS **menu bar** app **+ iOS** app for Diyanet prayer times (SwiftUI + WidgetKit), sharing
one `Core` and one set of SwiftUI views. Localized **EN · TR · AR**.

## Build / test / run

This is an **XcodeGen** project — `NamazVakti.xcodeproj` is generated and **gitignored**.
Two app targets share `Sources/Core` + `Sources/Shared`: **`NamazVakti`** (macOS) and
**`NamazVaktiiOS`** (iOS), each embedding its own widget extension.

```sh
xcodegen generate          # REQUIRED after adding/removing any source file

# macOS (menu bar app + widget) — build / test (Core logic, no network) / run
xcodebuild -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData build
xcodebuild test -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData
open build/DerivedData/Build/Products/Debug/NamazVakti.app

# iOS (app + widget) — build for the Simulator, then install/launch on a booted device
xcodebuild -project NamazVakti.xcodeproj -scheme NamazVaktiiOS -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/NamazVaktiiOS.app
xcrun simctl launch booted com.olcayertas.NamazVakti.iOS
```

Slash commands wrap the macOS flow: `/build`, `/test`, `/run`. Signing is local **ad-hoc**
(macOS) / unsigned Simulator build (iOS) — no Apple Developer account or team is required.

## Layout

- `Sources/Core/` — UI-free logic (model, `PrayerSchedule`, providers, `PrayerStore`, cache,
  `Qibla` great-circle bearing, `Localizable.xcstrings`), compiled into every target.
- `Sources/Shared/` — cross-platform SwiftUI used by **both** apps: `TodayView`, `MonthView`,
  `SettingsView`, `LocationPickerView` (+model), `CountdownFormatter`, `DateLocalizer`,
  `AppSection`, and `PlatformColor` (`Color.cardBackground` — the one per-platform shim).
- `Sources/App/` — **macOS** shell: `MenuBarExtra` + `AppDelegate` + `MainWindowView` (sidebar).
- `Sources/iOS/` — **iOS** shell: `PrayerTimesApp` (`@main`) + `RootTabView` (tabbed Today / Monthly /
  Qibla / Settings) + the Qibla compass (`QiblaController` over CoreLocation + `QiblaView`). The Qibla
  tab is iOS-only (needs a magnetometer) — `AppSection.displayed` filters it out on macOS. The
  Simulator has **no magnetometer**, so the compass shows a "No compass" state there; verify the live
  needle on a real iPhone.
- `Sources/Widget/` — WidgetKit timeline + views, shared by the macOS widget and the iOS widget
  (`NamazVaktiWidgetiOS` lists the `.swift` explicitly so the macOS Info.plist/entitlements don't leak in).
- `Tests/CoreTests/` — schedule + JSON-decoding tests.

## Conventions

- All times are **Europe/Istanbul** (`Config.timeZone`).
- **Localized** via String Catalogs — source language is **English** (the `Text("…")` literal is
  the key), translated to **Turkish + Arabic**. UI/domain strings live in
  `Sources/Core/Localizable.xcstrings` (shared by every target); app/widget names in the
  `InfoPlist.xcstrings` files (each key needs an **`en`** value, else the compiled
  `en.lproj/InfoPlist.strings` falls back to the literal key); dates via
  `Sources/Shared/DateLocalizer.swift` (the Diyanet API's
  long dates are Turkish-only). Adding a language = catalog edits only; see
  [docs/LOCALIZATION.md](docs/LOCALIZATION.md). Use `String(localized:)` in `Sources/Core`
  (non-SwiftUI). RTL is automatic (semantic `.leading`/`.trailing`, no `.left`/`.right`).
- **Swift 6 language mode** (complete strict concurrency). Networking is **`async`/`await`**
  (`URLSession.data(from:)`) behind a `Sendable` `PrayerTimesProvider`; the `@MainActor`
  `PrayerStore` awaits it from a cancellable `Task`, and a `Task` loop drives the countdown.
  (An earlier "async is unreliable here" note was a misdiagnosis — the real cause was the
  rendered `MenuBarExtra` label; see the warning below.)
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
3. For UI changes: `/run` (macOS — confirm the menu bar counts down and the main thread is idle),
   and/or build + `simctl launch` the iOS app and confirm the Today countdown ticks.
