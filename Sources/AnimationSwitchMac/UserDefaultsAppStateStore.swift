#if os(macOS)
import AnimationSwitchCore
import Foundation

/// Keeps the app's state as JSON in its own preferences domain.
public final class UserDefaultsAppStateStore: AppStateStore {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "AppState") {
        self.defaults = defaults
        self.key = key
    }

    public func load() throws -> AppState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(AppState.self, from: data)
    }

    public func save(_ state: AppState) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        defaults.set(try encoder.encode(state), forKey: key)
    }
}
#endif
