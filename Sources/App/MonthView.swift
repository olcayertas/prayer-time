import SwiftUI

/// The full cached month as a table, with today's row highlighted.
struct MonthView: View {
    @ObservedObject var store: PrayerStore

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
        .navigationTitle("Aylık")
        .overlay {
            if store.days.isEmpty {
                ProgressView("Yükleniyor…")
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            cell("Tarih", width: 100, align: .leading, bold: true)
            ForEach(Prayer.allCases) { cell($0.displayName, bold: true) }
        }
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func row(day: PrayerDay, isToday: Bool) -> some View {
        HStack(spacing: 0) {
            cell(day.miladiTarihKisa ?? "", width: 100, align: .leading)
            ForEach(Prayer.allCases) { cell(day.time(for: $0)) }
        }
        .padding(.vertical, 7)
        .fontWeight(isToday ? .semibold : .regular)
        .background(isToday ? Color.accentColor.opacity(0.14) : Color.clear)
    }

    @ViewBuilder
    private func cell(_ text: String, width: CGFloat? = nil, align: Alignment = .center, bold: Bool = false) -> some View {
        let label = Text(text)
            .font(.callout)
            .fontWeight(bold ? .semibold : .regular)
            .monospacedDigit()
        if let width {
            label.frame(width: width, alignment: align)
        } else {
            label.frame(maxWidth: .infinity, alignment: align)
        }
    }
}
