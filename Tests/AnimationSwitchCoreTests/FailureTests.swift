import AnimationSwitchCore
import Testing

@Suite struct FailureTests {
    @Test func oneFailedWriteDoesNotStopTheRest() throws {
        let h = try Harness()
        h.preferences.failingWrites = [Keys.minimizeEffect]
        let report = h.engine.disableAnimations()

        guard case .failed = report["dock-minimize-effect"]?.result else {
            Issue.record("expected a failure, got \(String(describing: report["dock-minimize-effect"]))")
            return
        }
        #expect(h[Keys.minimizeEffect] == nil)
        #expect(h[Keys.launchBounce] == .bool(false))
        #expect(report["dock-launch-bounce"]?.result == .applied)
        #expect(h.restarter.restarts == [.dock, .finder])
    }

    @Test func aWriteMacOSDoesNotKeepIsReportedAsFailed() throws {
        let h = try Harness()
        h.preferences.ignoredWrites = [Keys.missionControl]
        let report = h.engine.disableAnimations()
        #expect(report["mission-control"]?.result == .failed("macOS did not keep the change"))
    }

    @Test func anAnimationWhoseSettingCannotBeReadIsNotChanged() throws {
        let h = try Harness([Keys.launchBounce: .bool(true)])
        h.preferences.failingReads = [Keys.launchBounce]
        let report = h.engine.disableAnimations()

        #expect(report["dock-launch-bounce"]?.result == .failed("Could not read \(Keys.launchBounce)"))
        #expect(h[Keys.launchBounce] == .bool(true))
    }

    @Test func nothingIsWrittenIfTheOriginalValuesCannotBeSaved() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck")])
        h.stateStore.saveFailure = "disk full"
        let report = h.engine.disableAnimations()

        #expect(h.preferences.values == [Keys.minimizeEffect: .string("suck")])
        #expect(!h.engine.animationsDisabled)
        #expect(h.restarter.restarts.isEmpty)
        #expect(report["dock-minimize-effect"]?.result == .failed("Could not save the original settings: disk full"))
    }

    @Test func aFailedRestoreKeepsTheOriginalValueForNextTime() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck")])
        _ = h.engine.disableAnimations()
        h.preferences.failingWrites = [Keys.minimizeEffect]
        let failed = h.engine.restoreAnimations()
        guard case .failed = failed["dock-minimize-effect"]?.result else {
            Issue.record("expected a failure")
            return
        }
        #expect(h[Keys.windowAnimations] == nil)  // the rest were restored

        h.preferences.failingWrites = []
        _ = h.engine.restoreAnimations()
        #expect(h[Keys.minimizeEffect] == .string("suck"))
    }

    @Test func aFailedRestartIsNotedOnTheAnimationsThatNeededIt() throws {
        let h = try Harness()
        h.restarter.failures = [.dock: "not allowed"]
        let report = h.engine.disableAnimations()

        #expect(report["dock-launch-bounce"]?.notes == [.restartFailed(.dock, reason: "not allowed")])
        #expect(report["finder-animations"]?.notes == [])
        #expect(h.restarter.restarts == [.finder])
    }

    @Test func autoHideRowsCarryANoteOnlyWhileTheDockDoesNotHide() throws {
        let h = try Harness()
        #expect(h.engine.status()["dock-autohide-delay"]?.notes == [.onlyWhenDockHidesAutomatically])
        #expect(h.engine.status()["dock-launch-bounce"]?.notes == [])

        h.preferences.values[Keys.dockAutohide] = .bool(true)
        #expect(h.engine.status()["dock-autohide-slide"]?.notes == [])
    }

    @Test func theAppNeverTurnsOnDockAutoHide() throws {
        let h = try Harness()
        _ = h.engine.disableAnimations()
        _ = h.engine.restoreAnimations()
        #expect(h[Keys.dockAutohide] == nil)
    }
}
