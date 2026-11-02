import ActivityKit
import BackgroundTasks
import Foundation

/// Starts, refreshes, and ends the next-prayer Live Activity (iOS only). The countdown
/// ticks itself via `Text(timerInterval:)`, but the activity cannot move on to the next prayer
/// by itself: iOS renders it again only when the app updates it. So the app updates it on
/// launch, each time it becomes active, and in a background app refresh that it asks for at
/// the prayer time. iOS decides when that refresh runs, often some minutes later.
@MainActor
final class LiveActivityController: ObservableObject {
    static let shared = LiveActivityController()

    /// The `BGAppRefreshTask` identifier. Also listed in `BGTaskSchedulerPermittedIdentifiers`.
    static let refreshTaskIdentifier = "com.olcayertas.NamazVakti.iOS.liveActivityRefresh"

    @Published private(set) var isEnabled: Bool
    private static let key = "liveActivityEnabled"
    private let timeFormatter: DateFormatter

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.key)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
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

    /// Start the activity (or update the running one) for the current next prayer, and ask for a
    /// background refresh at that prayer's time. A no-op when disabled or unauthorized; safe to
    /// call on every launch / foreground / background refresh. Returns the task that updates a
    /// running activity, so a background refresh can wait for it before iOS suspends the app.
    @discardableResult
    func sync(schedule: PrayerSchedule, locationName: String) -> Task<Void, Never>? {
        guard isEnabled, ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        guard var upcoming = schedule.upcoming(now: Date()) else { endAll(); return nil }
        #if DEBUG
        // Simulator check of the rollover: the next prayer 45 s from now.
        if ProcessInfo.processInfo.arguments.contains("-liveActivityDemo") {
            upcoming = UpcomingPrayer(prayer: upcoming.prayer, date: Date().addingTimeInterval(45), remaining: 45)
        }
        #endif
        timeFormatter.timeZone = schedule.timeZone // the place's clock, also abroad
        let state = PrayerActivityAttributes.ContentState(
            prayerName: upcoming.prayer.displayName,
            symbolName: upcoming.prayer.symbolName,
            time: timeFormatter.string(from: upcoming.date),
            endDate: upcoming.date,
            locationName: locationName)
        let content = ActivityContent(state: state, staleDate: upcoming.date)
        // iOS ends an activity after some hours, but an ended or dismissed one can stay in
        // `activities`. Updating it shows nothing, so remove it and start a new one.
        let running = Activity<PrayerActivityAttributes>.activities.filter(\.isRunning)
        if running.count < Activity<PrayerActivityAttributes>.activities.count {
            Task {
                for activity in Activity<PrayerActivityAttributes>.activities where !activity.isRunning {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
        if running.isEmpty {
            do {
                _ = try Activity.request(
                    attributes: PrayerActivityAttributes(locationName: locationName),
                    content: content)
            } catch {
                // Starting can fail (system limit / disabled) — leave the toggle on, no activity.
                return nil
            }
            scheduleRefresh(at: upcoming.date)
            return nil
        }
        // Re-fetch inside the task so the (non-Sendable) Activity never crosses the
        // main-actor boundary — point each running activity at the new next prayer.
        let update = Task {
            for activity in Activity<PrayerActivityAttributes>.activities where activity.isRunning {
                await activity.update(content)
            }
        }
        scheduleRefresh(at: upcoming.date)
        return update
    }

    func endAll() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
        Task {
            for activity in Activity<PrayerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Ask iOS to wake the app just after `date`. A new request replaces the pending one, so there
    /// is at most one. iOS can run it later than asked, or skip it, for an app that is rarely used.
    private func scheduleRefresh(at date: Date) {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = date.addingTimeInterval(5)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Not available (for example Background App Refresh is off): the activity then
            // moves on the next time the app opens, as before.
        }
    }
}

private extension Activity {
    /// Shown on the Lock Screen and in the Dynamic Island (also when stale), so an update reaches the user.
    var isRunning: Bool { activityState == .active || activityState == .stale }
}
