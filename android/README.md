# Namaz Vakti — Android

Native Android port of the Namaz Vakti (Prayer Times) app — feature-complete at **v1.0.0**. Full
plan: [`../docs/android/PLAN.md`](../docs/android/PLAN.md); release steps:
[`../docs/android/RELEASE.md`](../docs/android/RELEASE.md).

Kotlin + Jetpack Compose (Material 3), same keyless EzanVakti data source as the Apple apps. Four
tabs — **Today / Monthly / Qibla / Settings** — with a live compass, two themes (Default M3 dynamic +
Arc dark/gold, 3 bundled variable fonts), **EN · TR · AR** (Arabic RTL), prayer-time notifications
(exact alarms + boot reschedule), automatic location (reverse-geocode → Diyanet district) plus pinned,
and a Glance home-screen widget. Hilt DI, R8 release build (~4 MB).

## Modules
- **`:domain`** — pure Kotlin/JVM. The ported, unit-tested logic (prayer schedule, Qibla bearing,
  location matching, EzanVakti DTOs, cache freshness). No Android dependencies → 58 tests run in
  milliseconds on any JDK, and it's a KMP-ready seam.
- **`:app`** — the Android + Jetpack Compose shell: the four screens, themes, localization,
  notifications, location, the Glance widget, and Hilt wiring.

## Build & test
Requires JDK 21 and the Android SDK (compileSdk 36). From this `android/` directory:
```sh
./gradlew :domain:test        # the ported golden tests — no Android SDK needed (58 green)
./gradlew :app:assembleDebug  # the debug APK
```
Or just open `android/` in Android Studio.

## Versions
`gradle/libs.versions.toml` pins a **known-good, mutually-compatible** set (AGP 8.11.1, Kotlin 2.2.0,
Compose BOM 2025.06.01, compile/target SDK 36, min 30). The plan's bleeding-edge targets (AGP 9.x,
Compose BOM 2026.xx, Material 3 Expressive, Navigation 3) are the future destination — bump via
Android Studio's AGP Upgrade Assistant when you adopt them.
