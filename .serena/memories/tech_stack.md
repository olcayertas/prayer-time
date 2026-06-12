# Tech Stack

- Swift, **language mode 6.0** (`SWIFT_VERSION` — Swift 6, complete strict concurrency); built with Xcode 26.5 / Swift 6.3 toolchain.
- SwiftUI + AppKit + WidgetKit + UserNotifications. Deployment target macOS 14.0.
- Project generation: XcodeGen (`brew install xcodegen`); single spec `project.yml`. No `.xcworkspace`.
- No SwiftPM / third-party dependencies.
- Signing: ad-hoc local ("Sign to Run Locally", `CODE_SIGN_IDENTITY=-`). No Apple Developer account,
  no provisioning profile, no App Group (App Groups require a paid account → deliberately avoided).
- Data source: EzanVakti, a no-auth wrapper of Diyanet's published tables
  (`https://ezanvakti.emushaf.net`): `/vakitler/{districtId}` (a month), `/ulkeler`, `/sehirler/{id}`, `/ilceler/{id}`.
