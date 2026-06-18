# App Store submission runbook — Namaz Vakti (iOS)

Everything needed to publish the **iOS** app to the App Store. The macOS app ships separately as a
signed/notarized DMG (see the GitHub releases) and is **not** part of this.

- **Bundle ID:** `com.olcayertas.NamazVakti.iOS` (+ embedded widget `com.olcayertas.NamazVakti.iOS.Widget`)
- **Team:** `SNZ29V4PJZ` · **Version:** `1.0.0` (build `2`) · **Min iOS:** 17.0 · **Devices:** iPhone only (v1.0)
- **Signing:** automatic; Release/archive uses *Apple Distribution* (set in `project.yml`).
- **Export compliance:** `ITSAppUsesNonExemptEncryption = false` is in the Info.plist (HTTPS only) → no per-upload question.

---

## 1. Store listing metadata (copy-paste)

**Name** (30 max)
```
Namaz Vakti — Prayer Times
```

**Subtitle** (30 max)
```
Diyanet prayer times & Qibla
```

**Promotional text** (170 max, editable anytime without review)
```
Always know the next prayer — accurate Diyanet times for your city, a live countdown, a Qibla compass, Home & Lock Screen widgets, and a beautiful new dark theme.
```

**Keywords** (100 max, comma-separated, no spaces)
```
namaz,ezan,vakti,prayer,times,diyanet,qibla,kıble,islam,muslim,salah,azan,imsak,iftar,ramadan
```

**Description** (4000 max)
```
Namaz Vakti shows accurate Muslim prayer times for your city, powered by the published tables of the Turkish Directorate of Religious Affairs (Diyanet).

Clean, fast, and private — no account, no ads, no tracking.

PRAYER TIMES
• The six daily times — İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı — for today and the whole month.
• A live countdown to the next prayer, always visible at a glance.
• Hijri and Gregorian dates.

YOUR LOCATION, YOUR WAY
• Automatic: the app finds your city and shows the right times wherever you are.
• Pinned: choose a city by hand (country → city → district) and keep it.
• Each location is cached, so it works offline and makes no unnecessary requests.

QIBLA COMPASS
• A live compass that points to the Kaaba in Mecca, using a true-north bearing from your location, with a “facing the Qibla” cue.

WIDGETS & LIVE ACTIVITY
• Home Screen widgets with the next prayer and a live countdown.
• Lock Screen widgets (rectangular, circular, inline).
• A Live Activity and Dynamic Island countdown for the next prayer.

NOTIFICATIONS
• Optional local reminders at each prayer time.

BEAUTIFUL & ACCESSIBLE
• Two themes: the clean system look (auto light/dark) and a warm dark “Arc” theme.
• Full Dynamic Type support and VoiceOver labels.
• English, Turkish, and Arabic (right-to-left).

Prayer-time data © T.C. Diyanet İşleri Başkanlığı, via the community EzanVakti service. Not affiliated with or endorsed by Diyanet.
```

**What’s New** (4000 max) — for the 1.0.0 release
```
First release of Namaz Vakti for iPhone:
• Daily and monthly Diyanet prayer times with a live countdown.
• Automatic or pinned location.
• Qibla compass.
• Home Screen, Lock Screen, Live Activity, and Dynamic Island.
• Prayer-time notifications.
• Light/dark system theme and a new dark “Arc” theme.
• English, Turkish, and Arabic.
```

**URLs**
- Support URL: `https://github.com/olcayertas/prayer-time`
- Marketing URL (optional): `https://olcayertas.github.io/prayer-time/`
- Privacy Policy URL: `https://olcayertas.github.io/prayer-time/privacy/`  ← requires GitHub Pages enabled (see §5)

**Other fields**
- Primary category: **Lifestyle** · Secondary (optional): **Reference**
- Copyright: `2026 Olcay Ertaş`
- Price: **Free**, all territories
- Age rating: **4+** — answer “None” to every content question.
- Primary language: English (U.S.). (You can add a Turkish localization of this listing later.)

---

## 2. App Privacy ("nutrition label")

Recommended answer: **Data Not Collected.**

Reasoning (accurate for this app): the developer runs no servers and transmits no user data. Location
is used **on device**; turning coordinates into a place name uses Apple’s `CLGeocoder` (handled by
Apple, not the developer). Fetching prayer times sends only a **district identifier** (a city choice),
which is not personal data. There are no analytics or advertising SDKs.

