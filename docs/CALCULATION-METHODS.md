# Calculation methods

The app shows Diyanet times by default. The EzanVakti service gives them for every place, also
outside Türkiye. A place can also offer its local authority's method. The app then calculates the
times on the device from the place's coordinates.

## Rules

- Diyanet is the default. It does not change when the user moves.
- The app lists a local method only when the authority's published parameters reproduce the
  authority's own published table. An empirical fit does not qualify.
- The Hijri date always comes from Diyanet. The app does not convert dates.
- The local method needs coordinates. Automatic mode uses the device location. Pinned mode on iOS
  and macOS forward-geocodes the chosen place once, when the user saves it. The Android picker lists
  Türkiye only, so pinned places on Android have no local method.
- Without a local method or coordinates, the app uses Diyanet, also when "local" is saved.

## Saudi Arabia: Umm al-Qura (shipped)

| Item | Value |
|---|---|
| Authority | Umm al-Qura calendar, KACST — <https://www.ummulqura.org.sa> |
| Fajr | sun 18.5° below the horizon |
| Sunrise, Maghrib | sun 0.833° below the horizon (refraction and the sun's radius) |
| Dhuhr | solar noon |
| Asr | shadow factor 1 |
| Isha | Maghrib + 90 min; Maghrib + 120 min in Ramadan (Hijri month 9, from Diyanet) |
| Rounding | up to the next minute; sunrise down |

Check: Mecca (21.4225, 39.8262), 30 October 2026. The official page gives
Fajr 05:06, Sunrise 06:22, Dhuhr 12:05, Asr 15:21, Maghrib 17:46, Isha 19:16.
The app gives the same six times. Both test suites (`PrayerCalculatorTests`, `PrayerCalculatorTest`)
pin this day.

## Bosnia and Herzegovina: Islamska zajednica (not shipped)

The IZ BiH takvim (2022 and 2023 editions) states: dawn at 18° below the horizon, isha at 17°.
The published Sarajevo vaktija (vaktija.ba, six dates in 2026) does not follow these values:

| Time | Published minus 18°/17° calculation |
|---|---|
| Zora (dawn) | 0 to +1 min |
| Izlazak sunca (sunrise) | −5 to −7 min |
| Podne (noon) | +1 to +2 min |
| Ikindija (asr) | 0 to +1 min |
| Akšam (maghrib) | +6 to +7 min |
| Jacija (isha) | −4 to −10 min |

An isha angle of 16°, with fixed safety minutes on sunrise, noon and maghrib, fits the table within
one minute. But 16° and those minutes are not published parameters. Also, the IZ BiH tables for
other towns are Sarajevo times with fixed minute corrections, not a calculation from coordinates.
So Bosnia keeps Diyanet only.

## Adding a method

1. Find the authority's published parameters and one published daily table.
2. Add a case to `LocalMethod` (Swift and Kotlin) and its country code to `forCountry`.
3. Add a golden test with at least one published day. All six times must match.
4. Add the method's name to the string catalogs (en, tr, ar).
