import ActivityKit
import SwiftUI
import WidgetKit

/// The next-prayer Live Activity: a Lock Screen banner plus the Dynamic Island in all three
/// presentations. The countdown uses `Text(timerInterval:)`, so it ticks on its own without
/// the app pushing updates. The interval is clamped so a just-passed prayer shows 0 rather
/// than forming an invalid range.
struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            lockScreen(context)
                .padding(14)
                .activityBackgroundTint(Color.accentColor.opacity(0.18))
                .activitySystemActionForegroundColor(Color.accentColor)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.prayerName, systemImage: context.state.symbolName)
                        .font(.headline).foregroundStyle(Color.accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context).font(.headline).frame(maxWidth: 84)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.locationName) · \(context.state.time)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.symbolName).foregroundStyle(Color.accentColor)
            } compactTrailing: {
                countdown(context).frame(maxWidth: 48)
            } minimal: {
                Image(systemName: context.state.symbolName).foregroundStyle(Color.accentColor)
            }
        }
    }

    private func countdown(_ context: ActivityViewContext<PrayerActivityAttributes>) -> some View {
        Text(timerInterval: min(Date.now, context.state.endDate)...context.state.endDate, countsDown: true)
            .monospacedDigit().multilineTextAlignment(.trailing)
    }

    private func lockScreen(_ context: ActivityViewContext<PrayerActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: context.state.symbolName)
                .font(.title2).foregroundStyle(Color.accentColor).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Next prayer").font(.caption2).foregroundStyle(.secondary)
                Text(context.state.prayerName).font(.headline)
                Text("\(context.attributes.locationName) · \(context.state.time)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            countdown(context)
                .font(.system(.title2, design: .rounded))
                .foregroundStyle(Color.accentColor).frame(maxWidth: 116)
        }
    }
}
