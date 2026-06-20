import WidgetKit
import SwiftUI

struct PrayerEntry: TimelineEntry, Sendable {
    let date: Date
    let nextPrayer: Prayer?
    let nextDate: Date?
    let day: PrayerDay?
    let locationName: String
}

/// Builds the widget timeline. It shares the app's App Group, so it reads the user's selected
/// (Automatic or Pinned) district + the same cached month, and fetches once if the cache is empty.
/// One entry per upcoming prayer boundary; the live countdown uses `Text(timerInterval:)`,
/// so no per-second entries are needed.
struct PrayerTimelineProvider: TimelineProvider {
    // Read from the shared App Group so the widget follows the app's Automatic/Pinned location
    // (the app writes these on every location change and reloads the widget timelines).
    private var districtId: String {
        AppGroup.defaults.string(forKey: AppGroup.selectedDistrictIdKey) ?? Config.defaultDistrictId
    }
    private var locationName: String {
        AppGroup.defaults.string(forKey: AppGroup.selectedDistrictNameKey) ?? Config.defaultLocationName
    }

    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), nextPrayer: .ogle, nextDate: Date().addingTimeInterval(3600),
                    day: nil, locationName: locationName)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (PrayerEntry) -> Void) {
        let days = PrayerCache().load(districtId: districtId) ?? []
        completion(entries(from: days, now: Date()).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<PrayerEntry>) -> Void) {
        let cache = PrayerCache()
        if let cached = cache.load(districtId: districtId), !cached.isEmpty {
            completion(makeTimeline(from: cached))
            return
        }
        Task {
            do {
                let days = try await EzanVaktiProvider().monthlyTimes(districtId: districtId)
                cache.save(days, districtId: districtId)
                completion(makeTimeline(from: days))
            } catch {
                let entry = PrayerEntry(date: Date(), nextPrayer: nil, nextDate: nil,
                                        day: nil, locationName: locationName)
                completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))))
            }
        }
    }

    private func makeTimeline(from days: [PrayerDay]) -> Timeline<PrayerEntry> {
        let now = Date()
        let entries = self.entries(from: days, now: now)
        let reload = entries.last?.nextDate ?? now.addingTimeInterval(3600)
        let safeEntries = entries.isEmpty
            ? [PrayerEntry(date: now, nextPrayer: nil, nextDate: nil, day: days.first, locationName: locationName)]
            : entries
        return Timeline(entries: safeEntries, policy: .after(reload))
    }

    /// One entry per upcoming prayer: it activates at the previous boundary and points at
    /// the next prayer, so the displayed "next" advances as each time passes.
    private func entries(from days: [PrayerDay], now: Date) -> [PrayerEntry] {
        let schedule = PrayerSchedule(days: days)
        let upcoming = schedule.sortedTimes().filter { $0.date > now }.prefix(16)
        var result: [PrayerEntry] = []
        var start = now
        for (prayer, date) in upcoming {
            let day = schedule.day(on: start) ?? schedule.day(on: date)
            result.append(PrayerEntry(date: start, nextPrayer: prayer, nextDate: date,
                                      day: day, locationName: locationName))
            start = date
        }
        return result
    }
}

struct NamazVaktiWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PrayerEntry

    var body: some View {
        switch family {
        #if os(iOS)
        case .accessoryRectangular: rectangularView.containerBackground(.clear, for: .widget)
        case .accessoryCircular: circularView.containerBackground(.clear, for: .widget)
        case .accessoryInline: inlineView
        #endif
        case .systemMedium: mediumView.containerBackground(.fill.tertiary, for: .widget)
        default: smallView.containerBackground(.fill.tertiary, for: .widget)
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.locationName)
                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 0)
            if let next = entry.nextPrayer, let nextDate = entry.nextDate {
                Label(next.displayName, systemImage: next.symbolName)
                    .font(.headline)
                Text(timerInterval: entry.date...nextDate, countsDown: true)
                    .font(.system(.title2, design: .rounded)).monospacedDigit()
                if let day = entry.day {
                    Text("Time \(day.time(for: next))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("Prayer Times").font(.headline)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.locationName)
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Spacer(minLength: 0)
                if let next = entry.nextPrayer, let nextDate = entry.nextDate {
                    Text("Next").font(.caption2).foregroundStyle(.secondary)
                    Label(next.displayName, systemImage: next.symbolName)
                        .font(.headline)
                    Text(timerInterval: entry.date...nextDate, countsDown: true)
                        .font(.system(.title2, design: .rounded)).monospacedDigit()
                } else {
                    Text("Prayer Times").font(.headline)
                }
                Spacer(minLength: 0)
            }
            if let day = entry.day {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Prayer.allCases) { prayer in
                        let isNext = prayer == entry.nextPrayer
                        HStack {
                            Text(prayer.displayName)
                            Spacer()
                            Text(day.time(for: prayer)).monospacedDigit()
                        }
                        .font(.caption)
                        .fontWeight(isNext ? .semibold : .regular)
                        .foregroundStyle(isNext ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    #if os(iOS)
    /// Lock Screen rectangular: next prayer + a live countdown.
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let next = entry.nextPrayer, let nextDate = entry.nextDate {
                Label(next.displayName, systemImage: next.symbolName)
                    .font(.headline).lineLimit(1)
                Text(timerInterval: entry.date...nextDate, countsDown: true)
                    .font(.system(.title3, design: .rounded)).monospacedDigit()
                if let day = entry.day {
                    Text("Time \(day.time(for: next))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("Prayer Times").font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Lock Screen circular: the next prayer's icon over a live countdown.
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let next = entry.nextPrayer, let nextDate = entry.nextDate {
                VStack(spacing: 0) {
                    Image(systemName: next.symbolName).font(.caption)
                    Text(timerInterval: entry.date...nextDate, countsDown: true)
                        .font(.system(.caption2, design: .rounded))
                        .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                }
            } else {
                Image(systemName: "moon.stars.fill")
            }
        }
    }

    /// Lock Screen inline (beside the clock): next prayer + its time.
    @ViewBuilder
    private var inlineView: some View {
        if let next = entry.nextPrayer, let day = entry.day {
            Label("\(next.displayName) \(day.time(for: next))", systemImage: next.symbolName)
        } else {
            Label("Prayer Times", systemImage: "moon.stars.fill")
        }
    }
    #endif
}

struct NamazVaktiWidget: Widget {
    let kind = "NamazVaktiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            NamazVaktiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("The next prayer time and countdown.")
        .supportedFamilies(Self.supportedFamilies)
    }

    /// Home Screen on every platform; iOS adds the three Lock Screen accessory families.
    private static var supportedFamilies: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }
}

@main
struct NamazVaktiWidgetBundle: WidgetBundle {
    var body: some Widget {
        NamazVaktiWidget()
        #if os(iOS)
        PrayerLiveActivity()
        #endif
    }
}
