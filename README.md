<div align="center">

# 🕌 Namaz Vakti

**A native macOS menu bar app for Muslim prayer times — powered by the Turkish
Directorate of Religious Affairs (Diyanet).**

[![CI](https://github.com/olcayertas/prayer-time/actions/workflows/ci.yml/badge.svg)](https://github.com/olcayertas/prayer-time/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)
![Concurrency](https://img.shields.io/badge/strict%20concurrency-complete-F05138?logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-26-147EFB?logo=xcode&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20WidgetKit-0A84FF)
![Localization](https://img.shields.io/badge/i18n-EN%20·%20TR%20·%20AR-0A84FF)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

Namaz Vakti lives in your menu bar with a live countdown to the next prayer, and opens
into a full window when you want more detail or to change settings.

## ✨ Features

- **Menu bar countdown** — the next prayer with a live, jitter-free countdown (e.g. `Afternoon  1:23:45`).
- **Dropdown panel** — today's six times with the next one highlighted, location, and the
  Gregorian + Hijri date.
- **Main window** — sidebar with **Today** (rich view), **Monthly** (table), and **Settings**.
  A Dock icon appears only while the window is open.
- **Widget** — small / medium WidgetKit widget with the next prayer and a live countdown.
- **Notifications** — optional local notifications at each prayer time.
- **Location picker** — country → city → district, remembered across launches.
- **Localized** — English, Turkish, and Arabic (right-to-left), including the app name and
  locale-aware Gregorian + Hijri dates. [Adding a language →](docs/LOCALIZATION.md)

## 📋 Requirements

- macOS 14 (Sonoma) or later
- Xcode 26+ to build
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## 🚀 Build & run

```sh
brew install xcodegen
xcodegen generate                       # regenerate NamazVakti.xcodeproj from project.yml
xcodebuild -scheme NamazVakti -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/NamazVakti.app
```

Run the tests (pure schedule + decoding logic, no network):

```sh
xcodebuild test -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData
```

Uses **local ad-hoc signing** — no Apple Developer account required. Re-run
`xcodegen generate` whenever you add or remove source files.

## 🧭 Data source

Prayer times come from the no-auth **EzanVakti** wrapper of Diyanet's published tables:

```
GET https://ezanvakti.emushaf.net/vakitler/{districtId}   # one call = a full month
```

The hierarchy endpoints (`/ulkeler`, `/sehirler/{id}`, `/ilceler/{id}`) drive the location
picker. Everything goes through a `PrayerTimesProvider` protocol, so the official Diyanet
`AwqatSalah` API can be dropped in later without touching the UI.

## 🏗️ Architecture

- **`Sources/Core`** — UI-free, shared by the app, widget, and tests:
  `PrayerDay`, `PrayerSchedule` (next-prayer math in `Europe/Istanbul`), `PrayerCache`,
  `PrayerTimesProvider` / `PlacesProvider` (EzanVakti), `PrayerStore`, `NotificationScheduler`,
  and the shared `Localizable.xcstrings`.
- **`Sources/App`** — `MenuBarExtra` menu bar item + the main window (Today / Monthly / Settings),
  plus `DateLocalizer` (locale-aware Gregorian + Hijri dates).
- **`Sources/Widget`** — WidgetKit timeline provider and views.

### Notable decisions

- **No App Group** (avoids needing a paid Apple Developer account) — the app and the widget
  each cache their own monthly JSON.
- **Swift 6 language mode** with complete strict concurrency. Networking is `async`/`await`
  (`URLSession.data(from:)`) behind a `Sendable` `PrayerTimesProvider`; the `@MainActor`
  `PrayerStore` awaits it from a cancellable `Task`, and a structured `Task` (not a GCD timer)
  drives the once-a-second countdown.
- The menu bar uses a **plain `String` title with monospaced digits**: a rendered
  `MenuBarExtra` label hangs AppKit's status-item sizing on macOS 26. (This — not async/await —
  was the real cause of an earlier hang, so the data layer is free to use modern concurrency.)
- **Localized via String Catalogs** (English source · Turkish · Arabic with RTL) — including the
  app/widget names and locale-aware Gregorian + Hijri dates. See [docs/LOCALIZATION.md](docs/LOCALIZATION.md).

## 🗺️ Roadmap

- Official Diyanet `AwqatSalah` provider
- Location-aware widget (per-widget configuration)
- [More languages](docs/LOCALIZATION.md) — prioritized by Muslim population
- App icon and launch-at-login

## 📄 License

Released under the [MIT License](LICENSE) © 2026 Olcay Ertaş.

Prayer-time data © T.C. Diyanet İşleri Başkanlığı, accessed via the community EzanVakti
service. This project is not affiliated with or endorsed by Diyanet.
