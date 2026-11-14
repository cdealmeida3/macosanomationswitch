import AnimationSwitchCore

/// Keys from the catalog table in docs/PLAN.md, spelled out independently.
enum Keys {
    static let windowAnimations = PreferenceKey(.global, "NSAutomaticWindowAnimationsEnabled")
    static let windowResize = PreferenceKey(.global, "NSWindowResizeTime")
    static let smoothScrolling = PreferenceKey(.global, "NSScrollAnimationEnabled")
    static let quickLook = PreferenceKey(.global, "QLPanelAnimationDuration")
    static let finderAnimations = PreferenceKey(.app("com.apple.finder"), "DisableAllAnimations")
    static let autohideDelay = PreferenceKey(.app("com.apple.dock"), "autohide-delay")
    static let launchBounce = PreferenceKey(.app("com.apple.dock"), "launchanim")
    static let minimizeEffect = PreferenceKey(.app("com.apple.dock"), "mineffect")
    static let missionControl = PreferenceKey(.app("com.apple.dock"), "expose-animation-duration")
    static let dockAutohide = PreferenceKey(.app("com.apple.dock"), "autohide")
}

/// An engine wired to fakes, plus handles on the fakes.
struct Harness {
    let preferences: InMemoryPreferencesStore
    let restarter = RecordingProcessRestarter()
    let stateStore: InMemoryAppStateStore
    let engine: Engine

    init(
        _ values: [PreferenceKey: PreferenceValue] = [:],
        state: AppState? = nil,
        preferences: InMemoryPreferencesStore? = nil,
        stateStore: InMemoryAppStateStore? = nil
    ) throws {
        self.preferences = preferences ?? InMemoryPreferencesStore(values)
        self.stateStore = stateStore ?? InMemoryAppStateStore(state)
        engine = try Engine(preferences: self.preferences, restarter: restarter, stateStore: self.stateStore)
    }

    /// A second launch of the app against the same system and saved state.
    func relaunched() throws -> Harness {
        try Harness(preferences: preferences, stateStore: stateStore)
    }

    subscript(key: PreferenceKey) -> PreferenceValue? { preferences.values[key] }
}
