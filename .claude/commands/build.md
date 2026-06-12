---
description: Build the macOS app (and embedded widget)
---
Build the app. If a source file was added or removed since the last generate, run
`xcodegen generate` first.

```sh
xcodebuild -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
```

Report whether the build succeeded, and surface any `error:` / `warning:` lines.
