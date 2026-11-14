#if os(macOS)
import AnimationSwitchCore
import CoreFoundation
import Foundation

/// Reads and writes real settings through CFPreferences, for the current user
/// on any host, which is what `defaults read/write` use. CFPreferences goes
/// through cfprefsd, so running apps see the change, which a direct plist edit
/// would not guarantee.
public final class CFPreferencesStore: PreferencesStore {
    public init() {}

    public func value(for key: PreferenceKey) throws -> PreferenceValue? {
        let app = Self.applicationID(key.domain)
        guard
            let raw = CFPreferencesCopyValue(
                key.name as CFString, app, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        else { return nil }
        return try Self.decode(raw, key: key)
    }

    public func setValue(_ value: PreferenceValue, for key: PreferenceKey) throws {
        let app = Self.applicationID(key.domain)
        CFPreferencesSetValue(
            key.name as CFString, Self.encode(value), app, kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost)
        try Self.synchronize(app, key: key)
    }

    public func removeValue(for key: PreferenceKey) throws {
        let app = Self.applicationID(key.domain)
        CFPreferencesSetValue(
            key.name as CFString, nil, app, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        try Self.synchronize(app, key: key)
    }

    private static func applicationID(_ domain: PreferenceDomain) -> CFString {
        switch domain {
        case .global: kCFPreferencesAnyApplication
        case .app(let id): id as CFString
        }
    }

    private static func synchronize(_ app: CFString, key: PreferenceKey) throws {
        guard CFPreferencesSynchronize(app, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
            throw PreferencesError("macOS did not save \(key)")
        }
    }

    private static func encode(_ value: PreferenceValue) -> CFPropertyList {
        switch value {
        case .bool(let b): NSNumber(value: b)
        case .int(let i): NSNumber(value: i)
        case .double(let d): NSNumber(value: d)
        case .string(let s): s as NSString
        }
    }

    private static func decode(_ raw: CFPropertyList, key: PreferenceKey) throws -> PreferenceValue {
        let type = CFGetTypeID(raw)
        if type == CFBooleanGetTypeID() {
            return .bool(CFBooleanGetValue((raw as! CFBoolean)))
        }
        if type == CFNumberGetTypeID() {
            let number = raw as! NSNumber
            return CFNumberIsFloatType((raw as! CFNumber)) ? .double(number.doubleValue) : .int(number.intValue)
        }
        if type == CFStringGetTypeID() {
            return .string(raw as! String)
        }
        throw PreferencesError("\(key) holds a kind of value the app can't restore")
    }
}
#endif