If a reviewer ever pushes back on "Data Not Collected" for an app that requests location, the safe
fallback is to declare exactly one item:
- **Location → Coarse/Precise Location**, used for **App Functionality**, **not** linked to identity,
  **not** used for tracking.

---

## 3. Screenshots

Required: one set for **6.9-inch iPhone** (1320 × 2868 portrait). Apple scales these down for smaller
iPhones, so a single 6.9" set is enough.

A ready-to-upload set is generated into `docs/app-store/screenshots/` from the iPhone 16 Pro Max
simulator (Today + Monthly, light + Arc). The Qibla compass needs a magnetometer, so capture that one
on a real iPhone if you want it in the set (optional — 1–10 screenshots allowed; the generated set is
sufficient to ship).

---

## 4. Apple Developer portal — App IDs (one-time)

The app record needs the bundle IDs registered as App IDs. Either:
- **Let Xcode do it:** the first archive/upload with automatic signing auto-creates both App IDs and
  the Apple Distribution certificate + App Store profiles, **or**
- **Register by hand:** developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → +
  → App IDs → App → register `com.olcayertas.NamazVakti.iOS` and `com.olcayertas.NamazVakti.iOS.Widget`
  (no extra capabilities needed — Location, Widgets, and Live Activities require no capability toggle).

Also: App Store Connect → Business (Agreements, Tax, and Banking) → make sure the **free apps**
agreement shows **Active**. A free app needs no tax/banking forms.

---

## 5. Host the privacy policy (GitHub Pages)

The policy lives at `docs/privacy/index.html`. Enable Pages once:
- GitHub repo → Settings → Pages → Source = **Deploy from a branch** → Branch = `main`, folder = `/docs`
  → Save. After a minute it’s live at `https://olcayertas.github.io/prayer-time/privacy/`.

(Or via CLI — Claude can run this with your go:
`gh api -X POST repos/olcayertas/prayer-time/pages -f source.branch=main -f source.path=/docs`.)

---

## 6. Create the app & submit (App Store Connect)

1. appstoreconnect.apple.com → **My Apps → + → New App**.
   - Platform **iOS**, Name `Namaz Vakti — Prayer Times`, Primary language **English (U.S.)**,
     Bundle ID `com.olcayertas.NamazVakti.iOS`, SKU `namazvakti-ios` (any unique string), Full access.
2. Fill the **1.0.0** version page with the metadata from §1, upload the §3 screenshots, set category,
   age rating, and the privacy policy URL.
3. Set **App Privacy** (§2) and **Pricing** (Free).
4. **Upload the build** (see §7). After processing, pick build `1.0.0 (2)` on the version page.
5. **Submit for Review.** (Export compliance is already answered via the Info.plist key.)

---

## 7. Archive & upload the build

**Option A — Xcode Organizer (simplest):**
1. `xcodegen generate`
2. Open `NamazVakti.xcodeproj`, select the **NamazVaktiiOS** scheme, destination **Any iOS Device**.
3. Product → **Archive** (uses Release → Apple Distribution).
4. In Organizer: **Distribute App → App Store Connect → Upload**. Xcode creates the distribution cert
   and profiles automatically.

**Option B — command line (Claude can run this with your go):**
```sh
xcodegen generate
xcodebuild -project NamazVakti.xcodeproj -scheme NamazVaktiiOS -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/NamazVaktiiOS.xcarchive \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build/NamazVaktiiOS.xcarchive \
  -exportOptionsPlist Distribution/ExportOptions-AppStore.plist \
  -exportPath build/export -allowProvisioningUpdates
# then upload build/export/*.ipa with Transporter, or:
xcrun altool --upload-app -f build/export/NamazVaktiiOS.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```
Option B needs the App Store Connect API key as a `.p8` file plus its Key ID and Issuer ID. (The
notarytool keychain profile used for the macOS DMG is a different credential and can’t be reused here.)

> Note: archiving with `-allowProvisioningUpdates` (or Organizer) will **create an Apple Distribution
> certificate and App Store provisioning profiles on your developer account** the first time — expected,
> but it does modify your account, so it’s done only on your go.
