import Foundation
import Combine
import WidgetKit

/// Owns the prayer-times data for the menu bar app: loads cache immediately, refreshes
/// from the network, and exposes the current schedule + the menu bar title string.
/// UI-facing, so `@MainActor`.
@MainActor
final class PrayerStore: ObservableObject {
    /// Shared instance so the app delegate (which styles the status item) and the SwiftUI
    /// scenes observe the same store.
    static let shared = PrayerStore()

    @Published private(set) var days: [PrayerDay] = []
    @Published private(set) var menuTitle: String = "Namaz Vakti"
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var notificationsEnabled: Bool = false
    @Published private(set) var districtId: String
    @Published private(set) var locationName: String

    static let notificationsKey = "notificationsEnabled"
    static let selectedDistrictIdKey = "selectedDistrictId"
    static let selectedDistrictNameKey = "selectedDistrictName"

    private let provider: PrayerTimesProvider
    private let cache: PrayerCache
    private let scheduler = NotificationScheduler()
    private var clockTimer: Timer?

    init(
        provider: PrayerTimesProvider = EzanVaktiProvider(),
        cache: PrayerCache = PrayerCache()
    ) {
        let defaults = UserDefaults.standard
        let savedId = defaults.string(forKey: Self.selectedDistrictIdKey) ?? Config.defaultDistrictId
        let savedName = defaults.string(forKey: Self.selectedDistrictNameKey) ?? Config.defaultLocationName
        self.districtId = savedId
        self.locationName = savedName
        self.provider = provider
        self.cache = cache
        self.days = cache.load(districtId: savedId) ?? []
        self.notificationsEnabled = defaults.bool(forKey: Self.notificationsKey)
        updateMenuTitle()
        refresh()
        startClock()
    }

    var schedule: PrayerSchedule { PrayerSchedule(days: days) }

    var hasData: Bool { !days.isEmpty }

    /// Fetches the month and publishes it. Synchronous trigger: the request runs on
    /// URLSession's background queue; the `@Published` updates are posted back via GCD.
    /// On failure, cached data is kept.
    func refresh() {
        isLoading = true
        let districtId = self.districtId
        let cache = self.cache
        provider.monthlyTimes(districtId: districtId) { [weak self] result in
            switch result {
            case .success(let days):
                cache.save(days, districtId: districtId)
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard let self else { return }
                        self.days = days
                        self.lastUpdated = Date()
                        self.lastError = nil
                        self.isLoading = false
                        self.updateMenuTitle()
                        if self.notificationsEnabled {
                            self.scheduler.reschedule(schedule: self.schedule, locationName: self.locationName)
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            case .failure(let error):
                let message = error.localizedDescription
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard let self else { return }
                        self.lastError = message
                        self.isLoading = false
                    }
                }
            }
        }
    }

    /// Ticks once a second to keep the menu bar countdown current.
    private func startClock() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateMenuTitle() }
        }
        RunLoop.main.add(timer, forMode: .common)
        clockTimer = timer
    }

    /// Recomputes the menu bar title ("İkindi  1:23:45") from the current schedule.
    private func updateMenuTitle() {
        guard let upcoming = schedule.upcoming(now: Date()) else {
            menuTitle = "Namaz Vakti"
            return
        }
        let total = max(0, Int(upcoming.remaining))
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        let countdown = hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
        menuTitle = "\(upcoming.prayer.displayName)  \(countdown)"
    }

    /// Enables/disables prayer-time notifications, persists the choice, and (re)schedules
    /// or clears pending notifications. Prompts for permission when first enabled.
    func setNotifications(enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.notificationsKey)
        guard enabled else {
            scheduler.cancelAll()
            return
        }
        scheduler.requestAuthorization { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.scheduler.reschedule(schedule: self.schedule, locationName: self.locationName)
                }
            }
        }
    }

    /// Switches to a new district: persists it, shows its cached times (or empty) while a
    /// fresh fetch runs, then the refresh reschedules notifications and reloads the widget.
    func selectLocation(districtId newId: String, name newName: String) {
        guard newId != districtId else { return }
        districtId = newId
        locationName = newName
        let defaults = UserDefaults.standard
        defaults.set(newId, forKey: Self.selectedDistrictIdKey)
        defaults.set(newName, forKey: Self.selectedDistrictNameKey)
        days = cache.load(districtId: newId) ?? []
        updateMenuTitle()
        refresh()
    }
}
