# NamazVakti — Core

macOS menu bar app showing Diyanet (Turkish religious affairs) prayer times. SwiftUI + WidgetKit.
Remote: github.com/olcayertas/prayer-time (folder name differs: NamazVakti).

## Source map
- `Sources/Core/` — UI-free logic, compiled into app + widget + test targets (no framework, same-module):
  `PrayerDay`, `PrayerSchedule` (next-prayer/countdown math), `PrayerCache`, `PrayerTimesProvider` +
  `PlacesProvider` (EzanVakti), `PrayerStore` (@MainActor observable), `NotificationScheduler`,
  `Place` (Country/City/District), `Config`.
- `Sources/App/` — `NamazVaktiApp` (MenuBarExtra + Window scenes), `MenuPanelView` (dropdown),
  `MainWindowView` → `TodayView`/`MonthView`/`SettingsView`, `LocationPicker{Model,View}`,
  `AppDelegate` (single-instance guard + status-item monospaced font), `CountdownFormatter`.
- `Sources/Widget/` — WidgetKit timeline provider + views.
- `Tests/CoreTests/` — pure logic (schedule edge cases, JSON decoding).
- `project.yml` — XcodeGen spec; the `.xcodeproj` is generated and gitignored.

## Invariants
- The generated `NamazVakti.xcodeproj` is NOT committed — regenerate from `project.yml`.
- Stack & versions: `mem:tech_stack`. Build/run/test commands: `mem:suggested_commands`.
- Code style, data-layer rules, and macOS gotchas: `mem:conventions`. Done criteria: `mem:task_completion`.
