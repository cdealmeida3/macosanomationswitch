import AnimationSwitchCore
import Testing

@Suite struct AnimationToggleTests {
    @Test func whileAnimationsAreOnAToggleOnlyChangesTheManagedSet() throws {
        let h = try Harness()
        let report = h.engine.setAnimationToggle("smooth-scrolling", checked: true)
        _ = h.engine.setAnimationToggle("dock-launch-bounce", checked: false)

        #expect(h.preferences.values.isEmpty)
        #expect(h.restarter.restarts.isEmpty)
        #expect(report.outcomes.allSatisfy { $0.result == .unchanged })
        #expect(h.engine.isManaged("smooth-scrolling"))
        #expect(!h.engine.isManaged("dock-launch-bounce"))

        _ = h.engine.disableAnimations()
        #expect(h[Keys.smoothScrolling] == .bool(false))
        #expect(h[Keys.launchBounce] == nil)
    }

    @Test func toggleChangesAreRememberedAcrossLaunches() throws {
        let h = try Harness()
        _ = h.engine.setAnimationToggle("smooth-scrolling", checked: true)
        #expect(try h.relaunched().engine.isManaged("smooth-scrolling"))
    }

    @Test func checkingAToggleWhileAnimationsAreOffDisablesItNow() throws {
        let h = try Harness([Keys.smoothScrolling: .bool(true)])
        _ = h.engine.disableAnimations()
        let report = h.engine.setAnimationToggle("smooth-scrolling", checked: true)

        #expect(report["smooth-scrolling"]?.result == .applied)
        #expect(h[Keys.smoothScrolling] == .bool(false))

        _ = h.engine.restoreAnimations()
        #expect(h[Keys.smoothScrolling] == .bool(true))
    }

    @Test func uncheckingAToggleWhileAnimationsAreOffRestoresItNow() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck")])
        _ = h.engine.disableAnimations()
        let restartsBefore = h.restarter.restarts.count
        let report = h.engine.setAnimationToggle("dock-minimize-effect", checked: false)

        #expect(report["dock-minimize-effect"]?.result == .restored)
        #expect(h[Keys.minimizeEffect] == .string("suck"))
        #expect(h[Keys.launchBounce] == .bool(false))  // the others stay disabled
        #expect(Array(h.restarter.restarts.dropFirst(restartsBefore)) == [.dock])
        #expect(h.engine.animationsDisabled)
    }

    @Test func aToggleThatCannotBeSavedReportsAFailureAndStaysAsItWas() throws {
        let h = try Harness()
        h.stateStore.saveFailure = "disk full"
        let report = h.engine.setAnimationToggle("smooth-scrolling", checked: true)
        #expect(report["smooth-scrolling"]?.result == .failed("Could not save the change: disk full"))
        #expect(!h.engine.isManaged("smooth-scrolling"))
    }
}

@Suite struct DriftTests {
    @Test func launchReappliesManagedAnimationsThatDriftedBack() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck")])
        _ = h.engine.disableAnimations()
        // A macOS update puts two settings back while the app isn't running.
        h.preferences.values[Keys.minimizeEffect] = .string("genie")
        h.preferences.values[Keys.windowAnimations] = nil

        let later = try h.relaunched()
        let report = later.engine.reapplyDrift()
        #expect(report["dock-minimize-effect"]?.result == .applied)
        #expect(report["window-open-close"]?.result == .applied)
        #expect(report["dock-launch-bounce"]?.result == .unchanged)
        #expect(later[Keys.minimizeEffect] == .string("scale"))
        #expect(later[Keys.windowAnimations] == .bool(false))
        #expect(later.restarter.restarts == [.dock])

        // The Original Value from before the drift is still the one restored.
        _ = later.engine.restoreAnimations()
        #expect(later[Keys.minimizeEffect] == .string("suck"))
        #expect(later[Keys.windowAnimations] == nil)
    }

    @Test func launchWithNothingDriftedChangesAndRestartsNothing() throws {
        let h = try Harness()
        _ = h.engine.disableAnimations()
        let later = try h.relaunched()
        let report = later.engine.reapplyDrift()
        #expect(report.outcomes.allSatisfy { $0.result == .unchanged })
        #expect(later.restarter.restarts.isEmpty)
    }

    @Test func launchWhileAnimationsAreOnTouchesNothing() throws {
        let h = try Harness([Keys.launchBounce: .bool(true)])
        let report = h.engine.reapplyDrift()
        #expect(h.preferences.values == [Keys.launchBounce: .bool(true)])
        #expect(h.restarter.restarts.isEmpty)
        #expect(report.outcomes.allSatisfy { $0.result == .unchanged })
    }

    @Test func launchLeavesUncheckedAnimationsAlone() throws {
        let h = try Harness([Keys.smoothScrolling: .bool(true)])
        _ = h.engine.disableAnimations()
        _ = try h.relaunched().engine.reapplyDrift()
        #expect(h[Keys.smoothScrolling] == .bool(true))
    }
}

@Suite struct RestoreAllTests {
    @Test func restoreAllIgnoresTheManagedSet() throws {
        // Saved state from an earlier session: smooth scrolling was disabled
        // and is now unchecked, which a failed restore can leave behind.
        let state = AppState(
            animationsDisabled: true,
            managed: [],
            originalValues: ["smooth-scrolling": .value(.bool(true)), "dock-launch-bounce": .absent])
        let h = try Harness([Keys.smoothScrolling: .bool(false), Keys.launchBounce: .bool(false)], state: state)

        let report = h.engine.restoreAll()
        #expect(report["smooth-scrolling"]?.result == .restored)
        #expect(report["dock-launch-bounce"]?.result == .restored)
        #expect(h.preferences.values == [Keys.smoothScrolling: .bool(true)])
        #expect(!h.engine.animationsDisabled)
        #expect(h.restarter.restarts == [.dock])
    }

    @Test func restoreAllLeavesNoKeysBehind() throws {
        let h = try Harness()
        _ = h.engine.setAnimationToggle("smooth-scrolling", checked: true)
        _ = h.engine.disableAnimations()
        _ = h.engine.restoreAll()
        #expect(h.preferences.values.isEmpty)
        #expect(h.stateStore.saved?.originalValues.isEmpty == true)
    }
}
