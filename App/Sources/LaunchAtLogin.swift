import Observation
import ServiceManagement

/// The "Launch at login" menu item, through SMAppService (plan Q9). It is on
/// by default. If macOS refuses, for example for an ad-hoc-signed build, the
/// item stays visible with an inline warning.
@MainActor @Observable
final class LaunchAtLogin {
    private(set) var isEnabled = false
    private(set) var warning: String?

    private static let configuredKey = "LaunchAtLoginConfigured"

    init() {
        refresh()
    }

    func enableOnFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: Self.configuredKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.configuredKey)
        set(true)
    }

    func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            warning = nil
        } catch {
            warning = "macOS refused: \(error.localizedDescription)"
        }
        refresh(keepingWarning: true)
    }

    func refresh(keepingWarning: Bool = false) {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled || status == .requiresApproval
        if status == .requiresApproval {
            warning = "Allow Animation Switch in System Settings → General → Login Items"
        } else if !keepingWarning {
            warning = nil
        }
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
