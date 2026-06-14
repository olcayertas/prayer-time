# NamazVakti — Core

macOS menu bar app **+ iOS app** showing Diyanet (Turkish religious affairs) prayer times.
SwiftUI + WidgetKit. Remote: github.com/olcayertas/prayer-time (folder name differs: NamazVakti).

## Source map
- `Sources/Core/` — UI-free logic, compiled into every target (no framework, same-module):
  `PrayerDay`, `PrayerSchedule` (next-prayer/countdown math), `PrayerCache`, `PrayerTimesProvider` +
  `PlacesProvider` (EzanVakti), `PrayerStore` (@MainActor observable), `NotificationScheduler`,
  `Place` (Country/City/District), `Config`, `Localizable.xcstrings`.
- `Sources/Shared/` — cross-platform SwiftUI used by BOTH apps: `TodayView`, `MonthView`,
  `SettingsView`, `LocationPicker{Model,View}`, `CountdownFormatter`, `DateLocalizer`, `AppSection`,
  `PlatformColor` (`Color.cardBackground`). TodayView's hero (`ViewThatFits`) and MonthView
  (icons + smaller font when `horizontalSizeClass == .compact`) adapt to narrow phone widths.
- `Sources/App/` — macOS shell only: `NamazVaktiApp` (MenuBarExtra + Window scenes), `MenuPanelView`
  (dropdown), `MainWindowView` (sidebar), `AppDelegate` (single-instance guard + status-item font).
- `Sources/iOS/` — iOS shell only: `PrayerTimesApp` (@main WindowGroup) + `RootTabView` (tabs).
- `Sources/Widget/` — WidgetKit timeline + views; built into both `NamazVaktiWidget` (macOS, folder
  include) and `NamazVaktiWidgetiOS` (iOS, explicit `.swift` include so macOS Info.plist doesn't leak).
- `Tests/CoreTests/` — pure logic (schedule edge cases, JSON decoding).
- `project.yml` — XcodeGen spec; the `.xcodeproj` is generated and gitignored.

## Invariants
- The generated `NamazVakti.xcodeproj` is NOT committed — regenerate from `project.yml`.
- Stack & versions: `mem:tech_stack`. Build/run/test commands: `mem:suggested_commands`.
- Code style, data-layer rules, and macOS gotchas: `mem:conventions`. Done criteria: `mem:task_completion`.
