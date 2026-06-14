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
    @Published private(set) var menuTitle: String = String(localized: "Prayer Times")
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
    /// Drives the once-a-second menu bar countdown; cancelled implicitly when the app exits.
    private var clockTask: Task<Void, Never>?
    /// The in-flight network refresh, kept so a new refresh (or location change) can cancel it.
    private var refreshTask: Task<Void, Never>?

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
        #if os(macOS)
        // 1 Hz menu-bar countdown. iOS has no menu bar — TodayView drives its own
        // countdown via TimelineView — so the clock would be pure wasted work there.
        startClock()
        #endif
    }

    var schedule: PrayerSchedule { PrayerSchedule(days: days) }

    var hasData: Bool { !days.isEmpty }

    /// Fetches the month and publishes it. The fetch + decode run off the main actor (the
    /// URLSession async API hops to the cooperative pool); the `@Published` mutations run
    /// back here on the main actor. A new call supersedes any in-flight fetch; on failure
    /// the cached data is kept.
    func refresh() {
        refreshTask?.cancel()
        isLoading = true
        let districtId = self.districtId
        refreshTask = Task { [provider, cache] in
            do {
                let days = try await provider.monthlyTimes(districtId: districtId)
                try Task.checkCancellation()
                cache.save(days, districtId: districtId)
                applyRefreshed(days)
            } catch is CancellationError {
                // Superseded by a newer refresh / location change — let that task own the state.
            } catch {
                lastError = error.localizedDescription
                isLoading = false
            }
        }
    }

    /// Applies a freshly fetched month on the main actor: publishes it, refreshes the menu
    /// title, reschedules notifications if enabled, and reloads the widget.
    private func applyRefreshed(_ days: [PrayerDay]) {
        self.days = days
        lastUpdated = Date()
        lastError = nil
        isLoading = false
        updateMenuTitle()
        if notificationsEnabled {
            scheduler.reschedule(schedule: schedule, locationName: locationName)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Ticks once a second to keep the menu bar countdown current. A `@MainActor` task loop:
    /// it inherits this actor's isolation, so `updateMenuTitle()` is a direct call (no GCD
    /// hop, no `assumeIsolated`), and `Task.sleep` is cancellation-aware.
    private func startClock() {
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.updateMenuTitle()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// Recomputes the menu bar title ("İkindi  1:23:45") from the current schedule.
    private func updateMenuTitle() {
        guard let upcoming = schedule.upcoming(now: Date()) else {
            menuTitle = String(localized: "Prayer Times")
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
        Task {
            guard await scheduler.requestAuthorization() else { return }
            scheduler.reschedule(schedule: schedule, locationName: locationName)
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
