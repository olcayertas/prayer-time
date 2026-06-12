# Conventions

- Localized via String Catalogs: **English** source strings → Turkish + Arabic. UI/domain
  strings in `Sources/Core/Localizable.xcstrings` (shared app+widget); app/widget names in
  `Sources/{App,Widget}/InfoPlist.xcstrings`; dates via `Sources/App/DateLocalizer.swift`
  (API long dates are Turkish-only). `developmentLanguage: en`. RTL auto (Arabic). Adding a
  language = catalog edits only (see `docs/LOCALIZATION.md`).
- All times computed/displayed in Europe/Istanbul (`Config.timeZone`), regardless of the Mac's
  own timezone.
- `Sources/Core` is UI-free and compiled into app + widget + tests (same module, no `@testable`).
- Swift 6 language mode (complete strict concurrency). Networking is `async`/`await`
  (`URLSession.data(from:)`) behind a `Sendable` `PrayerTimesProvider`; the `@MainActor`
  `PrayerStore` awaits it from a cancellable `Task`, and a `Task` loop drives the menu-bar
  countdown. (An earlier note claimed async continuations were unreliable here — that was a
  misdiagnosis; the real cause was the rendered MenuBarExtra label, see below.)
- `PrayerCache` = per-process JSON file in Application Support (no App Group → app & widget each
  cache their own copy; widget fetches independently if its cache is empty).
- Data-source seam: `PrayerTimesProvider` (EzanVakti now; official `AwqatSalah` is a future
  drop-in). `PlacesProvider` for the country/city/district hierarchy.
- Selected district persisted in `UserDefaults` (`selectedDistrictId`/Name); default 9543 (Küçükçekmece).

## macOS gotchas (hard-won — do not relearn)
- <important>MenuBarExtra MUST use a plain String title (`MenuBarExtra(store.menuTitle)`), NEVER a
  rendered SwiftUI label / `Image`-in-`Text` / `TimelineView`. A rendered status-item label hangs
  AppKit sizing (`makeMenuBarExtras → updateButton → NSStatusBarButton.setImage: → NSCell.cellSize`)
  on macOS 26 and WEDGES THE MAIN THREAD — which then masquerades as broken async/GCD/networking.
  Diagnose with `sample <pid>` (main thread stuck in setImage/cellSize vs idle in mach_msg).</important>
- Menu bar monospaced digits: `AppDelegate` finds the status button and re-applies
  `NSFont.monospacedDigitSystemFont` after each title change (MenuBarExtra rebuilds the
  attributedTitle in the proportional font every tick, which otherwise makes the countdown jitter).
- Main window uses `NavigationSplitView`; activation policy → `.regular` on open (Dock icon),
  `.accessory` on close. Secondary `Window` scenes do NOT auto-open at launch.
- Single-instance guard in `AppDelegate.applicationWillFinishLaunching` (relaunch via Xcode/`open`
  would otherwise add a second status item).
