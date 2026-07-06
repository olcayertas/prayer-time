# Task Completion

When a coding task is considered done (Apple side — run from **`apple/`**; the Android app has its own
`./gradlew :domain:test :app:assembleDebug` under `android/`):
1. If source files were added or removed: `xcodegen generate` (from `apple/`).
2. Run tests (must stay green), from `apple/`:
   `xcodebuild test -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData`
3. For UI changes: build, `open` the app, and confirm the main thread is idle (no MenuBarExtra
   status-item hang) via `sample <pid>` — see the gotcha in `mem:conventions`.

No linter/formatter/type-checker is configured (no SwiftLint, no swift-format). The unit tests are
the automated gate. Interactive UI behavior (window opening, menu bar rendering, notification
delivery) is NOT headlessly verifiable — confirm those by running the app.
