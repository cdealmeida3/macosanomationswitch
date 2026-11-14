/// What an animation's setting was the first time the app changed it.
public enum OriginalValue: Hashable, Sendable, Codable {
    /// The key wasn't set, so Restore deletes it.
    case absent
    case value(PreferenceValue)

    init(_ value: PreferenceValue?) {
        self = value.map(OriginalValue.value) ?? .absent
    }

    var preferenceValue: PreferenceValue? {
        switch self {
        case .absent: nil
        case .value(let v): v
        }
    }
}

/// Everything the app remembers between launches.
public struct AppState: Hashable, Sendable, Codable {
    /// True when the Master Switch says animations are off.
    public var animationsDisabled: Bool
    /// The Managed Animations: the ones whose Animation Toggle is checked.
    public var managed: Set<AnimationID>
    /// The Original Value of each animation the app currently has disabled.
    public var originalValues: [AnimationID: OriginalValue]

    public init(
        animationsDisabled: Bool = false,
        managed: Set<AnimationID>,
        originalValues: [AnimationID: OriginalValue] = [:]
    ) {
        self.animationsDisabled = animationsDisabled
        self.managed = managed
        self.originalValues = originalValues
    }

    /// The state on first launch: animations on, toggles as the catalog says.
    public static func initial(for catalog: [Animation]) -> AppState {
        AppState(managed: Set(catalog.filter(\.startsChecked).map(\.id)))
    }
}

/// Keeps the app's own state. The real one is backed by UserDefaults.
public protocol AppStateStore {
    /// The saved state, or nil on first launch.
    func load() throws -> AppState?
    func save(_ state: AppState) throws
}

/// An app-state store held in memory, for tests and previews.
public final class InMemoryAppStateStore: AppStateStore {
    public var saved: AppState?
    /// When set, `save` throws this message and keeps the old state.
    public var saveFailure: String?

    public init(_ saved: AppState? = nil) {
        self.saved = saved
    }

    public func load() throws -> AppState? { saved }

    public func save(_ state: AppState) throws {
        if let saveFailure { throw PreferencesError(saveFailure) }
        saved = state
    }
}

/// Restarts Dock or Finder so a changed setting takes effect.
public protocol ProcessRestarter {
    func restart(_ target: RestartTarget) throws
}

/// A restarter that only records what it was asked to restart.
public final class RecordingProcessRestarter: ProcessRestarter {
    public private(set) var restarts: [RestartTarget] = []
    /// Targets whose restart throws, with the message to throw.
    public var failures: [RestartTarget: String] = [:]

    public init() {}

    public func restart(_ target: RestartTarget) throws {
        if let message = failures[target] { throw PreferencesError(message) }
        restarts.append(target)
    }
}
