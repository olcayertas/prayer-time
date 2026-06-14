# Localization

Prayer Times ships in **English (source), Turkish, and Arabic**, and is built to add more
languages with minimal effort. This document covers how localization is wired and the
roadmap for new languages.

## How it's structured

- **`Sources/Core/Localizable.xcstrings`** — one String Catalog with every UI/domain string
  (prayer names, errors, notification formats, buttons, labels). It's in `Sources/Core`, so it
  compiles into **every** target — both apps and both widgets.
- **`Sources/{App,iOS}/InfoPlist.xcstrings`** / **`Sources/Widget/InfoPlist.xcstrings`** — the
  localized app and widget **names** (`CFBundleDisplayName`). ⚠️ Each key MUST also carry an `en`
  value; without it the compiled `en.lproj/InfoPlist.strings` falls back to the literal key, so the
  app shows "CFBundleDisplayName" instead of "Prayer Times".
- **`Sources/Shared/DateLocalizer.swift`** — the Diyanet API returns the long Gregorian and Hijri
  dates as Turkish-only text, so we reformat the numeric short dates (`dd.MM.yyyy`) locally with
  a locale-aware `DateFormatter` (Hijri via the `islamicUmmAlQura` calendar). The Diyanet Hijri
  numbers are preserved; only the month names / digits get localized.
- **English is the development language** (`options.developmentLanguage: en` in `project.yml`).
  Source strings in code *are* the keys, so English needs no translation table.
- **Prayer names** use plain-English descriptions (Dawn, Sunrise, Noon, Afternoon, Sunset,
  Night) mapped to the canonical terms in each language (e.g. Arabic الفجر/الظهر/العصر/المغرب/العشاء).
- **RTL** is automatic: the UI uses semantic `.leading`/`.trailing` (never `.left`/`.right`),
  so SwiftUI mirrors the layout for right-to-left languages. Arabic exercises this today, which
  means every future RTL language (Urdu, Farsi, Pashto, …) is already covered.

## Adding a language — step by step

1. Open `Sources/Core/Localizable.xcstrings` in Xcode → **+** → pick the language, and translate
   every key. (Or edit the JSON directly — each key gets a `"<lang>": { "stringUnit": … }`.)
   - Mind the **positional specifiers** where word order differs, e.g. the notification body
     `It's %@ time in %@.` → Turkish `%2$@ için %1$@ vakti girdi.`
2. Add the same language to **`Sources/App/InfoPlist.xcstrings`**, **`Sources/iOS/InfoPlist.xcstrings`**,
   and **`Sources/Widget/InfoPlist.xcstrings`** with the translated app/widget name (keep the `en` value).
3. `xcodegen generate && xcodebuild … build`, then confirm a `<lang>.lproj` appears in both
   `NamazVakti.app/Contents/Resources` and the widget `.appex`.
4. Smoke-test: `…/NamazVakti.app/Contents/MacOS/NamazVakti -AppleLanguages "(<lang>)"`.
5. **Native-speaker review** before shipping — machine/assisted translations of religious
   terminology must be verified.

No code changes are needed to add a language; it's catalog + review.

## Roadmap — prioritized by Muslim population

Localization is per *language*, so priority is by number of Muslim speakers rather than by
country. Each phase after the first is purely translation + review.

| Phase | Languages | Why / reach | RTL |
|------|-----------|-------------|-----|
| **1 — shipped** | Arabic, English, Turkish | Arabic ≈ all of MENA + the shared religious language; English = global/diaspora + official in Nigeria/Pakistan/India; Turkish = the original audience | ar |
| **2** | Indonesian (`id`), Urdu (`ur`), Bengali (`bn`) | Indonesia ~240M (largest Muslim nation); Urdu ~430M across Pakistan + Indian Muslims; Bengali ~150M Bangladesh | ur |
| **3** | Persian/Farsi (`fa`), Hausa (`ha`), French (`fr`) | Iran / Afghan-Dari / Tajik ~110M; Hausa ~80M West Africa; French = Maghreb + Sahel + EU diaspora | fa |
| **4** | Malay (`ms`), Pashto (`ps`), Swahili (`sw`), Russian (`ru`) | SE Asia; Afghanistan/Pakistan; East Africa; Central Asia & Caucasus | ps |
| **5 — long tail** | Azerbaijani, Uzbek, Kazakh, Kurdish, Albanian, Bosnian, Somali, German, Chinese, Tamil/Malayalam … | smaller national + diaspora communities | ku, ckb |

**Note on RTL:** because Arabic is in Phase 1, the right-to-left layout is already proven — so
Urdu, Farsi, and Pashto in later phases need translation only, no layout work.
