# Namaz Vakti — Native Android Port Plan

> **STATUS (2026-07-06): IMPLEMENTED.** This plan is now fully realized — all phases shipped: the four
> surfaces (Today / Monthly / Qibla / Settings), **EN · TR · AR** with RTL, prayer-time notifications,
> automatic location, a Glance home-screen widget, Hilt DI, and an R8 release build. The Android app
> lives under `android/`. See [RELEASE.md](RELEASE.md) for build/release details. **The text below is
> the original point-in-time plan, kept as-is for history.**

> Status: **proposal — all decisions resolved (§14); ready to scaffold.**
> Scope: a brand-new **native Android** app (Kotlin + Jetpack Compose, latest APIs, no backward
> compatibility) that reaches feature parity with the existing SwiftUI iOS/macOS app in this repo.
> This plan was produced by analyzing the Swift source, researching the current (2026) Android
> stack, generating two competing designs, and adversarially reviewing them for correctness,
> platform-policy feasibility, and completeness. Version numbers are "pin at scaffold time"
> (see §2).

---

## 0. TL;DR — the recommended shape

- **Fresh native Android app. No code sharing with Swift; no Kotlin Multiplatform** (the shared
  surface is tiny and the platform-touching parts don't share — see §12). Same **keyless EzanVakti
  API**, re-implement `Core` in Kotlin.
- **Monorepo:** an `android/` directory inside `olcayertas/prayer-time`, path-filtered CI.
- **Architecture:** a single **`:app`** module *packaged by layer*, **plus one pure-Kotlin/JVM
  `:domain`** module holding the ported algorithms (fast JVM golden tests; a KMP-ready seam). This
  is the middle path between the two design lenses — not over-modularized, but the tested spine is
  Android-free.
- **Stack (2026, latest-stable):** Kotlin 2.2.x/K2 · AGP 9.x · Compose BOM (latest) · **Material 3
  1.4 stable** (cherry-pick individual Expressive components from the `1.5.0-alpha` line, opt-in) ·
  **Navigation 3 `1.0.x` stable** (not the not-yet-real `1.1.4`) · Hilt on **KSP2** · Retrofit 3 +
  OkHttp 5 + kotlinx.serialization · **Proto DataStore** (no Room in v1) · WorkManager · **Glance
  1.1** · Coil 3 · Sentry (opt-in). **`compileSdk`/`targetSdk` 36 · `minSdk` 30.**
- **Prayer-time notifications:** exact alarms via **`SCHEDULE_EXACT_ALARM` + a first-run rationale
  screen** — *not* `USE_EXACT_ALARM` as the primary, and *not* "both as a fallback pair" (that is an
  anti-pattern; see §6.1).
- **Live Activity → an ongoing self-ticking *chronometer notification*** (optionally promoted via
  Android 16 "Live Updates" behind an off-by-default flag). **No Dynamic Island** analog; **lock-screen
  widgets are out of scope** for v1.
- **The two things that will actually bite:** (1) prayer alarms surviving **OEM battery-killers**
  (Xiaomi/Oppo/Samsung/Huawei) and Doze; (2) **automatic location on de-Googled devices**, where
  `Geocoder` is absent — handled by a **bundled Turkey district-centroid offline geocoder**
  (nearest-centroid match, no Play Services needed). Both are designed for below.
- **Effort:** ~**13 engineer-weeks**, 9 phases, **domain-first** (the tested spine goes green before
  any UI).

---

## 1. Goals, scope, non-goals

**Goals**
- Feature parity with the iOS app's four surfaces — **Today / Monthly / Qibla / Settings** — plus a
  **home-screen widget** and **prayer-time notifications**, in **EN · TR · AR** with RTL.
- Reproduce the app's visual identity: the **six-prayer dawn→dusk palette** and both themes
  (**Default** = Material baseline, **Arc** = dark/gold with the three bundled fonts).
- Use the newest *stable* Android/Compose capabilities; consciously opt into a few pre-stable ones.

**In scope for v1:** Today, Monthly (Focus Card + chart), Qibla compass, Settings, Automatic/Pinned
location, exact-alarm notifications, one Glance widget (small + medium), an ongoing-notification
"Live Activity" equivalent, full i18n + RTL, localized Gregorian + Hijri dates.

**Non-goals / out of scope for v1** (each is a deliberate decision, see §14): Kotlin Multiplatform;
iOS-style **lock-screen widgets** and **Dynamic Island**; **Wear OS / tablet-optimized** layouts (phone
only, graceful stretch); **adhan audio playback** (it forces a `mediaPlayback` foreground service —
§6.1); multi-month navigation (the store holds one month, same as iOS); cross-platform state transfer
(Android is a **fresh install**, full onboarding on first launch).

---

## 2. Tech stack (2026)

> ⚠️ **Pin at scaffold time.** The *choices and stability status* below are solid; the exact patch
> numbers are from mid-2026 snapshots. Resolve each against `libs.versions.toml` on the day you
> scaffold and take the latest patch. Where a row is pre-stable it says so explicitly.

| Area | Choice | Version (verify) | Notes |
|---|---|---|---|
| Language | **Kotlin / K2** | 2.2.x | K2 is the only compiler. Apply the Compose compiler via the `org.jetbrains.kotlin.plugin.compose` Gradle plugin **at the Kotlin version** — you never hand-match a compiler version again. |
| Build | **AGP** | 9.x | Current major; has built-in Kotlin support. Requires Gradle 8.11+. |
| UI | **Jetpack Compose (BOM)** | latest BOM | One `platform(compose-bom)` import keeps `ui`/`material3` consistent. The **compiler is separate** from the BOM (it tracks Kotlin) — the one gotcha. |
| Design | **Material 3** | **1.4 stable** | Production baseline. **Material 3 Expressive is NOT fully stable** — it lives in `material3 1.5.0-alpha` behind `@ExperimentalMaterial3ExpressiveApi`. Ship on 1.4 and **cherry-pick** individual graduated Expressive components consciously; don't put the whole Expressive surface on the critical path. |
| Nav | **Navigation 3** | **1.0.x stable** | Back stack = a plain observable `List` of keys; fits Compose. ⚠️ There is **no stable `1.1.4`** — the 1.1 line was pre-release (beta) as of 2026. Pin **1.0.x stable**, or accept `1.1.0-beta` as an explicit opt-in. (Navigation-Compose / Nav2 is the legacy-but-supported fallback if you want the larger third-party ecosystem.) |
| VM | Lifecycle + `lifecycle-viewmodel-compose` | 2.11.x | `collectAsStateWithLifecycle`. |
| Prefs | **Proto DataStore** (kotlinx-serialization) | 1.2.x | Typed config (theme, location mode, selected district, toggles). **No Room in v1** — the month cache is JSON files (§4). Add Room only when a real query need appears. |
| DI | **Hilt** on **KSP2** | 2.57.x | First-party, compile-time-validated. Use the KSP path, not kapt. (Metro/Koin are credible alternatives; Hilt is the conventional pick for a single-platform app.) |
| Serialization | kotlinx.serialization | 1.9.x | JSON for both networking and Proto DataStore. |
| Networking | **Retrofit 3 + OkHttp 5** + kotlinx-serialization converter | R3.0 / OkHttp5 | Mature, lowest-friction. (Ktor client 3.x only if KMP later — we're not.) |
| Async | Coroutines / Flow | 1.10.x | `suspend` repos + `StateFlow`. |
| Widget | **Glance** | 1.1.x (stable) | Compose-style app widgets. See §6.4 for the `Chronometer` interop caveat. |
| Images | Coil 3 | 3.x | (Minimal — the app is largely vector/text.) |
| Location | `play-services-location` | **21.x** (pin it) | `FusedLocationProviderClient`. See §6.3 for the de-Googled story. |
| Crash | **Sentry** (opt-in) | latest | GMS-independent — **not Firebase Crashlytics** (won't report on the de-Googled audience). See §11. |
| Test | JUnit4 · Compose UI Test · **Turbine** · **MockK** · **Roborazzi** | — | Roborazzi (Robolectric/JVM) for screenshots — interaction-capable, Hilt-compatible. |

**SDK levels** (given "latest features, no backward compat"): `compileSdk = 36`, `targetSdk = 36`
(**required** for a 2026 Play submission), `minSdk = 30` (Android 11 — a clean "modern-only" floor
that drops legacy storage/permission workarounds while keeping essentially the whole active base).
minSdk 30 also means `POST_NOTIFICATIONS` (33+) and the async `Geocoder` overload (33+) need runtime
branches for 30–32. If you want to be even more aggressive, 33/34 is defensible; do **not** go below
30 for a greenfield app in 2026.

---

## 3. Architecture

**Recommendation: two Gradle modules.**
- **`:domain`** — a **pure Kotlin/JVM** module (no Android imports): the ported `PrayerSchedule`,
  `Qibla`, `LocationMatcher`, the DTOs, cache-freshness, and the repository *interfaces*. It compiles
  and tests on the JVM in milliseconds and is the home of the ported golden tests. (This is the one
  hedge that keeps a future `commonMain`/KMP door open at ~zero cost.)
- **`:app`** — everything Android: Compose UI, ViewModels, DI, the EzanVakti/Retrofit repo impls,
  DataStore, notifications, Glance widget, sensors, location. **Packaged by layer** (`data/ domain/
  ui/ notifications/ widget/ location/ qibla/`), not further modularized. For 4 screens and a
  few-hundred-line domain, more modules is pure overhead; promotion to feature modules later is
  mechanical.

**Layers**
- **data** — `PrayerTimesRepository` / `PlacesRepository` interfaces (in `:domain`) with EzanVakti
  Retrofit impls; the per-district JSON month cache; Proto DataStore settings.
- **domain** — the ported pure logic + repository interfaces.
- **ui** — Compose screens + `ViewModel`s exposing `StateFlow<UiState>`; a `CompositionLocal` theme.

**Threading:** UI state on the main dispatcher; network/disk on `Dispatchers.IO`; a **cancellation-aware
refresh** (cancel the in-flight job on location-mode change, mirroring the Swift `Task` cancellation);
the 1 Hz countdown is a `flow { while(true){ emit(now); delay(1000) } }` collected with lifecycle —
**not** a persisted state write.

**Navigation:** Nav3 with a bottom nav bar (Today / Monthly / Qibla / Settings). The macOS
sidebar/menu-bar surfaces have **no Android analog** — that structure collapses into the phone tabs.

**DI:** thin Hilt — a `NetworkModule`, `RepositoryModule`, `DataStoreModule`; `@HiltViewModel` for the
screen VMs.

---

## 4. Data + domain layer

### 4.1 The EzanVakti client (keyless, unauthenticated)
Base `https://ezanvakti.emushaf.net`, all GET, all return JSON **arrays**:

| Purpose | Path | Model |
|---|---|---|
| Month of prayer times | `/vakitler/{districtId}` | `List<PrayerDayDto>` (one call = a whole month) |
| Countries | `/ulkeler` | `List<CountryDto>` |
| Cities/provinces | `/sehirler/{countryId}` | `List<CityDto>` |
| Districts (ilçe) | `/ilceler/{cityId}` | `List<DistrictDto>` |

- **Turkish PascalCase keys are load-bearing:** `Imsak, Gunes, Ogle, Ikindi, Aksam, Yatsi` (the six
  times), `GunesDogus, GunesBatis, KibleSaati`, `MiladiTarihKisa` (`dd.MM.yyyy`), `HicriTarihKisa`
  (`dd.MM.yyyy`), `MiladiTarihUzun`/`HicriTarihUzun` (Turkish long forms). Place keys:
  `UlkeID/UlkeAdi`, `SehirID/SehirAdi`, `IlceID/IlceAdi`.
- **`@Serializable` with `ignoreUnknownKeys = true`** — the API sends more than we model
  (`*Iso8601`, `AyinSekliURL`, `GreenwichOrtalamaZamani`); ignore them. **Parse the `dd.MM.yyyy` short
  form**, not the ISO field, for parity.
- **IDs are Strings** (leading-zero / opaque-id safety) — carry them as `String` through cache keys,
  DataStore, URL paths. Turkey `UlkeID = "2"`; default district `"9543"` = Küçükçekmece; the chosen
  `District.id` feeds `/vakitler/{id}` verbatim.
- OkHttp: ~15 s call/connect/read timeouts, no connectivity-wait (fail fast). Non-2xx → error.
- **Keep the repository interface seam** so the official Diyanet **AwqatSalah** OAuth API can be
  dropped in later (see the risk in §14 about this being a *present-tense* dependency).

### 4.2 Cache + settings
- **Month cache = JSON files**, `monthlyTimes.{districtId}.json` in app-internal storage, read directly
  by the widget worker (same process — no App Group needed; §6.4). **Freshness:** only fetch when the
  cached month no longer covers today (`isCacheFresh`).
- **Proto DataStore** for: `themeId`, `locationMode`, `selectedDistrictId`+`name`,
  `notificationsEnabled`, `liveActivityEnabled`.

### 4.3 Ported domain (port with the tests — §9)
| Swift | Kotlin | Rules to preserve exactly |
|---|---|---|
| `PrayerSchedule` | `PrayerSchedule` | Build instants with **`ZoneId.of("Europe/Istanbul")`** always (never device zone). `upcoming(now)` = **strict `>`** next prayer; `current(now)` = **inclusive `≤`**; **rolls into next day after Yatsı**; parse `dd.MM.yyyy` + `HH:mm`. |
| `Qibla.bearing` | `Qibla.bearing` | Great-circle initial azimuth to the Kaaba (**21.4225, 39.8262**), clockwise from **true north**, normalized `0..<360`. |
| `LocationMatcher` | `LocationMatcher` | **Turkish-aware fold** (case + diacritics + dotless-ı→i + strip non-alphanumerics), then exact-ilçe → containment → **province-named metropolitan-center fallback** (Ankara collapses central ilçe into a single "ANKARA" entry). **Subtle — port the tests.** |
| `PrayerDay` decode | DTO | PascalCase keys, unknown ignored. |
| cache freshness | — | Month-covers-today only. |
| `PrayerStore` | `MainViewModel` + repo | `StateFlow` for published fields; coroutine refresh; drives location mode → notifications → widget reload. |
| `Prayer` | `Prayer` enum | Order `imsak, gunes, ogle, ikindi, aksam, yatsi` (chronological). **Güneş/Sunrise is informational** — dimmed to 0.5, **never** highlighted as "next". |

---

## 5. Feature-parity map

| Feature | iOS/macOS mechanism | Android implementation |
|---|---|---|
| Six-prayer model + Istanbul-tz math | `Prayer` + `PrayerSchedule` | Port verbatim (`:domain`); pin Istanbul zone. |
| Monthly prayer data | `EzanVaktiProvider` (async) | Retrofit 3 + coroutines behind a repo interface. |
| Location hierarchy | `PlacesProvider` | Same 3 endpoints. |
| Today | `TodayView` (`TimelineView` 1 Hz) | Compose; 1 s coroutine tick; responsive hero via width breakpoint (`BoxWithConstraints`). |
| Live countdown (in-app) | `TimelineView`/`Text(timerInterval:)` | Coroutine tick. |
| Monthly Focus Card + chart | `MonthView` + `Monthly/` | `LazyColumn` chart + one shared 6-column `Row` (fixed leading gutter + 6×`weight(1f)`), hoisted `selectedId`, animated promotion (respect `reduceMotion`). Metrics dp: gutter 34, row 20, rail 1.3, dot 2.3/3.4. Month-nav disabled (single month v1). |
| Qibla compass | `QiblaView`+`QiblaController` | **Port** — `FusedLocation` + `SensorManager` (§6.2). |
| Settings: theme / location mode / notifications | `SettingsView` `Form` | Grouped settings screen; segmented controls; DataStore-persisted. |
| Location picker (Pinned) | cascading searchable sheets | Bottom sheets; Turkish-fold search. |
| Automatic location | `LocationTracker`+`LocationResolver`+`LocationMatcher` | `FusedLocation` one-shot + `Geocoder` + ported matcher (§6.3). |
| Notifications | `UNCalendarNotificationTrigger` (3 days, ≤64) | Exact alarms + `NotificationCompat` (§6.1). |
| Home widget | WidgetKit Small/Medium | **Glance** widget (§6.4). |
| Lock-screen widgets | accessory families | **Out of scope** (stretch → persistent notification). |
| Live Activity / Dynamic Island | `ActivityKit` | **Ongoing chronometer notification**; optional Live Updates behind a flag; no Dynamic Island (§6.5). |
| App↔widget data sharing | App Group | Same-process DataStore + `monthlyTimes.{id}.json` (§6.4). |
| Themes Default + Arc | `@Environment(\.theme)` | `data class` theme via `CompositionLocal` (§7). |
| 6-prayer palette / Arc gradient / fonts | tokens + `.ttf` | Fixed `Color` list + `Brush.radialGradient` + `res/font/` (§7). |
| i18n EN/TR/AR + RTL + localized dates | String Catalog + `DateLocalizer` | `values-*` + positional args + **plurals** + ICU dates (§8). |
| macOS menu bar / window / Open-at-Login | `MenuBarExtra` / `SMAppService` | **No analog — dropped.** Nearest = widget + ongoing notification; "Open at Login" ≈ "survive reboot" (BOOT_COMPLETED, already handled). |
| Accessibility (Dynamic Type / VoiceOver) | `@ScaledMetric` / a11y labels | Honor `fontScale` (a test axis, §9); TalkBack `contentDescription` incl. the per-row month-chart spoken summary. |

---

## 6. The hard platform bits (deep-dive)

### 6.1 Prayer-time notifications — exact alarms done right
- **Use `SCHEDULE_EXACT_ALARM`, not `USE_EXACT_ALARM`, as the primary.** They are **mutually-exclusive
  strategies, not a primary/fallback pair** (declaring both as a "fallback" is an anti-pattern that
  invites review scrutiny). `USE_EXACT_ALARM` is auto-granted but **Google-Play-restricted to
  alarm-clock/calendar apps** — a prayer app is a *plausible but not guaranteed* fit and has been asked
  to justify/remove it. `SCHEDULE_EXACT_ALARM` is **user-grantable and not Play-policy-gated** — any
  app may request it. **Ship `SCHEDULE_EXACT_ALARM` + a first-run rationale screen** that sends the user
  to `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`. Keep `USE_EXACT_ALARM` only as an optional extra you're
  prepared to defend/remove on 24 h notice.
- Fire with `AlarmManager.setExactAndAllowWhileIdle`. **Gate on `canScheduleExactAlarms()`**; if false,
  don't silently degrade to inexact and pretend it's fine — **inexact prayer alarms fire minutes late**
  (Doze batching), which is a *correctness* failure for prayer times. Make the exact-alarm grant a
  **first-run priority**, not a buried toggle.
- **Doze:** `setExactAndAllowWhileIdle` fires in Doze but `*AndAllowWhileIdle` is rate-limited to
  ~once/9–10 min per app in deep Doze — fine for six prayers hours apart. Document this so nobody adds
  a 7th sub-10-minute alarm.
- **Self-chaining:** the fired `BroadcastReceiver` posts the notification **and schedules the next
  alarm** — inside the wakeup. Schedule ~3 days ahead as a buffer. **Reschedule on `BOOT_COMPLETED`,
  `TIMEZONE_CHANGED`, `MY_PACKAGE_REPLACED`**, and on every data/location refresh.
- **The real reliability threat is OEM battery-killers** (Xiaomi/MIUI, Oppo/ColorOS, Samsung, Huawei)
  that kill the process **and cancel its alarms** regardless of Doze. Mitigation: on first schedule,
  detect aggressive OEMs and surface a "disable battery optimization / allow auto-start" nudge
  (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` + OEM guidance). This is a **top-3 reliability risk**
  for this audience.
- **`POST_NOTIFICATIONS`** (33+): request **contextually** (when the user enables the toggle, not at
  cold start). On 30–32 it's implicit — but still check
  `NotificationManagerCompat.areNotificationsEnabled()` before relying on alarms→notifications (a
  blocked channel = silent failure).
- **No started foreground service in v1** — the one-shot location fix is a bounded
  `getCurrentLocation()` callback, not a service. ⚠️ **If adhan audio is ever added**, playing audio
  from a background alarm receiver requires a **`mediaPlayback` foreground service + a Play Console
  declaration** — a latent P0. Adhan is therefore explicitly **out of v1** (§14).
- **Notification small-icon** must be a **separate silhouette-only asset** — reusing the launcher icon
  makes a grey square in the status bar.

### 6.2 Qibla compass — don't double-count declination
- Bearing math: port `Qibla.bearing` verbatim (true-north azimuth to 21.4225, 39.8262).
- **Sensors:** prefer computing the **magnetic azimuth explicitly** (`TYPE_MAGNETIC_FIELD` +
  `TYPE_ACCELEROMETER` → `getRotationMatrix` → `getOrientation`, or `TYPE_ROTATION_VECTOR`) and **always
  add `GeomagneticField.declination` yourself**. ⚠️ `TYPE_ROTATION_VECTOR` is **already true-north
  referenced on some OEMs** and magnetic on others — blindly adding declination to a
  sensor that's already true-north **double-counts** it and mis-points the arrow (the compass's whole
  job). Pick a deterministic path and correct it once. `remapCoordinateSystem` for portrait.
- **Location-denied path:** you can't compute declination without a coordinate → fall back to
  **magnetic** north with a visible "uncorrected" caveat, don't silently mis-point.
- `FEATURE_SENSOR_COMPASS` gate for the "No compass" state; calibration prompt on low
  `onAccuracyChanged`. **Shortest-path needle animation** (accumulate the signed delta so it never
  spins across the 0/360 seam). Haptic + green arrow within 5°. **The needle is bearing-absolute — it
  must be exempt from RTL mirroring** (mirroring the layout is right; mirroring the needle points the
  wrong way).
- Start on foreground, **stop on background** (battery).

### 6.3 Automatic location + geocoder (the de-Googled reality)
- One-shot fix: `getCurrentLocation(PRIORITY_BALANCED_POWER_ACCURACY)` with **coarse permission only**
  (city granularity is enough). ⚠️ With coarse-only, Fused **clamps accuracy** and `getCurrentLocation`
  **returns null more often** (no warm fix) — handle null (present) and set the expectation.
- Reverse-geocode with `Geocoder` (async `getFromLocation(...)` on 33+, sync branch on 30–32). ⚠️
  **`Geocoder.getFromLocation` throws `IOException` routinely** even on Googled devices (it's a network
  call) → automatic mode is **best-effort**, will no-op more than users expect; fall back to the saved
  district.
- ⚠️ **On de-Googled / microG / AOSP devices `Geocoder.isPresent()` is false** → automatic district
  resolution is **entirely unavailable, not degraded**. So on the FOSS audience the plan otherwise
  targets, **automatic mode = manual picker only** unless we add an **offline reverse-geocoder**. The
  clean fix that reuses our own data: **v1 bundles a Turkey district-centroid dataset and matches the
  nearest centroid** to the coarse fix — so automatic district resolution works with **no Play Services
  / no `Geocoder`**. On Googled devices `Geocoder` is tried first (better ilçe precision); the centroid
  matcher is the universal fallback and the only path on de-Googled devices.
- Feed geocoder output into the ported `LocationMatcher`. ⚠️ De-Googled geocoders return **different
  admin-area strings** than Google's — the matcher's golden fixtures are Google-shaped; add
  de-Googled fixtures or accept more fall-through to manual.
- ~1 km coordinate bucket cache to stay under geocoder quota (mirrors iOS). Turkey-focused; abroad/denied
  → saved district (default Küçükçekmece `9543`).
- **CI guard:** fail the build if `ACCESS_BACKGROUND_LOCATION` or `ACCESS_FINE_LOCATION` appears in the
  **merged** manifest (a transitive dep can pull it) — either triggers a heavyweight Play
  background-location review we don't need. Coarse + foreground only.

### 6.4 Home-screen widget (Glance)
- **Glance `GlanceAppWidget`**, small + medium `SizeMode`. Reads the **same-process** DataStore district
  + `monthlyTimes.{id}.json` (no App Group needed — the widget's *data* is in-process; only its
  *rendering* is `RemoteViews` in the launcher/host).
- **Live countdown:** there's no `Text(timerInterval:)`. Use a system **`Chronometer`** so the OS ticks
  it without app wakeups. ⚠️ `Chronometer` is a classic-`RemoteViews` view — in Glance you must drop to
  **`AndroidRemoteViews` interop** to embed it; **verify it renders before committing** to "the system
  ticks it." A `Chronometer` also **can't re-target at a prayer boundary on its own** — schedule a
  widget update at each boundary (rides the exact-alarm/WorkManager machinery). ⚠️ On a throttled
  de-Googled device the boundary update can lag → the widget shows a **stale countdown** until next app
  open. Respect the `updatePeriodMillis` (~30 min) / WorkManager (15 min) floors.

### 6.5 Live Activity equivalent
- An **ongoing, updating notification** with a self-ticking `Chronometer` (`setUsesChronometer` +
  `setChronometerCountDown`), toggled in Settings (`liveActivityEnabled`). Collapsed/expanded states map
  to the compact/expanded Dynamic-Island presentations. **No Dynamic Island** analog.
- **Optionally** promote it as an **Android 16 "Live Update"** via the `Notification` extra
  `EXTRA_REQUEST_PROMOTED_ONGOING` + `ProgressStyle` — **behind an off-by-default flag**, because
  promotion is best-effort/OEM-dependent and adds Play-review surface. ⚠️ **Do not declare a
  `POST_PROMOTED_NOTIFICATIONS` permission** — it isn't part of the documented model (the gate is the
  extra + system discretion); shipping a nonexistent permission is misleading cruft.

### 6.6 Hijri + localized dates (get the rationale right)
- The app **formats the numeric Hijri triple the Diyanet/EzanVakti API already returns**
  (`HicriTarihKisa`, e.g. `"22.12.1447"`); it does **not** convert Gregorian→Hijri. So there is **no
  Umm-al-Qura-vs-Diyanet reconciliation** to do — only **month-name lookup + digit rendering**.
  (Note: the JDK's default `HijrahChronology` *is* Umm al-Qura, and Diyanet can differ ±1 day at
  month boundaries — but that's irrelevant here precisely because we render Diyanet's own value.)
- Use **`android.icu`** (`islamic-umalqura` for month names, locale digits) or `java.time` — the point
  is **formatting**, not calendar computation. Arabic gets **Arabic-Indic digits + Arabic month
  names**. Gregorian long date via `DateTimeFormatter.ofLocalizedDate(FormatStyle.FULL)` (not the
  invalid `DateTimeFormatter.FULL`). Pin the Istanbul zone + app locale.

---

## 7. Theming + design system
- **`data class NamazTheme(...)`** provided via **`CompositionLocal` (`LocalNamazTheme`)**, two factory
  instances selected by a persisted enum. Composables read tokens (`theme.accent`,
  `theme.prayerColor(p)`, `theme.font(role, style)`) — **never hardcode colors/fonts**.
- **Default theme** = Material 3 baseline (followSystem light/dark), default `FontFamily`, tabular
  figures for countdowns. Keep it looking like a normal Material app (the parity baseline).
- **Arc theme** = fixed **dark/gold**, forces dark, three bundled fonts. Tokens (sRGB hex): surface
  `#10152B`, surface2 `#161D38`, card gradient `#161D38`→`#121733`, line `#E9ECF8`@6.5%, text
  `#EEF0F8`, muted `#8B92AE`, faint `#5A6182`, **accent `#E7B873`**, accentSoft `#E7B873`@12%, success
  `#6FCF97`, error `#E0796B`. **Night background** = `Brush.radialGradient` center (0.5, −0.08), stops
  `#131A36`@0 → `#080B1A`@0.46 → `#05070F`@1.0.
- **Six-prayer palette** (shared by both themes; index = `Prayer.allCases`): İmsak `#6E7AB8`, **Güneş
  `#D7A07C` @ 0.5 alpha**, Öğle `#F2C84B`, İkindi `#E89B4C`, Akşam `#D4663C`, Yatsı `#7E6CC0`.
- **Fonts** (copy the `.ttf` from `Sources/Shared/Fonts/` into `res/font/`): **Fraunces** =
  display/headings/day-numbers/hero; **Hanken Grotesk** = body; **Spline Sans Mono** =
  numerals/times/countdowns.

---

## 8. Localization, RTL, accessibility
- **EN (default) · TR · AR** → `res/values/`, `values-tr/`, `values-ar/`; ~**90 keys** to translate +
  a localized `app_name`. **Numbered positional args** (`%1$s`, `%2$s`) — word order flips (notification
  body `It's %@ time in %@` → Turkish `%2$s için %1$s vakti girdi`).
- **`android:supportsRtl="true"`**; use `start`/`end`; Compose auto-mirrors. Verify the two
  hand-drawn surfaces (compass, month grid). **Compass needle exempt from mirroring** (§6.2). Arabic
  countdown uses **Arabic-Indic numerals**.
- **Plurals:** route every count-bearing string (`in N minutes`, `N prayers`) through Android
  `plurals`/`quantityString` — **Arabic has all 6 CLDR categories** (zero/one/two/few/many/other);
  hardcoded counts will be grammatically wrong. Audit the 90 keys for inflected strings.
- **Accessibility:** honor `fontScale`; the dense Monthly chart has hardcoded dp (gutter 34, row 20,
  dot 2.3/3.4) — decide which metrics are `sp`-scaled vs fixed and **make `fontScale ∈ {1.0, 1.5, 2.0}`
  a Roborazzi test axis** (they'll collide/clip at 2.0 otherwise). Replicate the month-chart per-row
  TalkBack summary.

---

## 9. Testing
- **Golden-test-first.** Port the seven Swift suites (`PrayerScheduleTests`, `QiblaTests`,
  `LocationMatcherTests`, `SearchMatchingTests`, `PrayerDayDecodingTests`, `PlaceDecodingTests`,
  `CacheFreshnessTests`) into `:domain` JVM tests **before** any UI. These pin the subtle rules
  (Istanbul tz/DST, Turkish folding + Ankara fallback, strict-`>`/inclusive-`≤`, freshness).
- **The hard, highest-risk tests neither generic plan specifies — write these explicitly:**
  - **Self-chaining alarm:** fire alarm N (Robolectric `ShadowAlarmManager`) → **assert alarm N+1 is
    scheduled** (a bug here silently stops all future prayer alerts).
  - **Reschedule paths:** `BOOT_COMPLETED` / `TIMEZONE_CHANGED` / `MY_PACKAGE_REPLACED` rebuild the
    schedule.
  - **`canScheduleExactAlarms()==false`** degrades **without dropping alerts**.
  - **Circular low-pass filter 0/360 seam** (compass) — no long-way spin.
- Compose UI tests for the screens; **Roborazzi** screenshots across **theme × locale × dark ×
  fontScale**; fake `HeadingSource`/sensor + fake location for the Qibla/location code; Turbine for
  `StateFlow` emissions.

---

## 10. Build + CI
- **Gradle version catalog** (`gradle/libs.versions.toml`) — mandatory; single source of truth. Consider
  convention plugins for shared config.
- **GitHub Actions**, **path-filtered** to `android/**` (monorepo — doesn't run on Swift changes):
  - PR gate: lint → **`:domain` JVM tests (fast, first)** → Compose/Robolectric tests → Roborazzi →
    `assembleDebug`. **Plus the merged-manifest guard** (fail on `ACCESS_BACKGROUND_LOCATION` /
    `ACCESS_FINE_LOCATION`).
  - Release: `bundleRelease` → sign → Play (staged rollout).
- **Play App Signing**; upload key in CI secrets.
- **Versioning:** launch at **`versionName` 1.0.0** (matches the iOS/macOS train); `versionCode` = CI
  build number (monotonic).

---

## 11. Play Store release (the declarations that actually gate submission)
Add a **Play declarations checklist** to the release phase — the exact-alarm justification is only one
of several:
1. **Data Safety form** — the app **collects device location** (coarse) and **shares a coordinate with
   the Geocoder** (a Google backend on the GMS build) and with `ezanvakti.emushaf.net`. Declare
   location as *collected* and the reverse-geocode as *shared/ephemeral*. An inaccurate form is a
   common rejection/enforcement cause — **hard gate**.
2. **Location-permission justification** (coarse, foreground only; **no** background).
3. **Exact-alarm justification** (for `SCHEDULE_EXACT_ALARM`; the permission-state-changed receiver is
   relevant only to this path, not to `USE_EXACT_ALARM`).
4. **Promoted-notification eligibility** *if* the Live Updates flag ships.
- **Privacy policy** — reuse the existing GitHub Pages policy
  (`https://olcayertas.github.io/prayer-time/privacy/`) with an Android Data-Safety mapping.
- **Crash reporting:** **Sentry, opt-in, privacy-gated** — **not Firebase Crashlytics** (it needs GMS →
  won't report on the de-Googled users we build the fallback for; and it would get a future F-Droid
  build rejected). A FOSS flavor must be crash-reporting-free or self-hosted (ACRA).
- **Listing assets** (per locale × 3, **AR screenshots must actually be RTL**): 512×512 hi-res icon,
  1024×500 feature graphic, ≥2 phone screenshots, short/full descriptions. Reuse the icon crescent+star
  identity; add an **adaptive icon** (foreground/background + `<monochrome>` themed layer) and the
  separate **notification small-icon** silhouette.

---

## 12. Repo strategy + KMP
- **Monorepo** — `android/` inside `olcayertas/prayer-time`, path-filtered CI. One product, shared
  identity/assets/privacy-policy, easy cross-referencing of the Swift source of truth. (A separate repo
  only wins if the teams/release cadences diverge — they don't.)
- **No KMP.** The genuinely shareable surface (the pure algorithms) is a few hundred lines; everything
  that touches the platform (SwiftUI↔Compose, WidgetKit↔Glance, ActivityKit↔notifications,
  CoreLocation↔Fused, notifications) does **not** share. Wrapping the tiny core in KMP would add build
  complexity and slow the mature Swift pipeline for little gain. **Instead: keep `:domain`
  Android-import-free** (the §3 hedge) and **share the test corpus** (the same golden fixtures validate
  both ports). The one trigger to revisit KMP: a **Wear OS tile** (out of scope, §14).

---

## 13. Phased roadmap (~13 eng-weeks, domain-first)
| Phase | Deliverable | Exit gate |
|---|---|---|
| 0 · Scaffold | `android/` module, version catalog, CI skeleton, Compose + M3 + Hilt wired, edge-to-edge + splash | Empty app builds; CI green |
| 1 · Domain | Port `PrayerSchedule`/`Qibla`/`LocationMatcher`/DTOs/freshness into `:domain` **+ the 7 golden suites** | All ported tests green (the tested spine) |
| 2 · Data | EzanVakti Retrofit repos, JSON month cache, Proto DataStore | Repo integration tests; real month fetched + cached |
| 3 · Today + Nav + theming | Bottom-nav, Today screen, 1 Hz countdown, **Default + Arc themes**, palette, fonts | Today renders both themes; Roborazzi baseline |
| 4 · Monthly | Focus Card + chart, shared row layout, tap-to-promote, scroll-to-center | Screenshot parity vs iOS at the key widths |
| 5 · Settings + location | Settings screen, Automatic/Pinned, cascading searchable picker, Fused + Geocoder + matcher, **+ bundled offline-centroid geocoder** | Location resolves to a district (Googled + de-Googled); Ankara fallback covered |
| 6 · Notifications | Exact-alarm scheduler, self-chaining, boot/tz reschedule, channels, contextual `POST_NOTIFICATIONS`, OEM nudge | Alarm-chain + reschedule + degrade tests green; fires on device |
| 7 · Widget + Live Activity eq. | Glance widget (+ `Chronometer` interop), ongoing chronometer notification (+ optional Live Update flag) | Widget follows selected district; countdown ticks |
| 8 · Qibla | Sensors + declination-corrected bearing, calibration, no-compass + denied states, needle anim | Points correctly on device; RTL/uncorrected paths covered |
| 9 · Polish + release | **State matrix** (cold-empty/offline/error/denied/no-compass/loading × screen), a11y `fontScale` audit, plurals, insets audit, i18n QA, icons, Play declarations + assets, staged rollout | Play internal-testing track live |

---

## 14. Risks + decisions to confirm

**Ranked risks (with mitigations)**
1. **OEM battery-killers cancel prayer alarms** (Xiaomi/Oppo/Samsung/Huawei) — top reliability risk for
   this audience → battery-optimization nudge + boot reschedule + document. (§6.1)
2. **Unofficial EzanVakti API is a *present-tense* dependency** — single volunteer host, keyless, no
   SLA. If it disappears mid-launch the app is dead. Mitigation: the AwqatSalah repo seam **+ a
   concrete cutover trigger** (error-rate/host-down threshold). **AwqatSalah needs OAuth client
   registration with Diyanet — start that credential lead-time now**, it can't be done at cutover.
3. **De-Googled automatic location** — mitigated by the **bundled Turkey district-centroid geocoder**
   (v1 scope); `Geocoder` is a first-try precision optimization on Googled devices only. (§6.3)
4. **Exact-alarm Play policy** — pick `SCHEDULE_EXACT_ALARM`; inexact fallback fires late (correctness).
   (§6.1)
5. **Turkish folding / Ankara fallback** correctness — ported tests are the guard. (§4.3)
6. **Istanbul tz/DST discipline** — one un-pinned zone = wrong times. (§4.3)
7. **Glance `Chronometer` interop** may not render as assumed — verify early. (§6.4)
8. **Monthly chart complexity** at large `fontScale` / RTL — screenshot-tested axes. (§8/§9)
9. **Live Updates / promoted notification** best-effort — behind an off flag. (§6.5)

**Decisions to confirm** (I've defaulted each; override any):
1. **Repo:** monorepo `android/` in `olcayertas/prayer-time`. ✅ recommended.
2. **v1 scope:** phone-only, full parity **minus** lock-screen widgets & Dynamic Island. ✅
3. **Exact alarms:** `SCHEDULE_EXACT_ALARM` + rationale screen. ✅
4. **Crash reporting:** Sentry, opt-in. ✅ (not Firebase.)
5. **Adhan audio:** **out of v1** (forces a `mediaPlayback` FGS). Revisit later.
6. **FOSS/de-Googled automatic location:** ✅ **bundle a small Turkey district-centroid offline
   geocoder** (confirmed) — nearest-centroid match to the coarse fix; works with no Play Services / no
   `Geocoder`. `Geocoder` stays as a Googled-device precision first-try.
7. **Version start:** ✅ **1.0.0** (confirmed) — matches the iOS/macOS train.
8. **Wear OS / tablet:** out of scope v1 (a Wear tile would be the KMP re-evaluation trigger). ✅
9. **Live Updates flag:** ship the ongoing notification; **Live Update promotion off by default.** ✅

---

*Provenance: synthesized from a 9-agent workflow — 2 source-code readers (Core + Features), 2 web
researchers (2026 stack + platform APIs), 2 architecture designs, and 3 adversarial critics
(correctness / feasibility / completeness). Corrections folded in inline (Nav3 version, Hijri
rationale, exact-alarm strategy, M3 Expressive stability, Play declarations, de-Googled geocoder,
OEM alarm-killing, crash reporting, plurals, state matrix, notification small-icon).*
