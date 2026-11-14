import AnimationSwitchCore
import Testing

@Suite struct MasterSwitchTests {
    @Test func firstLaunchStartsWithAnimationsOnAndEveryToggleButSmoothScrollingChecked() throws {
        let h = try Harness()
        #expect(!h.engine.animationsDisabled)
        #expect(h.engine.isManaged("window-open-close"))
        #expect(h.engine.isManaged("mission-control"))
        #expect(!h.engine.isManaged("smooth-scrolling"))
    }

    @Test func flippingOffWritesTheDisabledValueOfEveryManagedAnimation() throws {
        let h = try Harness()
        let report = h.engine.disableAnimations()

        #expect(h.engine.animationsDisabled)
        #expect(h[Keys.windowAnimations] == .bool(false))
        #expect(h[Keys.windowResize] == .double(0.001))
        #expect(h[Keys.finderAnimations] == .bool(true))
        #expect(h[Keys.minimizeEffect] == .string("scale"))
        #expect(h[Keys.missionControl] == .double(0))
        #expect(report["window-open-close"]?.result == .applied)
        #expect(report["mission-control"]?.result == .applied)
    }

    @Test func uncheckedAnimationsAreNeverTouched() throws {
        let h = try Harness([Keys.smoothScrolling: .bool(true)])
        let off = h.engine.disableAnimations()
        #expect(h[Keys.smoothScrolling] == .bool(true))
        #expect(off["smooth-scrolling"]?.result == .unchanged)

        let on = h.engine.restoreAnimations()
        #expect(h[Keys.smoothScrolling] == .bool(true))
        #expect(on["smooth-scrolling"]?.result == .unchanged)
    }

    @Test func restoringDeletesKeysThatWereAbsent() throws {
        let h = try Harness()
        _ = h.engine.disableAnimations()
        let report = h.engine.restoreAnimations()

        #expect(!h.engine.animationsDisabled)
        #expect(h.preferences.values.isEmpty)
        #expect(report["dock-launch-bounce"]?.result == .restored)
    }

    @Test func restoringPutsBackACustomisedValueRatherThanTheDefault() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck"), Keys.autohideDelay: .double(0.5)])
        _ = h.engine.disableAnimations()
        #expect(h[Keys.minimizeEffect] == .string("scale"))

        _ = h.engine.restoreAnimations()
        #expect(h[Keys.minimizeEffect] == .string("suck"))
        #expect(h[Keys.autohideDelay] == .double(0.5))
    }

    @Test func aValueThatAlreadyMatchesIsLeftAloneAndRestoredUnchanged() throws {
        let h = try Harness([Keys.minimizeEffect: .string("scale")])
        let off = h.engine.disableAnimations()
        #expect(off["dock-minimize-effect"]?.result == .unchanged)

        let on = h.engine.restoreAnimations()
        #expect(on["dock-minimize-effect"]?.result == .unchanged)
        #expect(h[Keys.minimizeEffect] == .string("scale"))
    }

    @Test func theOriginalValueIsSavedOnlyTheFirstTime() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck")])
        _ = h.engine.disableAnimations()
        h.preferences.values[Keys.minimizeEffect] = .string("genie")  // something else changes it
        _ = h.engine.disableAnimations()
        _ = h.engine.restoreAnimations()
        #expect(h[Keys.minimizeEffect] == .string("suck"))
    }

    @Test func theNextFlipOffCapturesANewCustomisation() throws {
        let h = try Harness()
        _ = h.engine.disableAnimations()
        _ = h.engine.restoreAnimations()
        h.preferences.values[Keys.autohideDelay] = .double(0.2)  // the person customises it

        _ = h.engine.disableAnimations()
        #expect(h[Keys.autohideDelay] == .double(0))
        _ = h.engine.restoreAnimations()
        #expect(h[Keys.autohideDelay] == .double(0.2))
    }

    @Test func originalValuesSurviveAnAppRelaunch() throws {
        let h = try Harness([Keys.minimizeEffect: .string("suck")])
        _ = h.engine.disableAnimations()

        let later = try h.relaunched()
        #expect(later.engine.animationsDisabled)
        _ = later.engine.restoreAnimations()
        #expect(later[Keys.minimizeEffect] == .string("suck"))
        #expect(later[Keys.windowAnimations] == nil)
    }

    @Test func eachProcessRestartsOncePerFlip() throws {
        let h = try Harness()
        _ = h.engine.disableAnimations()
        #expect(h.restarter.restarts == [.dock, .finder])
        _ = h.engine.restoreAnimations()
        #expect(h.restarter.restarts == [.dock, .finder, .dock, .finder])
    }

    @Test func onlyProcessesWhoseSettingsChangedAreRestarted() throws {
        let finderAlreadyOff: [PreferenceKey: PreferenceValue] = [
            Keys.finderAnimations: .bool(true),
            PreferenceKey(.global, "NSBrowserColumnAnimationSpeedMultiplier"): .double(0),
            Keys.quickLook: .int(0),
        ]
        let h = try Harness(finderAlreadyOff)
        _ = h.engine.disableAnimations()
        #expect(h.restarter.restarts == [.dock])
    }

    @Test func flippingOnWithNothingDisabledChangesAndRestartsNothing() throws {
        let h = try Harness([Keys.launchBounce: .bool(true)])
        let report = h.engine.restoreAnimations()
        #expect(h.restarter.restarts.isEmpty)
        #expect(h.preferences.values == [Keys.launchBounce: .bool(true)])
        #expect(report.outcomes.allSatisfy { $0.result == .unchanged })
    }

    @Test func aReportCoversEveryCatalogAnimationInMenuOrder() throws {
        let h = try Harness()
        let report = h.engine.disableAnimations()
        #expect(report.outcomes.map(\.id) == Catalog.v1.map(\.id))
    }
}
