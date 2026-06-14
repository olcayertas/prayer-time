import ActivityKit
import Foundation

/// Starts, refreshes, and ends the next-prayer Live Activity (iOS only). The countdown
/// ticks itself via `Text(timerInterval:)`, so "refresh" just means pointing the activity
/// at the current next prayer — done on launch and each time the app becomes active.
@MainActor
final class LiveActivityController: ObservableObject {
    static let shared = LiveActivityController()

    @Published private(set) var isEnabled: Bool
    private static let key = "liveActivityEnabled"
    private let timeFormatter: DateFormatter

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.key)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Config.timeZone
        formatter.dateFormat = "HH:mm"
        timeFormatter = formatter
    }

    /// Whether the user allows Live Activities for this app in iOS Settings.
    var isSupported: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func setEnabled(_ on: Bool, schedule: PrayerSchedule, locationName: String) {
        isEnabled = on
        UserDefaults.standard.set(on, forKey: Self.key)
        if on { sync(schedule: schedule, locationName: locationName) } else { endAll() }
    }

    /// Start the activity (or update the running one) for the current next prayer. A no-op
    /// when disabled or unauthorized; safe to call on every launch / foreground.
    func sync(schedule: PrayerSchedule, locationName: String) {
        guard isEnabled, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let upcoming = schedule.upcoming(now: Date()) else { endAll(); return }
        let state = PrayerActivityAttributes.ContentState(
            prayerName: upcoming.prayer.displayName,
            symbolName: upcoming.prayer.symbolName,
            time: timeFormatter.string(from: upcoming.date),
            endDate: upcoming.date)
        let content = ActivityContent(state: state, staleDate: upcoming.date)
        if Activity<PrayerActivityAttributes>.activities.isEmpty {
            do {
                _ = try Activity.request(
                    attributes: PrayerActivityAttributes(locationName: locationName),
                    content: content)
            } catch {
                // Starting can fail (system limit / disabled) — leave the toggle on, no activity.
            }
        } else {
            // Re-fetch inside the task so the (non-Sendable) Activity never crosses the
            // main-actor boundary — point each running activity at the new next prayer.
            Task {
                for activity in Activity<PrayerActivityAttributes>.activities {
                    await activity.update(content)
                }
            }
        }
    }

    func endAll() {
        Task {
            for activity in Activity<PrayerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
