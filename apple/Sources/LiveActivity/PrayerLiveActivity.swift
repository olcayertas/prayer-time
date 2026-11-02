import ActivityKit
import SwiftUI
import WidgetKit

/// The next-prayer Live Activity: a Lock Screen banner plus the Dynamic Island in all three
/// presentations. The countdown uses `Text(timerInterval:)`, so it ticks on its own without
/// the app pushing updates. It cannot move on to the next prayer by itself: iOS renders the
/// view again only when the app updates the activity (`LiveActivityController`). The interval
/// is clamped so a just-passed prayer shows 0 rather than forming an invalid range.
///
/// Every text has one line and may shrink: the compact presentation is narrow, and on a Mac the
/// menu bar shows it even narrower ("35:…" instead of "35:12").
struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            lockScreen(context)
                .padding(14)
                .activityBackgroundTint(Color.accentColor.opacity(0.18))
                .activitySystemActionForegroundColor(Color.accentColor)
        } dynamicIsland: { context in
            let entry = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(entry.prayerName, systemImage: entry.symbolName)
                        .font(.headline).foregroundStyle(Color.accentColor)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(entry).font(.headline).frame(maxWidth: 96, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(place(context)) · \(entry.time)")
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            } compactLeading: {
                Image(systemName: entry.symbolName).foregroundStyle(Color.accentColor)
            } compactTrailing: {
                countdown(entry).frame(maxWidth: 64, alignment: .trailing)
            } minimal: {
                Image(systemName: entry.symbolName).foregroundStyle(Color.accentColor)
            }
        }
    }

    private typealias Entry = PrayerActivityAttributes.ContentState

    private func place(_ context: ActivityViewContext<PrayerActivityAttributes>) -> String {
        context.state.locationName ?? context.attributes.locationName
    }

    private func countdown(_ entry: Entry) -> some View {
        Text(timerInterval: min(Date.now, entry.endDate)...entry.endDate, countsDown: true)
            .monospacedDigit().multilineTextAlignment(.trailing)
            .lineLimit(1).minimumScaleFactor(0.5)
    }

    private func lockScreen(_ context: ActivityViewContext<PrayerActivityAttributes>) -> some View {
        let entry = context.state
        return HStack(spacing: 12) {
            Image(systemName: entry.symbolName)
                .font(.title2).foregroundStyle(Color.accentColor).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Next prayer").font(.caption2).foregroundStyle(.secondary)
                Text(entry.prayerName).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                Text("\(place(context)) · \(entry.time)")
                    .font(.caption2).foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            countdown(entry)
                .font(.system(.title2, design: .rounded))
                .foregroundStyle(Color.accentColor).frame(maxWidth: 124, alignment: .trailing)
        }
    }
}
