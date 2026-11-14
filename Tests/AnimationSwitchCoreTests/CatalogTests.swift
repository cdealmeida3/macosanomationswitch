import AnimationSwitchCore
import Testing

// Expected values are copied from the catalog table in docs/PLAN.md.
@Suite struct CatalogTests {
    private func animation(_ id: AnimationID) throws -> Animation {
        try #require(Catalog.v1.first { $0.id == id })
    }

    @Test func v1HasThirteenAnimationsWithUniqueIDsAndKeys() {
        #expect(Catalog.v1.count == 13)
        #expect(Set(Catalog.v1.map(\.id)).count == 13)
        #expect(Set(Catalog.v1.map(\.key)).count == 13)
    }

    @Test func everyToggleStartsCheckedExceptSmoothScrolling() {
        let unchecked = Catalog.v1.filter { !$0.startsChecked }.map(\.id)
        #expect(unchecked == ["smooth-scrolling"])
    }

    @Test func animationsAreListedGroupByGroupInMenuOrder() {
        let groupsInOrder = Catalog.v1.map(\.group).reduce(into: [AnimationGroup]()) {
            if $0.last != $1 { $0.append($1) }
        }
        #expect(groupsInOrder == [.windows, .scrolling, .finder, .dock, .missionControl])
    }

    @Test func dockRowsRestartTheDock() {
        let dockKeys = Catalog.v1.filter { $0.key.domain == .app("com.apple.dock") }
        #expect(dockKeys.count == 5)
        #expect(dockKeys.allSatisfy { $0.restart == .dock })
    }

    @Test func globalWindowRowsRestartNothingAndCarryTheNewAppsNote() throws {
        for id: AnimationID in [
            "window-open-close", "sheets-window-resize", "fullscreen-toolbar", "versions-browser",
            "smooth-scrolling",
        ] {
            let row = try animation(id)
            #expect(row.key.domain == .global)
            #expect(row.restart == nil)
            #expect(row.notes == [.appliesToAppsOpenedFromNow])
        }
    }

    @Test func finderRows() throws {
        let column = try animation("finder-column-scrolling")
        #expect(column.key == PreferenceKey(.global, "NSBrowserColumnAnimationSpeedMultiplier"))
        #expect(column.restart == .finder)
        #expect(column.notes == [.appliesToAppsOpenedFromNow])

        let finder = try animation("finder-animations")
        #expect(finder.key == PreferenceKey(.app("com.apple.finder"), "DisableAllAnimations"))
        #expect(finder.disabledValue == .bool(true))
        #expect(finder.restart == .finder)
        #expect(finder.notes.isEmpty)
    }

    @Test func minimizeEffectSwitchesToScale() throws {
        let row = try animation("dock-minimize-effect")
        #expect(row.key == PreferenceKey(.app("com.apple.dock"), "mineffect"))
        #expect(row.disabledValue == .string("scale"))
    }

    @Test func windowResizeUsesATinyDurationBecauseZeroIsIgnored() throws {
        #expect(try animation("sheets-window-resize").disabledValue == .double(0.001))
    }

    @Test func autoHideRowsExplainTheyNeedAutoHide() throws {
        for id: AnimationID in ["dock-autohide-delay", "dock-autohide-slide"] {
            let condition = try #require(try animation(id).condition)
            #expect(condition.key == PreferenceKey(.app("com.apple.dock"), "autohide"))
            #expect(condition.value == .bool(true))
            #expect(condition.note.text == "Only applies when the Dock hides automatically")
        }
    }

    @Test func missionControlNotesThatGesturesKeepTheirAnimation() throws {
        let row = try animation("mission-control")
        #expect(row.key == PreferenceKey(.app("com.apple.dock"), "expose-animation-duration"))
        #expect(row.notes == [.keyboardAndHotCornersOnly])
    }

    @Test func newAppsNoteMatchesThePlanWording() {
        #expect(AnimationNote.appliesToAppsOpenedFromNow.text == "Applies to apps you open from now on")
    }
}
