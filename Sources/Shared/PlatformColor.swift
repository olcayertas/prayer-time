import SwiftUI

extension Color {
    /// Subtle fill for cards / tiles, resolved per platform so the shared views work on
    /// both macOS and iOS. macOS uses the control background; iOS uses the grouped
    /// secondary system background (one shade off the default background).
    static var cardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
}
