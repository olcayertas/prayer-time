# Android release guide

Play-release notes for the Android app (`android/`). See `PLAN.md` for the overall port.

## Build

```sh
cd android
./gradlew :app:bundleRelease     # AAB for Play upload (preferred)
./gradlew :app:assembleRelease   # APK (verification / sideload)
```

The release build is **R8-minified + resource-shrunk** (`isMinifyEnabled` +
`isShrinkResources`), which takes the APK from ~61 MB (debug) to ~4 MB. Keep rules live in
`app/proguard-rules.pro` (the important ones cover kotlinx.serialization on the `:domain`
models — verified: the release build deserializes the EzanVakti JSON without a
`SerializationException`).

## Signing

Signing is read from the environment so no keystore lives in the repo. Without these vars,
`assembleRelease` produces an **unsigned** APK (fine for R8 verification); with them, a signed
release/bundle:

```sh
export NAMAZVAKTI_KEYSTORE=/abs/path/namazvakti-release.jks
export NAMAZVAKTI_KEYSTORE_PASSWORD=…
export NAMAZVAKTI_KEY_ALIAS=…
export NAMAZVAKTI_KEY_PASSWORD=…
./gradlew :app:bundleRelease
```

Prefer **Play App Signing**: upload with an upload key; Google manages the app signing key.

## Versioning

`versionCode` / `versionName` are in `app/build.gradle.kts` (currently `1` / `1.0.0`, matching
the iOS/macOS train). Bump `versionCode` on every Play upload; `versionName` per release.

## Play Data safety form

- **Location** (approximate + precise): used **on-device** to (a) find the nearest Diyanet
  district for prayer times (Automatic mode) and (b) point the Qibla compass. **Not collected,
  not shared, not used for tracking/ads.** Optional — the app works fully in Pinned mode without it.
- **No account, no analytics, no ads, no other personal data.** Prayer times come from the keyless
  EzanVakti service (Diyanet data).

## Permissions to justify in the listing

| Permission | Why |
| --- | --- |
| `ACCESS_COARSE_LOCATION` / `ACCESS_FINE_LOCATION` | Automatic location + Qibla compass. Optional; user-toggled. |
| `POST_NOTIFICATIONS` | Prayer-time notifications (user opt-in). |
| `SCHEDULE_EXACT_ALARM` | Fire the notification exactly at each prayer time — inexact = late = wrong. Uses `SCHEDULE_EXACT_ALARM` (user-grantable) with an in-app rationale, **not** `USE_EXACT_ALARM`. |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule the prayer alarms after a reboot (alarms don't survive reboot). |
| `INTERNET` | Fetch prayer times from EzanVakti. |

## Pre-upload checklist

1. `./gradlew :domain:test` green (ported logic).
2. `./gradlew :app:assembleRelease` (R8) — smoke-test the signed APK: Today loads real times,
   Automatic location resolves, Qibla renders, a notification fires.
3. Bump `versionCode`.
4. `./gradlew :app:bundleRelease` → upload the AAB.
5. Fill the Data safety form as above; declare the exact-alarm use.
