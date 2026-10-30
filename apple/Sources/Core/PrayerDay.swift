import Foundation

/// The six daily times Diyanet publishes, in chronological order.
enum Prayer: String, CaseIterable, Codable, Sendable, Identifiable {
    case imsak, gunes, ogle, ikindi, aksam, yatsi

    var id: String { rawValue }

    /// Turkish display name as shown on the Diyanet site.
    var displayName: String {
        switch self {
        case .imsak: return String(localized: "Dawn", comment: "Prayer time: Diyanet İmsak (start of fast / Fajr)")
        case .gunes: return String(localized: "Sunrise", comment: "Prayer time: Diyanet Güneş (sunrise / Shuruq)")
        case .ogle: return String(localized: "Noon", comment: "Prayer time: Diyanet Öğle (Dhuhr)")
        case .ikindi: return String(localized: "Afternoon", comment: "Prayer time: Diyanet İkindi (Asr)")
        case .aksam: return String(localized: "Sunset", comment: "Prayer time: Diyanet Akşam (Maghrib)")
        case .yatsi: return String(localized: "Night", comment: "Prayer time: Diyanet Yatsı (Isha)")
        }
    }

    /// SF Symbol roughly matching the time of day.
    var symbolName: String {
        switch self {
        case .imsak: return "moon.stars.fill"
        case .gunes: return "sunrise.fill"
        case .ogle: return "sun.max.fill"
        case .ikindi: return "sun.min.fill"
        case .aksam: return "sunset.fill"
        case .yatsi: return "moon.fill"
        }
    }
}

/// One day of prayer times as returned by the EzanVakti wrapper of Diyanet data.
///
/// Field names mirror the JSON (Turkish, PascalCase). Unknown keys are ignored by the
/// decoder, so we only model what the app consumes.
struct PrayerDay: Codable, Equatable, Sendable, Identifiable {
    /// Stable id for lists/tables (one row per day).
    var id: String { miladiTarihKisa ?? "\(imsak)-\(ogle)-\(yatsi)" }

    let imsak: String
    let gunes: String
    let ogle: String
    let ikindi: String
    let aksam: String
    let yatsi: String

    let gunesDogus: String?
    let gunesBatis: String?
    let kibleSaati: String?

    let hicriTarihUzun: String?
    let hicriTarihKisa: String?
    let miladiTarihKisa: String?
    let miladiTarihUzun: String?
    /// "2026-10-26T00:00:00.0000000+01:00": local midnight of the day with the place's UTC offset.
    /// Abroad the times are local clock times, so this offset (not Europe/Istanbul) anchors them.
    let miladiTarihUzunIso8601: String?

    enum CodingKeys: String, CodingKey {
        case imsak = "Imsak"
        case gunes = "Gunes"
        case ogle = "Ogle"
        case ikindi = "Ikindi"
        case aksam = "Aksam"
        case yatsi = "Yatsi"
        case gunesDogus = "GunesDogus"
        case gunesBatis = "GunesBatis"
        case kibleSaati = "KibleSaati"
        case hicriTarihUzun = "HicriTarihUzun"
        case hicriTarihKisa = "HicriTarihKisa"
        case miladiTarihKisa = "MiladiTarihKisa"
        case miladiTarihUzun = "MiladiTarihUzun"
        case miladiTarihUzunIso8601 = "MiladiTarihUzunIso8601"
    }

    init(
        imsak: String,
        gunes: String,
        ogle: String,
        ikindi: String,
        aksam: String,
        yatsi: String,
        gunesDogus: String? = nil,
        gunesBatis: String? = nil,
        kibleSaati: String? = nil,
        hicriTarihUzun: String? = nil,
        hicriTarihKisa: String? = nil,
        miladiTarihKisa: String? = nil,
        miladiTarihUzun: String? = nil,
        miladiTarihUzunIso8601: String? = nil
    ) {
        self.imsak = imsak
        self.gunes = gunes
        self.ogle = ogle
        self.ikindi = ikindi
        self.aksam = aksam
        self.yatsi = yatsi
        self.gunesDogus = gunesDogus
        self.gunesBatis = gunesBatis
        self.kibleSaati = kibleSaati
        self.hicriTarihUzun = hicriTarihUzun
        self.hicriTarihKisa = hicriTarihKisa
        self.miladiTarihKisa = miladiTarihKisa
        self.miladiTarihUzun = miladiTarihUzun
        self.miladiTarihUzunIso8601 = miladiTarihUzunIso8601
    }

    /// The day's UTC offset in seconds, read from the trailing "+hh:mm" / "-hh:mm" / "Z" of
    /// `miladiTarihUzunIso8601`. Nil when absent (e.g. a month cached by an older version), so the
    /// caller falls back to Europe/Istanbul. The offset is the one at local midnight: on a DST change
    /// day the times after the change are an hour off for that one day.
    var utcOffsetSeconds: Int? {
        guard let iso = miladiTarihUzunIso8601?.trimmingCharacters(in: .whitespaces), !iso.isEmpty else { return nil }
        if iso.hasSuffix("Z") { return 0 }
        guard iso.count >= 6 else { return nil }
        let tail = iso.suffix(6) // "+01:00"
        guard let sign = tail.first, sign == "+" || sign == "-" else { return nil }
        let parts = tail.dropFirst().split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return (sign == "-" ? -1 : 1) * (h * 3600 + m * 60)
    }

    /// A copy with the six prayer times (and the sunrise/sunset extras) replaced, everything else
    /// (dates, Hijri, offset) kept. Used by on-device calculation methods.
    func replacingTimes(
        imsak: String, gunes: String, ogle: String, ikindi: String, aksam: String, yatsi: String
    ) -> PrayerDay {
        PrayerDay(
            imsak: imsak, gunes: gunes, ogle: ogle, ikindi: ikindi, aksam: aksam, yatsi: yatsi,
            gunesDogus: gunes, gunesBatis: aksam, kibleSaati: kibleSaati,
            hicriTarihUzun: hicriTarihUzun, hicriTarihKisa: hicriTarihKisa,
            miladiTarihKisa: miladiTarihKisa, miladiTarihUzun: miladiTarihUzun,
            miladiTarihUzunIso8601: miladiTarihUzunIso8601
        )
    }

    /// The published `HH:mm` string for a given prayer.
    func time(for prayer: Prayer) -> String {
        switch prayer {
        case .imsak: return imsak
        case .gunes: return gunes
        case .ogle: return ogle
        case .ikindi: return ikindi
        case .aksam: return aksam
        case .yatsi: return yatsi
        }
    }
}
