#if os(macOS)
import AnimationSwitchCore
import Foundation

/// Restarts Dock or Finder with `killall`. launchd starts the Dock again at
/// once, and Finder relaunches itself.
public final class DockFinderRestarter: ProcessRestarter {
    public init() {}

    public func restart(_ target: RestartTarget) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = [target.processName]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        // killall exits 1 when no such process is running. Then there is
        // nothing to restart, and the process reads the new value when it starts.
        guard process.terminationStatus == 0 || process.terminationStatus == 1 else {
            throw PreferencesError("killall \(target.processName) exited with \(process.terminationStatus)")
        }
    }
}
#endif
