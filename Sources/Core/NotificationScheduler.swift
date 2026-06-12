import Foundation
import UserNotifications

/// Schedules local notifications at upcoming prayer times. Local-only (no push), so it
/// needs runtime authorization but no special entitlement.
struct NotificationScheduler: Sendable {
    let timeZone: TimeZone

    init(timeZone: TimeZone = Config.timeZone) {
        self.timeZone = timeZone
    }

    private var center: UNUserNotificationCenter { .current() }

    /// Prompts for alert+sound permission; returns whether it was granted.
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Replaces all pending requests with the prayer times in the next `daysAhead` days.
    /// Capped well under the system's ~64 pending-request limit.
    func reschedule(schedule: PrayerSchedule, locationName: String, daysAhead: Int = 3, now: Date = Date()) {
        center.removeAllPendingNotificationRequests()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let cutoff = calendar.date(byAdding: .day, value: daysAhead, to: now) else { return }

        let upcoming = schedule.sortedTimes().filter { $0.date > now && $0.date <= cutoff }
        for (prayer, date) in upcoming {
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            components.timeZone = timeZone

            let content = UNMutableNotificationContent()
            content.title = String(localized: "\(prayer.displayName) time", comment: "Notification title, e.g. 'Noon time'")
            content.body = String(localized: "It's \(prayer.displayName) time in \(locationName).",
                                  comment: "Notification body; args: 1 prayer name, 2 location")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "namazvakti.\(prayer.rawValue).\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
