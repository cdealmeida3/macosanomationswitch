import AnimationSwitchCore
import AnimationSwitchMac
import AppKit
import Observation

/// Connects the menu to the engine. It keeps what the last reports said and
/// turns menu actions into engine calls. All behaviour lives in the engine.
@MainActor @Observable
final class AppModel {
    let catalog = Catalog.v1
    private(set) var animationsDisabled = false
    private(set) var managed: Set<AnimationID> = []
    /// Inline notes per animation, from the latest report.
    private(set) var notes: [AnimationID: [AnimationNote]] = [:]
    /// Inline warnings per animation. A warning stays until that animation is
    /// changed again, so a failure isn't hidden by an unrelated toggle.
    private(set) var failures: [AnimationID: String] = [:]
    /// Problems that belong to no single animation, including a failed start.
    private(set) var warnings: [String] = []
    private(set) var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    let launchAtLogin = LaunchAtLogin()

    @ObservationIgnored private var engine: Engine?
    @ObservationIgnored private var reduceMotionObserver: NSObjectProtocol?

    init() {
        do {
            let engine = try Engine(
                preferences: CFPreferencesStore(),
                restarter: DockFinderRestarter(),
                stateStore: UserDefaultsAppStateStore())
            self.engine = engine
            show(engine.reapplyDrift(), replacingFailures: true)
        } catch {
            warnings = ["Animation Switch could not read its saved state, so it changes nothing: \(error)"]
        }

        reduceMotionObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            }
        }
        launchAtLogin.enableOnFirstLaunch()
    }

    var isWorking: Bool { engine != nil }

    func animations(in group: AnimationGroup) -> [AnimationSwitchCore.Animation] {
        catalog.filter { $0.group == group }
    }

    // MARK: - Menu actions

    /// The Master Switch. `true` means animations are on.
    func setAnimationsEnabled(_ enabled: Bool) {
        guard let engine else { return }
        show(enabled ? engine.restoreAnimations() : engine.disableAnimations(), replacingFailures: true)
    }

    func setToggle(_ id: AnimationID, checked: Bool) {
        guard let engine else { return }
        let report = engine.setAnimationToggle(id, checked: checked)
        show(report, replacingFailures: false)
        failures[id] = Self.failure(in: report[id])
    }

    /// Re-reads the notes, for example when the menu opens after the person
    /// turned Dock auto-hide on in System Settings.
    func refresh() {
        guard let engine else { return }
        show(engine.status(), replacingFailures: false)
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        launchAtLogin.refresh()
    }

    func restoreAllAndQuit() {
        if let engine { _ = engine.restoreAll() }
        NSApplication.shared.terminate(nil)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    /// Opens System Settings at Reduce Motion: Accessibility → Motion on
    /// macOS 27, Accessibility → Display on macOS 26.
    func openMotionSettings() {
        let section = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 ? "Motion" : "Display"
        let candidates = [
            "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?\(section)",
            "x-apple.systempreferences:com.apple.Accessibility-Settings.extension",
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) { return }
        }
    }

    // MARK: - Reports

    private func show(_ report: Report, replacingFailures: Bool) {
        if let engine {
            animationsDisabled = engine.animationsDisabled
            managed = Set(catalog.map(\.id).filter(engine.isManaged))
        }
        for outcome in report.outcomes {
            notes[outcome.id] = outcome.notes
            if replacingFailures { failures[outcome.id] = Self.failure(in: outcome) }
        }
        warnings = report.warnings
    }

    private static func failure(in outcome: AnimationOutcome?) -> String? {
        if case .failed(let reason) = outcome?.result { return reason }
        return nil
    }
}
