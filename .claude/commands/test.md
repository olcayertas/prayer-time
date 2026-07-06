---
description: Run the Core unit tests
---
Run the unit tests (pure schedule + decoding logic, no network) and report pass/fail with counts:

```sh
xcodebuild test -project apple/NamazVakti.xcodeproj -scheme NamazVakti -destination 'platform=macOS' \
  -derivedDataPath apple/build/DerivedData
```
