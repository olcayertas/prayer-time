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
        miladiTarihUzun: String? = nil
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
