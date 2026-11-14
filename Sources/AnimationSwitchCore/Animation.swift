/// Stable name of an Animation, used in saved state. A plain string, so state
/// saved by an older build still loads after a catalog row is dropped.
public struct AnimationID: RawRepresentable, Hashable, Sendable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
    public var description: String { rawValue }
}

/// The menu sections, in menu order.
public enum AnimationGroup: String, Hashable, Sendable, CaseIterable {
    case windows, scrolling, finder, dock, missionControl

    public var title: String {
        switch self {
        case .windows: "Windows"
        case .scrolling: "Scrolling"
        case .finder: "Finder"
        case .dock: "Dock"
        case .missionControl: "Mission Control"
        }
    }
}

/// A process the app restarts so a changed setting takes effect.
public enum RestartTarget: String, Hashable, Sendable, CaseIterable, Codable {
    case dock, finder

    public var processName: String {
        switch self {
        case .dock: "Dock"
        case .finder: "Finder"
        }
    }
}

/// A one-line note shown under an Animation Toggle (plan Q16 and Q23).
public enum AnimationNote: Hashable, Sendable {
    case appliesToAppsOpenedFromNow
    case onlyWhenDockHidesAutomatically
    case keyboardAndHotCornersOnly
    case restartFailed(RestartTarget, reason: String)

    public var text: String {
        switch self {
        case .appliesToAppsOpenedFromNow: "Applies to apps you open from now on"
        case .onlyWhenDockHidesAutomatically: "Only applies when the Dock hides automatically"
        case .keyboardAndHotCornersOnly: "Only for keyboard and hot corners, not trackpad gestures"
        case .restartFailed(let target, let reason): "Could not restart \(target.processName): \(reason)"
        }
    }
}

/// A note that shows only while another setting doesn't have a given value.
public struct NoteCondition: Hashable, Sendable {
    public let key: PreferenceKey
    /// The value that makes the note unnecessary. An absent key never matches.
    public let value: PreferenceValue
    public let note: AnimationNote

    public init(unless key: PreferenceKey, is value: PreferenceValue, show note: AnimationNote) {
        self.key = key
        self.value = value
        self.note = note
    }
}

/// A built-in macOS animation the app can disable and restore.
public struct Animation: Identifiable, Hashable, Sendable {
    public let id: AnimationID
    public let group: AnimationGroup
    /// The menu label.
    public let label: String
    public let key: PreferenceKey
    /// What the app writes to disable the animation.
    public let disabledValue: PreferenceValue
    /// What must restart for a change to take effect, if anything.
    public let restart: RestartTarget?
    /// Whether the Animation Toggle starts checked on first launch.
    public let startsChecked: Bool
    /// Notes that always show under the toggle.
    public let notes: [AnimationNote]
    /// A note that shows only while some other setting is off.
    public let condition: NoteCondition?

    public init(
        id: AnimationID,
        group: AnimationGroup,
        label: String,
        key: PreferenceKey,
        disabledValue: PreferenceValue,
        restart: RestartTarget? = nil,
        startsChecked: Bool = true,
        notes: [AnimationNote] = [],
        condition: NoteCondition? = nil
    ) {
        self.id = id
        self.group = group
        self.label = label
        self.key = key
        self.disabledValue = disabledValue
        self.restart = restart
        self.startsChecked = startsChecked
        self.notes = notes
        self.condition = condition
    }
}
