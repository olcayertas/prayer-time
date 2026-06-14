import SwiftUI

/// The full cached month as a table, with today's row highlighted. On a wide window
/// (macOS / iPad) the prayer columns are labelled with names; on a compact iPhone width
/// they switch to icons and a smaller font so all six fit without crowding.
struct MonthView: View {
    @ObservedObject var store: PrayerStore
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    /// True only on a narrow phone width (iPhone portrait). iPad / macOS stay regular.
    private var isCompact: Bool {
        #if os(iOS)
        sizeClass == .compact
        #else
        false
        #endif
    }

    private var cellFont: Font { isCompact ? .footnote : .callout }
    private var dateWidth: CGFloat { isCompact ? 86 : 100 }

    var body: some View {
        let todayKey = store.schedule.day(on: Date())?.miladiTarihKisa
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(store.days) { day in
                        row(day: day, isToday: day.miladiTarihKisa == todayKey)
                        Divider()
                    }
                } header: {
                    headerRow
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Monthly")
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .overlay {
            if store.days.isEmpty {
                ProgressView("Loading…")
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            cell(String(localized: "Date"), width: dateWidth, align: .leading, bold: true)
            ForEach(Prayer.allCases) { prayer in
                Group {
                    if isCompact {
                        Image(systemName: prayer.symbolName)
                    } else {
                        Text(prayer.displayName).fontWeight(.semibold)
                    }
                }
                .font(cellFont)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func row(day: PrayerDay, isToday: Bool) -> some View {
        HStack(spacing: 0) {
            cell(day.miladiTarihKisa ?? "", width: dateWidth, align: .leading)
            ForEach(Prayer.allCases) { cell(day.time(for: $0)) }
        }
        .padding(.vertical, 7)
        .fontWeight(isToday ? .semibold : .regular)
        .background(isToday ? Color.accentColor.opacity(0.14) : Color.clear)
    }

    @ViewBuilder
    private func cell(_ text: String, width: CGFloat? = nil, align: Alignment = .center, bold: Bool = false) -> some View {
        let label = Text(text)
            .font(cellFont)
            .fontWeight(bold ? .semibold : .regular)
            .monospacedDigit()
        if let width {
            label.frame(width: width, alignment: align)
        } else {
            label.frame(maxWidth: .infinity, alignment: align)
        }
    }
}
