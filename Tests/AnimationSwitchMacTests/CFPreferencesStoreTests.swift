#if os(macOS)
import AnimationSwitchCore
import AnimationSwitchMac
import Foundation
import Testing

/// Integration tests against the real preferences system. They only ever use a
/// throwaway domain, never Dock, Finder or NSGlobalDomain.
@Suite(.serialized) final class CFPreferencesStoreTests {
    let domain = "dev.animationswitch.tests.\(UUID().uuidString)"
    let store = CFPreferencesStore()

    deinit {
        _ = try? defaults(["delete", domain])
        let plist = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/\(domain).plist")
        try? FileManager.default.removeItem(at: plist)
    }

    private func key(_ name: String) -> PreferenceKey { PreferenceKey(.app(domain), name) }

    /// Runs /usr/bin/defaults, which talks to cfprefsd independently of the app.
    @discardableResult
    private func defaults(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Test func anAbsentKeyReadsAsNil() throws {
        #expect(try store.value(for: key("missing")) == nil)
    }

    @Test func valuesWrittenByTheStoreReadBackWithTheirType() throws {
        try store.setValue(.bool(false), for: key("flag"))
        try store.setValue(.double(0.001), for: key("duration"))
        try store.setValue(.int(3), for: key("count"))
        try store.setValue(.string("scale"), for: key("effect"))

        let fresh = CFPreferencesStore()
        #expect(try fresh.value(for: key("flag")) == .bool(false))
        #expect(try fresh.value(for: key("duration")) == .double(0.001))
        #expect(try fresh.value(for: key("count")) == .int(3))
        #expect(try fresh.value(for: key("effect")) == .string("scale"))
    }

    @Test func valuesWrittenByTheStoreAreVisibleToDefaults() throws {
        try store.setValue(.string("scale"), for: key("effect"))
        try store.setValue(.bool(true), for: key("flag"))
        #expect(try defaults(["read", domain, "effect"]) == "scale")
        #expect(try defaults(["read-type", domain, "flag"]) == "Type is boolean")
    }

    @Test func valuesWrittenByDefaultsReadBackWithTheirType() throws {
        try defaults(["write", domain, "flag", "-bool", "true"])
        try defaults(["write", domain, "count", "-int", "7"])
        try defaults(["write", domain, "duration", "-float", "0.5"])
        try defaults(["write", domain, "effect", "-string", "suck"])
        #expect(try store.value(for: key("flag")) == .bool(true))
        #expect(try store.value(for: key("count")) == .int(7))
        #expect(try store.value(for: key("duration")) == .double(0.5))
        #expect(try store.value(for: key("effect")) == .string("suck"))
    }

    @Test func removingAKeyMakesItAbsentAgain() throws {
        try store.setValue(.int(1), for: key("temporary"))
        try store.removeValue(for: key("temporary"))
        #expect(try store.value(for: key("temporary")) == nil)
        #expect(try defaults(["read", domain, "temporary"]).isEmpty)
    }

    @Test func aValueTheAppCannotRestoreIsRefused() throws {
        try defaults(["write", domain, "list", "-array", "a", "b"])
        #expect(throws: PreferencesError.self) { try self.store.value(for: self.key("list")) }
    }
}
#endif
