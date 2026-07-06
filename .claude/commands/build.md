---
description: Build the macOS app (and embedded widget)
---
Build the app. If a source file was added or removed since the last generate, run
`xcodegen generate --spec apple/project.yml --project apple` first. (The Apple project lives under
`apple/` after the platform split.)

```sh
xcodebuild -project apple/NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' \
  -derivedDataPath apple/build/DerivedData build
```

Report whether the build succeeded, and surface any `error:` / `warning:` lines.
