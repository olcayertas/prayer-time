import AppKit
import Combine

/// Enforces a single running instance and gives the menu bar status item fixed-width digits.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var statusButton: NSStatusBarButton?
    /// Re-applies the monospaced font whenever `menuTitle` changes; cancelled when the app exits.
    private var titleObserver: Task<Void, Never>?

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
        // Force fixed-width (tabular) digits on the MenuBarExtra status item so the countdown
        // doesn't shift as the digits change. MenuBarExtra rebuilds the button's attributed
        // title in the proportional system font on every per-second update, so re-apply the
        // monospaced font on every `menuTitle` change. `$menuTitle.values` yields the current
        // value first and then each update, all delivered here on the main actor.
        titleObserver = Task { [weak self] in
            for await _ in PrayerStore.shared.$menuTitle.values {
                self?.applyMonospacedDigits()
            }
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
            mutable.addAttribute(
              .font,
              value: font,
              range: NSRange(location: 0, length: mutable.length)
            )
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
