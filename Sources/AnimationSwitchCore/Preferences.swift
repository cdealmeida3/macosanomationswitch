/// Where a setting lives. `.global` is NSGlobalDomain.
public enum PreferenceDomain: Hashable, Sendable, Codable, CustomStringConvertible {
    case global
    case app(String)

    public var description: String {
        switch self {
        case .global: "NSGlobalDomain"
        case .app(let id): id
        }
    }
}

/// One `defaults` key in one domain.
public struct PreferenceKey: Hashable, Sendable, CustomStringConvertible {
    public let domain: PreferenceDomain
    public let name: String

    public init(_ domain: PreferenceDomain, _ name: String) {
        self.domain = domain
        self.name = name
    }

    public var description: String { "\(domain) \(name)" }
}

/// A value a setting can hold. Anything else (data, arrays, dictionaries) is
/// refused by the stores, so the app never overwrites what it can't put back.
public enum PreferenceValue: Hashable, Sendable, Codable, CustomStringConvertible {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)

    /// Whether macOS would read both values the same way. `defaults write -int 0`,
    /// `-float 0` and `-bool false` all mean "off", so numbers and booleans
    /// compare by value.
    public func isEquivalent(to other: PreferenceValue) -> Bool {
        if let a = numericValue, let b = other.numericValue { return a == b }
        return self == other
    }

    private var numericValue: Double? {
        switch self {
        case .bool(let b): b ? 1 : 0
        case .int(let i): Double(i)
        case .double(let d): d
        case .string: nil
        }
    }

    public var description: String {
        switch self {
        case .bool(let b): String(b)
        case .int(let i): String(i)
        case .double(let d): String(d)
        case .string(let s): "\"\(s)\""
        }
    }
}

/// Why reading or writing a setting failed, in words the menu can show.
public struct PreferencesError: Error, Hashable, Sendable, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// Reads and writes the system's settings. The real one is
/// `CFPreferencesStore` in AnimationSwitchMac; tests use `InMemoryPreferencesStore`.
public protocol PreferencesStore {
    /// The key's current value, or nil when the key is absent.
    func value(for key: PreferenceKey) throws -> PreferenceValue?
    func setValue(_ value: PreferenceValue, for key: PreferenceKey) throws
    /// Deletes the key, so macOS falls back to its built-in behaviour.
    func removeValue(for key: PreferenceKey) throws
}

/// A preferences store held in memory, with switches to make keys fail.
public final class InMemoryPreferencesStore: PreferencesStore {
    public var values: [PreferenceKey: PreferenceValue]
    /// Keys whose reads throw.
    public var failingReads: Set<PreferenceKey> = []
    /// Keys whose writes and deletes throw.
    public var failingWrites: Set<PreferenceKey> = []
    /// Keys whose writes and deletes report success but change nothing, the way
    /// a setting looks when something else keeps putting it back.
    public var ignoredWrites: Set<PreferenceKey> = []

    public init(_ values: [PreferenceKey: PreferenceValue] = [:]) {
        self.values = values
    }

    public func value(for key: PreferenceKey) throws -> PreferenceValue? {
        if failingReads.contains(key) { throw PreferencesError("Could not read \(key)") }
        return values[key]
    }

    public func setValue(_ value: PreferenceValue, for key: PreferenceKey) throws {
        if failingWrites.contains(key) { throw PreferencesError("Could not write \(key)") }
        if ignoredWrites.contains(key) { return }
        values[key] = value
    }

    public func removeValue(for key: PreferenceKey) throws {
        if failingWrites.contains(key) { throw PreferencesError("Could not delete \(key)") }
        if ignoredWrites.contains(key) { return }
        values[key] = nil
    }
}
