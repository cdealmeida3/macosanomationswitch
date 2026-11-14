import AnimationSwitchCore
import Testing

@Suite struct EngineStartupTests {
    @Test func unreadableSavedStateStopsTheEngineFromStarting() {
        struct Broken: AppStateStore {
            func load() throws -> AppState? { throw PreferencesError("corrupt") }
            func save(_ state: AppState) throws {}
        }
        #expect(throws: PreferencesError("corrupt")) {
            try Engine(
                preferences: InMemoryPreferencesStore(), restarter: RecordingProcessRestarter(),
                stateStore: Broken())
        }
    }
}
