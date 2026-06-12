# Conventions

- UI strings are Turkish. All times computed/displayed in Europe/Istanbul (`Config.timeZone`),
  regardless of the Mac's own timezone.
- `Sources/Core` is UI-free and compiled into app + widget + tests (same module, no `@testable`).
- Networking is COMPLETION-HANDLER `URLSession` + GCD (`DispatchQueue.main.async` +
  `MainActor.assumeIsolated`), NOT async/await — async continuations proved unreliable in this
  menu-bar/sandbox/SDK combination.
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
