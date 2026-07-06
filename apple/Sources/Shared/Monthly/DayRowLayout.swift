import SwiftUI

/// The shared horizontal layout for the Monthly chart: a fixed-width trailing gutter (day number)
/// followed by six equal-width columns (one per prayer). The column header and every chart row feed
/// through this, so dots line up under their labels at any width — phone, macOS window, or the
/// macOS popover. (Handoff §3.)
struct DayRowLayout<Gutter: View, Cell: View>: View {
    @ViewBuilder var gutter: () -> Gutter
    @ViewBuilder var cell: (Int) -> Cell

    var body: some View {
        HStack(spacing: 0) {
            gutter().frame(width: MonthlyMetrics.gutter, alignment: .trailing)
            ForEach(0..<6, id: \.self) { i in
                cell(i).frame(maxWidth: .infinity)
            }
        }
    }
}
