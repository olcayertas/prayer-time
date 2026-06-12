---
description: Regenerate, build, and launch the app
---
Regenerate the project, build, relaunch the app, and confirm it's healthy.

```sh
xcodegen generate
xcodebuild -project NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
pkill -9 -f NamazVakti.app 2>/dev/null; open build/DerivedData/Build/Products/Debug/NamazVakti.app
```

Then verify health: the menu bar shows a counting-down next prayer, and `sample <pid> 1` shows the
main thread idle in `mach_msg` (NOT wedged in `setImage`/`cellSize` — see CLAUDE.md).
