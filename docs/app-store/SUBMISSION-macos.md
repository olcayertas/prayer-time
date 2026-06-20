# Mac App Store submission runbook — Namaz Vakti for Mac

Publishing the **macOS** app to the Mac App Store. It's a **separate listing** from iOS (different
bundle ID), so it has its own app record, metadata, and screenshots. Shared bits (privacy policy,
App Privacy answer, age rating, pricing) match `SUBMISSION.md`.

- **App name:** Namaz Vakti for Mac (`Namaz Vakti — Mac` in Turkish) · **Bundle ID:** `com.olcayertas.NamazVakti`
  (+ widget `com.olcayertas.NamazVakti.Widget`)
- **Team:** `SNZ29V4PJZ` · **Version:** `1.0.1` · **Min macOS:** 14.0 · sandboxed, App Group enabled
- **Differences from iOS:** no Qibla (no magnetometer), no Live Activity / Dynamic Island / Lock
  Screen; the hero is the **menu bar** + the full window + a Notification Center widget.

---

## 1. Create the app record (you)
App Store Connect → **My Apps → ＋ → New App**:
- Platform **macOS**, Name **Namaz Vakti for Mac**, Primary language (suggest **Turkish**, to match iOS),
  Bundle ID **com.olcayertas.NamazVakti**, SKU `namazvakti-mac`, Full access.
- Make sure the **Free Apps** agreement is active (already is, from iOS).

## 2. Build + deliver via Xcode Cloud (you)
The macOS app has no local Apple Distribution cert, so build in the cloud (like iOS):
1. Add a **macOS Archive** workflow to Xcode Cloud on the **`NamazVakti`** scheme (Archive action,
   macOS; deployment prep **TestFlight and App Store**; post-action **TestFlight Internal Testing Only**
   to deliver to App Store Connect). The existing `ci_scripts/ci_post_clone.sh` regenerates the project.
2. Cloud signing creates the **Apple Distribution** cert + Mac App Store provisioning and **registers
   the App Group** automatically.
3. Start a build → it archives `1.0.1` and delivers the `.pkg` to the macOS app record.

## 3. Metadata via Fastlane (Claude can run, with your go)
Same API key as iOS (`fastlane/AuthKey_<KEY_ID>.p8`, App Manager role). The macOS metadata lives in
`fastlane/metadata-mac/` (tr + en-US). After the app record exists:
```sh
export ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_PATH=fastlane/AuthKey_<KEY_ID>.p8
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
fastlane mac metadata     # pushes macOS text + screenshots to the macOS app (no binary; no submit)
```
(`platform: osx`, `metadata-mac/` + `screenshots-mac/`.) If macOS screenshots double-upload like iOS
did, we'll clear + re-push.

## 4. Screenshots (1280×800 / 1440×900 / 2560×1600 / 2880×1800)
Capture the **main window** (Today + Monthly) and the **menu-bar dropdown**, light + Arc. Either:
- **You** capture on your Mac (Retina), and Claude composites them to a valid size, or
- **Claude** builds + launches the app and captures + pads to 2560×1600.

Drop the finals in `fastlane/screenshots-mac/en-US/` (and `/tr/`).

## 5. App Privacy / Age / Pricing / Category (you, one-time)
Same answers as iOS: **App Privacy → Data Not Collected**, **Age → 4+**, **Pricing → Free**,
**Category → Lifestyle**, App Review contact phone. (`SUBMISSION.md §2` reasoning applies.)

## 6. Submit (you)
Attach the delivered build to 1.0.1 → **Submit for Review**. Export compliance is already declared
(`ITSAppUsesNonExemptEncryption=false` is shared via the base Info.plist).
