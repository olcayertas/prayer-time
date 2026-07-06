import Foundation
import Combine
import CoreLocation
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
    /// Automatic (track device location) vs pinned (manual picker). Persisted; default automatic.
    @Published private(set) var locationMode: LocationMode
    /// Transient state of the automatic pipeline, for the Settings UI. Not persisted.
    @Published private(set) var trackingStatus: LocationTrackingStatus = .idle

    static let notificationsKey = "notificationsEnabled"
    // Shared with the widget — single source of truth on AppGroup.
    static let selectedDistrictIdKey = AppGroup.selectedDistrictIdKey
    static let selectedDistrictNameKey = AppGroup.selectedDistrictNameKey
    static let locationModeKey = "locationMode"

    private let provider: PrayerTimesProvider
    private let cache: PrayerCache
    private let tracker: LocationTracker
    private let resolver: LocationResolver
    private let scheduler = NotificationScheduler()
    /// The in-flight automatic location → resolve → select pipeline, cancellable on mode change.
    private var locationTask: Task<Void, Never>?
    /// Drives the once-a-second menu bar countdown; cancelled implicitly when the app exits.
    private var clockTask: Task<Void, Never>?
    /// The in-flight network refresh, kept so a new refresh (or location change) can cancel it.
    private var refreshTask: Task<Void, Never>?

    init(
        provider: PrayerTimesProvider = EzanVaktiProvider(),
        cache: PrayerCache = PrayerCache(),
        tracker: LocationTracker = LocationTracker(),
        resolver: LocationResolver = LocationResolver()
    ) {
        Self.migrateSelectedDistrictToAppGroup()
        let defaults = UserDefaults.standard
        // The selected district lives in the App Group so the widget can read it; mode +
        // notifications are app-only and stay in `.standard`.
        let shared = AppGroup.defaults
        let savedId = shared.string(forKey: Self.selectedDistrictIdKey) ?? Config.defaultDistrictId
        let savedName = shared.string(forKey: Self.selectedDistrictNameKey) ?? Config.defaultLocationName
        // Automatic by default for new installs. Existing users with a saved district also default
        // automatic but fall back to that district if permission is denied (no data change).
        let savedMode = defaults.string(forKey: Self.locationModeKey)
            .flatMap(LocationMode.init(rawValue:)) ?? .automatic
        self.districtId = savedId
        self.locationName = savedName
        self.locationMode = savedMode
        self.provider = provider
        self.cache = cache
        self.tracker = tracker
        self.resolver = resolver
        self.days = cache.load(districtId: savedId) ?? []
        self.notificationsEnabled = defaults.bool(forKey: Self.notificationsKey)
        updateMenuTitle()
        // Show cached times immediately; only hit the network if the cached month is stale.
        refreshIfStale()
        if savedMode == .automatic {
            startAutomaticTracking()   // requests permission on first launch
        }
        #if os(macOS)
        // 1 Hz menu-bar countdown. iOS has no menu bar — TodayView drives its own
        // countdown via TimelineView — so the clock would be pure wasted work there.
        startClock()
        #endif
    }

    /// One-time migration for installs that predate the App Group: the selected district used to
    /// live in `.standard`, which the widget can't read. Copy it into the shared suite the first
    /// time the new build runs (no-op on fresh installs, or when the suite falls back to `.standard`).
    private static func migrateSelectedDistrictToAppGroup() {
        let shared = AppGroup.defaults
        let standard = UserDefaults.standard
        guard shared.string(forKey: selectedDistrictIdKey) == nil,
              let id = standard.string(forKey: selectedDistrictIdKey) else { return }
        shared.set(id, forKey: selectedDistrictIdKey)
        if let name = standard.string(forKey: selectedDistrictNameKey) {
            shared.set(name, forKey: selectedDistrictNameKey)
        }
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
        let shared = AppGroup.defaults   // shared with the widget
        shared.set(newId, forKey: Self.selectedDistrictIdKey)
        shared.set(newName, forKey: Self.selectedDistrictNameKey)
        days = cache.load(districtId: newId) ?? []
        updateMenuTitle()
        refresh()
    }

    // MARK: - Cache freshness

    /// True when the in-memory month already includes today's Istanbul date.
    var isCacheFresh: Bool { schedule.day(on: Date()) != nil }

    /// Fetches only when the cached month is missing or no longer covers today (e.g. month
    /// rollover), so a still-valid cache makes no network request.
    func refreshIfStale() {
        if isCacheFresh {
            applyCachedSideEffects()
        } else {
            refresh()
        }
    }

    /// Side effects for the "cache already covers today, no fetch" path: keep the menu title,
    /// notifications, and widget coherent without bumping `lastUpdated` (we didn't fetch).
    private func applyCachedSideEffects() {
        updateMenuTitle()
        if notificationsEnabled {
            scheduler.reschedule(schedule: schedule, locationName: locationName)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Location mode + automatic tracking

    /// Switches between automatic (track device location) and pinned (manual picker) modes.
    func setLocationMode(_ mode: LocationMode) {
        guard mode != locationMode else { return }
        locationMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.locationModeKey)
        switch mode {
        case .automatic:
            startAutomaticTracking()
        case .pinned:
            locationTask?.cancel()
            trackingStatus = .idle
            // Keep the current district; the picker overwrites it via selectLocation.
        }
    }

    /// Single entry point both platforms call on launch / foreground: re-check location in
    /// automatic mode, or just freshen the cache in pinned mode.
    func onForeground() {
        if locationMode == .automatic {
            startAutomaticTracking()
        } else {
            refreshIfStale()
        }
    }

    /// Runs the automatic pipeline: ensure permission → one-shot fix → resolve to a district →
    /// switch to it (reusing the per-district cache). Falls back to the saved district on any
    /// denial/failure/no-match. No-op in pinned mode.
    func startAutomaticTracking() {
        guard locationMode == .automatic else { return }
        locationTask?.cancel()
        locationTask = Task { [weak self] in
            guard let self else { return }
            var status = tracker.authorizationStatus
            if status == .notDetermined {
                trackingStatus = .locating
                status = await tracker.requestWhenInUseAuthorization()
            }
            if Task.isCancelled { return }
            // `.authorizedWhenInUse` is unavailable on macOS, so branch on the cross-platform helper
            // rather than a switch with that case label.
            if status.isAuthorizedForLocation {
                trackingStatus = .locating
                let coordinate = await tracker.requestCoordinate()
                if Task.isCancelled { return }
                guard let coordinate else {
                    trackingStatus = .unavailable
                    refreshIfStale()
                    return
                }
                await resolveAndApply(coordinate)
            } else if status == .denied || status == .restricted {
                trackingStatus = .permissionDenied
                refreshIfStale()
            } else {
                trackingStatus = .unavailable
                refreshIfStale()
            }
        }
    }

    private func resolveAndApply(_ coordinate: CLLocationCoordinate2D) async {
        trackingStatus = .resolving
        do {
            let match = try await resolver.resolve(coordinate: coordinate)
            if Task.isCancelled { return }
            if let match {
                trackingStatus = .resolved(match.name)
                applyAutomaticSelection(districtId: match.id, name: match.name)
            } else {
                trackingStatus = .unavailable
                refreshIfStale()
            }
        } catch {
            trackingStatus = .unavailable
            refreshIfStale()
        }
    }

    /// Applies an automatically-resolved district. On a real change, routes through
    /// `selectLocation` (persists + swaps cache + force-refresh) — which becomes the denial
    /// fallback next launch. On no change, only fetches if the cached month is stale, so
    /// re-resolving the same place makes no network request. Never flips `locationMode`.
    private func applyAutomaticSelection(districtId newId: String, name newName: String) {
        if newId == districtId {
            // Same Diyanet entry — refresh the displayed ilçe name if it changed (e.g. moving
            // between two central İstanbul ilçe that both map to "İSTANBUL"), then only fetch if stale.
            if newName != locationName {
                locationName = newName
                AppGroup.defaults.set(newName, forKey: Self.selectedDistrictNameKey)
                updateMenuTitle()
            }
            refreshIfStale()
        } else {
            selectLocation(districtId: newId, name: newName)
        }
    }
}
