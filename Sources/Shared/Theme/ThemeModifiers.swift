import SwiftUI

extension Theme {
    /// The Arc night background — a radial gradient matching the mock
    /// (`radial-gradient(140% 80% at 50% -8%, #131A36, #080B1A 46%, #05070F)`).
    static let nightGradient = RadialGradient(
        gradient: Gradient(stops: [
            .init(color: Color(hex: 0x131A36), location: 0),
            .init(color: Color(hex: 0x080B1A), location: 0.46),
            .init(color: Color(hex: 0x05070F), location: 1),
        ]),
        center: UnitPoint(x: 0.5, y: -0.08),
        startRadius: 0,
        endRadius: 820)
}

extension View {
    /// Root screen background, applied once per top-level screen. Default = system (no-op, so the
    /// current look is preserved); Arc = the night gradient behind everything.
    @ViewBuilder
    func themedRootBackground(_ theme: Theme) -> some View {
        switch theme.background {
        case .system:
            self
        case .nightGradient:
            background(Theme.nightGradient.ignoresSafeArea())
        }
    }

    /// Generic raised-card fill (replaces `Color.cardBackground`).
    func themedCard(_ theme: Theme, cornerRadius: CGFloat = 12) -> some View {
        background(theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Applies the active theme to a scene's root content: injects `\.theme`, passes the manager
    /// (so the Appearance picker can drive it), and forces the theme's color scheme (Arc = dark).
    func themed(_ manager: ThemeManager) -> some View {
        environment(\.theme, manager.theme)
            .environmentObject(manager)
            .preferredColorScheme(manager.theme.colorScheme)
    }
}
