/// The Animations the app manages, in menu order. Each row is documented in
/// docs/PLAN.md and docs/research/animation-settings.md. Apple ships every one
/// of these keys absent.
public enum Catalog {
    public static let dockAutohide = PreferenceKey(.app("com.apple.dock"), "autohide")

    public static let v1: [Animation] = [
        // Windows
        Animation(
            id: "window-open-close", group: .windows, label: "Window open and close",
            key: PreferenceKey(.global, "NSAutomaticWindowAnimationsEnabled"),
            disabledValue: .bool(false),
            notes: [.appliesToAppsOpenedFromNow]),
        Animation(
            id: "sheets-window-resize", group: .windows, label: "Sheets and window resizing",
            key: PreferenceKey(.global, "NSWindowResizeTime"),
            disabledValue: .double(0.001),  // 0 is reportedly ignored
            notes: [.appliesToAppsOpenedFromNow]),
        Animation(
            id: "fullscreen-toolbar", group: .windows, label: "Full-screen toolbar slide",
            key: PreferenceKey(.global, "NSToolbarFullScreenAnimationDuration"),
            disabledValue: .double(0),
            notes: [.appliesToAppsOpenedFromNow]),
        Animation(
            id: "versions-browser", group: .windows, label: "Versions browser",
            key: PreferenceKey(.global, "NSDocumentRevisionsWindowTransformAnimation"),
            disabledValue: .bool(false),
            notes: [.appliesToAppsOpenedFromNow]),

        // Scrolling
        Animation(
            id: "smooth-scrolling", group: .scrolling, label: "Smooth scrolling",
            key: PreferenceKey(.global, "NSScrollAnimationEnabled"),
            disabledValue: .bool(false),
            startsChecked: false,
            notes: [.appliesToAppsOpenedFromNow]),

        // Finder
        Animation(
            id: "finder-column-scrolling", group: .finder, label: "Column view scrolling",
            key: PreferenceKey(.global, "NSBrowserColumnAnimationSpeedMultiplier"),
            disabledValue: .double(0), restart: .finder,
            notes: [.appliesToAppsOpenedFromNow]),
        Animation(
            id: "quick-look-zoom", group: .finder, label: "Quick Look zoom",
            key: PreferenceKey(.global, "QLPanelAnimationDuration"),
            disabledValue: .double(0), restart: .finder,
            notes: [.appliesToAppsOpenedFromNow]),
        Animation(
            id: "finder-animations", group: .finder, label: "Finder animations",
            key: PreferenceKey(.app("com.apple.finder"), "DisableAllAnimations"),
            disabledValue: .bool(true), restart: .finder),

        // Dock
        Animation(
            id: "dock-autohide-delay", group: .dock, label: "Auto-hide delay",
            key: PreferenceKey(.app("com.apple.dock"), "autohide-delay"),
            disabledValue: .double(0), restart: .dock,
            condition: NoteCondition(
                unless: dockAutohide, is: .bool(true), show: .onlyWhenDockHidesAutomatically)),
        Animation(
            id: "dock-autohide-slide", group: .dock, label: "Auto-hide slide",
            key: PreferenceKey(.app("com.apple.dock"), "autohide-time-modifier"),
            disabledValue: .double(0), restart: .dock,
            condition: NoteCondition(
                unless: dockAutohide, is: .bool(true), show: .onlyWhenDockHidesAutomatically)),
        Animation(
            id: "dock-launch-bounce", group: .dock, label: "Bounce when opening apps",
            key: PreferenceKey(.app("com.apple.dock"), "launchanim"),
            disabledValue: .bool(false), restart: .dock),
        Animation(
            id: "dock-minimize-effect", group: .dock, label: "Minimize effect (Scale instead of Genie)",
            key: PreferenceKey(.app("com.apple.dock"), "mineffect"),
            disabledValue: .string("scale"), restart: .dock),

        // Mission Control
        Animation(
            id: "mission-control", group: .missionControl, label: "Mission Control transition",
            key: PreferenceKey(.app("com.apple.dock"), "expose-animation-duration"),
            disabledValue: .double(0), restart: .dock,
            notes: [.keyboardAndHotCornersOnly]),
    ]
}
