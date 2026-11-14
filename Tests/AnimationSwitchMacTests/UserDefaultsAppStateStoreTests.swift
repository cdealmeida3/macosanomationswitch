#if os(macOS)
import AnimationSwitchCore
import AnimationSwitchMac
import Foundation
import Testing

@Suite final class UserDefaultsAppStateStoreTests {
    let suite = "dev.animationswitch.tests.\(UUID().uuidString)"
    lazy var defaults = UserDefaults(suiteName: suite)!

    deinit {
        defaults.removePersistentDomain(forName: suite)
        let plist = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/\(suite).plist")
        try? FileManager.default.removeItem(at: plist)
    }

    @Test func firstLaunchHasNoSavedState() throws {
        #expect(try UserDefaultsAppStateStore(defaults: defaults).load() == nil)
    }

    @Test func savedStateLoadsBackInAFreshStore() throws {
        let state = AppState(
            animationsDisabled: true,
            managed: ["dock-launch-bounce", "mission-control"],
            originalValues: [
                "dock-minimize-effect": .value(.string("suck")),
                "dock-launch-bounce": .absent,
                "sheets-window-resize": .value(.double(0.2)),
            ])
        try UserDefaultsAppStateStore(defaults: defaults).save(state)
        #expect(try UserDefaultsAppStateStore(defaults: defaults).load() == state)
    }

    @Test func stateMentioningAnAnimationNoLongerInTheCatalogStillLoads() throws {
        let state = AppState(managed: ["retired-animation"], originalValues: ["retired-animation": .absent])
        try UserDefaultsAppStateStore(defaults: defaults).save(state)
        #expect(try UserDefaultsAppStateStore(defaults: defaults).load() == state)
    }

    @Test func unreadableStateThrowsInsteadOfStartingOver() throws {
        defaults.set(Data("not json".utf8), forKey: "AppState")
        #expect(throws: (any Error).self) { try UserDefaultsAppStateStore(defaults: self.defaults).load() }
    }
}
#endif
