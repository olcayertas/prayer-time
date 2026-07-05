# Namaz Vakti — Android

Native Android port of the Namaz Vakti (Prayer Times) app. Full plan:
[`../docs/android/PLAN.md`](../docs/android/PLAN.md).

**Status: Phase 0 (scaffold) — complete and building.**

## Modules
- **`:domain`** — pure Kotlin/JVM. The ported, unit-tested logic (currently `Qibla` + `Prayer`; the
  rest of the Swift `Core` lands in Phase 1). No Android dependencies → tests run in milliseconds on
  any JDK, and it's a KMP-ready seam.
- **`:app`** — the Android + Jetpack Compose shell (Material 3 + Material You dynamic color,
  edge-to-edge, SplashScreen API). Phase 0 ships a smoke screen that calls `:domain`'s `Qibla` to
  prove the wiring end-to-end.

## Build & test
Requires JDK 21 and the Android SDK (compileSdk 36). From this `android/` directory:
```sh
./gradlew :domain:test        # the ported golden tests — no Android SDK needed (7/7 green)
./gradlew :app:assembleDebug  # the debug APK
```
Or just open `android/` in Android Studio.

## Versions
`gradle/libs.versions.toml` pins a **known-good, mutually-compatible** set (AGP 8.11.1, Kotlin 2.2.0,
Compose BOM 2025.06.01, compile/target SDK 36, min 30) chosen so the project builds today. The plan's
bleeding-edge targets (AGP 9.x, Compose BOM 2026.xx, Material 3 Expressive, Navigation 3) are the
destination — bump via Android Studio's AGP Upgrade Assistant when you adopt them.

## Next — Phase 1 (domain-first)
Port the rest of `Core` into `:domain`, each with its golden tests: `PrayerSchedule` (Istanbul-tz
math), `LocationMatcher` (Turkish folding + the Ankara province-collapse fallback), the EzanVakti
DTOs, and cache freshness. Then Phase 2 (data layer + Hilt) and Phase 3 (Today + the two themes).
