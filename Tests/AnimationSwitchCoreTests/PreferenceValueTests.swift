import AnimationSwitchCore
import Testing

@Suite struct PreferenceValueTests {
    @Test func numbersWrittenAsIntOrFloatMeanTheSame() {
        #expect(PreferenceValue.int(0).isEquivalent(to: .double(0)))
        #expect(PreferenceValue.double(0.5).isEquivalent(to: .double(0.5)))
        #expect(!PreferenceValue.int(1).isEquivalent(to: .double(0.001)))
    }

    @Test func booleansMatchZeroAndOne() {
        #expect(PreferenceValue.bool(false).isEquivalent(to: .int(0)))
        #expect(PreferenceValue.bool(true).isEquivalent(to: .int(1)))
        #expect(!PreferenceValue.bool(true).isEquivalent(to: .bool(false)))
    }

    @Test func stringsMatchOnlyTheSameString() {
        #expect(PreferenceValue.string("scale").isEquivalent(to: .string("scale")))
        #expect(!PreferenceValue.string("scale").isEquivalent(to: .string("genie")))
        #expect(!PreferenceValue.string("0").isEquivalent(to: .int(0)))
    }
}
