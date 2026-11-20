import DesignSystem
import SwiftUI
import Testing

/// DesignSystem is MainActor by default; so is this bundle (project.yml).
struct MotionTests {
    @Test("every motion entry has a Reduce Motion branch that removes or keeps the animation deliberately")
    func reduceMotionBranches() {
        let entries: [Motion.Entry] = [Motion.digitRoll, Motion.intentSwitch, Motion.errorFade, Motion.resultSettle]
        for entry in entries {
            #expect(entry.animation(reduceMotion: false) != nil)
            #expect(entry.animation(reduceMotion: true) == entry.reduced)
        }
        // The spec removes motion for these four under Reduce Motion (plain replace / instant).
        #expect(Motion.digitRoll.reduced == nil)
        #expect(Motion.intentSwitch.reduced == nil)
    }

    @Test("timing constants match the spec")
    func timings() {
        #expect(Motion.errorHold == .seconds(3))
        #expect(Motion.armTimeout == .seconds(4))
        #expect(Motion.clearedLinger == .milliseconds(1200))
    }
}

struct RollingNumberTests {
    @Test("formats with grouping and a real minus sign", arguments: [
        (0, "0"), (7, "7"), (1240, "1,240"), (-120, "\u{2212}120"), (-1_000_000, "\u{2212}1,000,000"),
    ])
    func text(value: Int, expected: String) {
        #expect(RollingNumber.text(for: value, locale: Locale(identifier: "en_US")) == expected)
    }
}

struct TwoTapStateTests {
    @Test("idle → armed → done; done stays done")
    func taps() {
        let armed = TwoTapState.idle.tapped()
        #expect(armed == .armed)
        let done = armed.tapped()
        #expect(done == .done)
        #expect(done.tapped() == .done)
    }

    @Test("only an armed button disarms on timeout")
    func timeout() {
        #expect(TwoTapState.armed.timedOut() == .idle)
        #expect(TwoTapState.idle.timedOut() == .idle)
        #expect(TwoTapState.done.timedOut() == .done)
    }
}

struct TokenTests {
    @Test("keys are at least the glove-friendly minimum and above the tap-target floor")
    func keySizes() {
        #expect(Tokens.size.keyMin >= Tokens.size.control)
        #expect(Tokens.size.control >= 44)
    }
}
