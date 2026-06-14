# Suggested Commands

Regenerate the Xcode project (REQUIRED after adding/removing source files):
  xcodegen generate

Build the app (+ embedded widget):
  xcodebuild -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData build

Run unit tests (pure Core logic, no network):
  xcodebuild test -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' -derivedDataPath build/DerivedData

Launch the built app:
  open build/DerivedData/Build/Products/Debug/NamazVakti.app

iOS — build for the Simulator, then install/launch on a booted device (Simulator GUI not required):
  xcodebuild -project NamazVakti.xcodeproj -scheme NamazVaktiiOS -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build
  xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/NamazVaktiiOS.app
  xcrun simctl launch booted com.olcayertas.NamazVakti.iOS
  xcrun simctl io booted screenshot /tmp/ios.png      # verify visually (take AFTER launch, separate call)

Health checks (Darwin/macOS):
  pgrep -lf NamazVakti.app
  pkill -9 -f NamazVakti.app                 # force-quit (single-instance app)
  sample <pid> 1                             # main thread: idle = mach_msg; HANG = setImage/cellSize
  pluginkit -mv | grep -i namaz              # widget registered with the system?

Note: this is a GUI/menu-bar app — there is no `swift run`. xcodebuild is sandboxed-network-free
for tests; the app itself fetches at runtime.
