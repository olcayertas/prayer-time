# Tech Stack

- Swift, **language mode 6.0** (`SWIFT_VERSION` — Swift 6, complete strict concurrency); built with Xcode 26.5 / Swift 6.3 toolchain.
- SwiftUI + WidgetKit + UserNotifications (AppKit only in the macOS shell). Deployment targets **macOS 14.0** and **iOS 17.0**.
- **Platform-split monorepo:** the Apple project is under **`apple/`**; a separate native **Android**
  app (Kotlin 2.2 / Jetpack Compose, Gradle `:domain`+`:app`, minSdk 30) under **`android/`** (see `docs/android/`).
- Project generation (Apple): XcodeGen (`brew install xcodegen`); single spec `apple/project.yml`. No `.xcworkspace`.
- Targets: `NamazVakti` (macOS) + `NamazVaktiWidget`; `NamazVaktiiOS` (iOS) + `NamazVaktiWidgetiOS`;
  `NamazVaktiCoreTests`. Both apps share `apple/Sources/Core` + `apple/Sources/Shared`; tests run on the macOS scheme.
- No SwiftPM / third-party dependencies.
- Signing: ad-hoc local ("Sign to Run Locally", `CODE_SIGN_IDENTITY=-`). No Apple Developer account,
  no provisioning profile, no App Group (App Groups require a paid account → deliberately avoided).
- Data source: EzanVakti, a no-auth wrapper of Diyanet's published tables
  (`https://ezanvakti.emushaf.net`): `/vakitler/{districtId}` (a month), `/ulkeler`, `/sehirler/{id}`, `/ilceler/{id}`.
