import SwiftUI
import ServiceManagement

/// Wraps `SMAppService.mainApp` so the menu-bar app can register itself as a login item and start
/// automatically when the user logs in. This is the modern macOS 13+ API — sandbox-safe and with no
/// helper bundle — so it lives in the macOS shell and the shared `SettingsView` references the
/// toggle behind `#if os(macOS)` (mirroring the iOS-only `LiveActivityToggle`).
@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var status: SMAppService.Status = .notRegistered

    init() { refresh() }

    /// Whether the app is currently set to open at login.
    var isEnabled: Bool { status == .enabled }

    /// The user turned the item off under System Settings → Login Items; `register()` won't take
    /// effect until they re-enable it there, so we surface a hint instead of silently failing.
    var needsApproval: Bool { status == .requiresApproval }

    /// Re-read the system state — the user can flip this in System Settings while we're running.
    func refresh() { status = SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status != .notRegistered { try SMAppService.mainApp.unregister() }
            }
        } catch {
            // Leave `status` to reflect reality below: the toggle snaps back if the change didn't
            // take (e.g. the user must approve it in System Settings → Login Items).
        }
        refresh()
    }
}

/// The "Open at Login" control shown in the macOS Settings — menu-bar apps commonly offer this so
/// the countdown keeps running after a restart.
struct LoginItemToggle: View {
    @StateObject private var controller = LoginItemController()

    var body: some View {
        Toggle("Open at Login", isOn: Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        ))
        .onAppear { controller.refresh() }

        if controller.needsApproval {
            VStack(alignment: .leading, spacing: 6) {
                Text("Enable this in System Settings → Login Items to finish turning it on.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Open Login Items Settings") { SMAppService.openSystemSettingsLoginItems() }
            }
        } else {
            Text("Start automatically when you log in.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
