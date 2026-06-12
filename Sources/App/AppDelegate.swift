import AppKit
import Combine

/// Enforces a single running instance and gives the menu bar status item fixed-width digits.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var statusButton: NSStatusBarButton?
    private var titleObserver: AnyCancellable?

    /// Single-instance guard: if another copy is already running, the newly launched one
    /// activates the existing instance and exits before its menu bar item is created.
    func applicationWillFinishLaunching(_ notification: Notification) {
        let current = NSRunningApplication.current
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let existing = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID)
            .first { $0.processIdentifier != current.processIdentifier }

        if let existing {
            existing.activate()
            exit(0)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force fixed-width (tabular) digits on the MenuBarExtra status item so the
        // countdown doesn't shift as the digits change. MenuBarExtra rebuilds the button's
        // attributed title in the proportional system font on every per-second update, so
        // re-apply the monospaced font right after each title change (deferred so it runs
        // after SwiftUI has set the new title).
        DispatchQueue.main.async { [weak self] in self?.applyMonospacedDigits() }
        titleObserver = PrayerStore.shared.$menuTitle.sink { [weak self] _ in
            DispatchQueue.main.async { self?.applyMonospacedDigits() }
        }
    }

    private func applyMonospacedDigits() {
        if statusButton == nil { statusButton = Self.findStatusBarButton() }
        guard let button = statusButton else { return }

        let size = button.font?.pointSize ?? NSFont.systemFontSize
        let font = NSFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
        button.font = font

        let attributed = button.attributedTitle
        if attributed.length > 0 {
            let mutable = NSMutableAttributedString(attributedString: attributed)
            mutable.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutable.length))
            button.attributedTitle = mutable
        }
    }

    private static func findStatusBarButton() -> NSStatusBarButton? {
        for window in NSApp.windows {
            if let button = statusBarButton(in: window.contentView) { return button }
        }
        return nil
    }

    private static func statusBarButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view else { return nil }
        if let button = view as? NSStatusBarButton { return button }
        for subview in view.subviews {
            if let button = statusBarButton(in: subview) { return button }
        }
        return nil
    }
}
