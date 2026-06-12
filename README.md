# Namaz Vakti

A minimal macOS app that shows Muslim prayer times (namaz vakitleri) from the Turkish
Directorate of Religious Affairs (Diyanet), delivered through three surfaces:

- **Menu bar** — the next prayer and a live countdown (e.g. `İkindi  3:32:16`); click for a
  panel with today's six times (next highlighted), location, and the Gregorian + Hicri date.
- **Widget** — small / medium WidgetKit widget with the next prayer, a live countdown, and
  today's times.
- **Notifications** — optional local notifications at each prayer time (toggle in the panel).

v1 is a single hardcoded location: **Küçükçekmece** (Diyanet district id `9543`).

## Build & run

Requires [XcodeGen](https://github.com/yonsh/XcodeGen) (`brew install xcodegen`) and Xcode.

```sh
xcodegen generate                       # regenerate the .xcodeproj from project.yml
xcodebuild -scheme NamazVakti -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/NamazVakti.app
```

Tests (pure schedule + decoding logic, no network):

```sh
xcodebuild test -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData
```

The project uses **local ad-hoc signing** — no Apple Developer account or team is needed.
Regenerate the project (`xcodegen generate`) whenever you add or remove source files.

## Architecture

- `Sources/Core` — shared, UI-free logic (compiled into the app, widget, and test targets):
  - `PrayerDay` — `Codable` model of one day (Turkish JSON field names).
  - `PrayerTimesProvider` — data-source seam. `EzanVaktiProvider` (no-auth wrapper of Diyanet
    data, `GET ezanvakti.emushaf.net/vakitler/{id}`) is the v1 impl; `AwqatSalahProvider`
    (official Diyanet API) is a stubbed future drop-in.
  - `PrayerSchedule` — next-prayer / countdown math in `Europe/Istanbul`.
  - `PrayerCache` — per-process monthly cache (a JSON file in Application Support).
  - `PrayerStore` — `@MainActor` observable: loads cache, refreshes, drives the menu title,
    notifications, and widget reloads.
  - `NotificationScheduler` — schedules `UNCalendarNotificationTrigger`s for upcoming times.
- `Sources/App` — `MenuBarExtra` app (menu bar title + dropdown panel).
- `Sources/Widget` — WidgetKit timeline provider and views.

## Notable v1 decisions

- **No App Group.** App Groups require a paid Apple Developer account, so the app and the
  widget each cache their own monthly JSON; the widget fetches independently if its cache is
  empty.
- **Completion-handler networking + GCD**, not async/await — the most robust path observed in
  this menu-bar/sandbox context.
- The menu bar uses a **plain `String` title** (not a rendered SwiftUI label): a rendered
  `MenuBarExtra` label hangs AppKit's status-item sizing on macOS 26.

## Deferred (post-v1)

Country/city/district location picker, the official `AwqatSalah` provider, weekly/monthly
tables, qibla + moon phase, per-prayer notification settings, multiple locations, app icon,
launch-at-login.
