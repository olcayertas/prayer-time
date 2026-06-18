import SwiftUI

extension Color {
    /// `Color(hex: 0xE7B873)` — sRGB from a 24-bit hex literal.
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

/// A fully resolved set of color + font tokens for one theme. A `Sendable` value type carried in the
/// SwiftUI environment (`\.theme`). Two factories:
/// - `.default` — every token maps to the system semantics the app used before theming (so the Default
///   theme looks identical to today and keeps automatic light/dark). Fonts are the system fonts.
/// - `.arc` — the dark/gold design from the handoff: literal hex + a night gradient + bundled fonts.
///
/// The 6-color prayer palette is shared by both themes (the app's signature); Güneş (sunrise) is dimmed.
struct Theme: Sendable {
    /// Which font family a piece of text uses; resolved per-theme.
    enum FontRole: Sendable { case display, body, mono, rounded }
    /// Root screen background; rendered by `themedRootBackground`.
    enum Background: Sendable { case system, nightGradient }

    var background: Background
    var surface: Color           // generic raised card (was Color.cardBackground)
    var surface2: Color          // chrome / bars
    var elevatedCardTop: Color   // focus-card gradient stops
    var elevatedCardBottom: Color
    var line: Color              // hairlines / dividers
    var lineStrong: Color
    var text: Color              // primary text
    var muted: Color             // secondary text (was .secondary)
    var faint: Color             // tertiary text (was .tertiary)
    var accent: Color            // (was Color.accentColor / .tint)
    var accentSoft: Color        // accent fills (hero / next-prayer)
    var success: Color           // (was .green — Qibla aligned)
    var error: Color             // (was .red)
    var prayerPalette: [Color]   // index 0…5 = İmsak…Yatsı (matches Prayer.allCases)
    /// Forced scheme: Arc = .dark (system chrome matches night); Default = nil (auto light/dark).
    var colorScheme: ColorScheme?

    private let fontResolver: @Sendable (FontRole, CGFloat, Font.Weight, Font.TextStyle) -> Font

    /// Style-based font — scales with Dynamic Type. Use for most text.
    func font(_ role: FontRole, _ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        fontResolver(role, Self.size(for: style), weight, style)
    }

    /// Fixed-size font — for dense / spec-exact layouts. Scales relative to `relativeTo` (pair with
    /// `@ScaledMetric` at the call site where the app already does).
    func font(_ role: FontRole, size: CGFloat, weight: Font.Weight = .regular,
              relativeTo style: Font.TextStyle = .body) -> Font {
        fontResolver(role, size, weight, style)
    }

    /// Prayer color, with Güneş (sunrise) dimmed — it's informational, never a prayer.
    func prayerColor(_ prayer: Prayer) -> Color {
        let base = prayerPalette[Self.prayerIndex(prayer)]
        return prayer == .gunes ? base.opacity(0.5) : base
    }

    static func prayerIndex(_ prayer: Prayer) -> Int {
        Prayer.allCases.firstIndex(of: prayer) ?? 0
    }

    /// Default point size for a text style (used to seed `Font.custom(size:relativeTo:)` on Arc).
    private static func size(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title:      return 28
        case .title2:     return 22
        case .title3:     return 20
        case .headline, .body: return 17
        case .callout:    return 16
        case .subheadline: return 15
        case .footnote:   return 13
        case .caption:    return 12
        case .caption2:   return 11
        @unknown default: return 17
        }
    }
}

extension Theme {
    /// The dawn→dusk arc — shared by both themes (the app's signature palette).
    static let sharedPrayerPalette: [Color] = [
        Color(hex: 0x6E7AB8), Color(hex: 0xD7A07C), Color(hex: 0xF2C84B),
        Color(hex: 0xE89B4C), Color(hex: 0xD4663C), Color(hex: 0x7E6CC0),
    ]

    /// Current look: system semantics (auto light/dark) + system fonts. The parity baseline.
    static let `default` = Theme(
        background: .system,
        surface: .cardBackground,
        surface2: .cardBackground,
        elevatedCardTop: .cardBackground,
        elevatedCardBottom: .cardBackground,
        line: Color.primary.opacity(0.08),
        lineStrong: Color.primary.opacity(0.14),
        text: .primary,
        muted: .secondary,
        faint: Color.secondary.opacity(0.55),
        accent: .accentColor,
        accentSoft: Color.accentColor.opacity(0.14),
        success: .green,
        error: .red,
        prayerPalette: sharedPrayerPalette,
        colorScheme: nil,
        fontResolver: { role, size, weight, _ in
            // Default keeps the exact system designs the app uses today: SF default everywhere
            // (NOT serif, NOT SF-Mono) — tabular numerals come from `.monospacedDigit()` at the
            // call sites, as today. Only the countdown uses the rounded design.
            let design: Font.Design = role == .rounded ? .rounded : .default
            return .system(size: size, weight: weight, design: design)
        }
    )

    /// The handoff's dark/gold "Arc" design.
    static let arc = Theme(
        background: .nightGradient,
        surface: Color(hex: 0x10152B),
        surface2: Color(hex: 0x161D38),
        elevatedCardTop: Color(hex: 0x161D38),
        elevatedCardBottom: Color(hex: 0x121733),
        line: Color(hex: 0xE9ECF8, alpha: 0.065),
        lineStrong: Color(hex: 0xE9ECF8, alpha: 0.11),
        text: Color(hex: 0xEEF0F8),
        muted: Color(hex: 0x8B92AE),
        faint: Color(hex: 0x5A6182),
        accent: Color(hex: 0xE7B873),
        accentSoft: Color(hex: 0xE7B873, alpha: 0.12),
        success: Color(hex: 0x6FCF97),
        error: Color(hex: 0xE0796B),
        prayerPalette: sharedPrayerPalette,
        colorScheme: .dark,
        fontResolver: { role, size, weight, style in
            let family: String = switch role {
            case .display:           "Fraunces"
            case .body:              "Hanken Grotesk"
            case .mono, .rounded:    "Spline Sans Mono"   // the design uses mono for all numerals/times
            }
            return .custom(family, size: size, relativeTo: style).weight(weight)
        }
    )
}
