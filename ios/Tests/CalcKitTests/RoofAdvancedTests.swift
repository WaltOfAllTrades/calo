import CalcKit
import Foundation
import Testing

private let en = Locale(identifier: "en_US")

/// Solve a spec directly (these functions are tested before they join the registry).
private func solve(_ spec: FunctionSpec, _ values: [String: FieldValue],
                   prefs: CalcPreferences = .defaults) -> [String: FunctionResult] {
    var input = spec.defaults(prefs)
    for (k, v) in values {
        input[k] = v
    }
    return Dictionary(uniqueKeysWithValues: spec.solve(input, prefs).map { ($0.id, $0) })
}

private func fi(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .feetInches, precision: .sixteenth, locale: en).text }
}

private func deg(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .degrees, precision: .sixteenth, locale: en).text }
}

private func ft(_ f: Int, _ i: Int = 0, _ fr: Fraction = .zero) -> FieldValue {
    .dimension(.feet(f, i, fr))
}

private func inch(_ v: Fraction) -> FieldValue {
    .dimension(.inches(v))
}

private func degrees(_ v: Double) -> FieldValue {
    .dimension(.degrees(Fraction(approximating: v, denominator: 10000) ?? .zero))
}

struct IrregularHipTests {
    private let r11: [String: FieldValue] = [
        "pitch": .number(Fraction(7)), "run": ft(4), "irregularPitch": .number(Fraction(8)),
    ]

    @Test("R11: 7/12 main, run 4′, irregular 8/12 → common, hip and cuts (UG p. 62)")
    func hipAndCuts() {
        let r = solve(IrregularHip.spec, r11)
        #expect(fi(r["common"]) == "4′ 7-9/16″")
        #expect(fi(r["rise"]) == "2′ 4″")
        #expect(fi(r["irregularRun"]) == "3′ 6″")
        #expect(fi(r["irregularCommon"]) == "4′ 2-1/2″")
        #expect(fi(r["hip"]) == "5′ 9-11/16″")
        #expect(deg(r["plumb"]) == "23.7°")
        #expect(deg(r["level"]) == "66.3°")
        #expect(deg(r["cheek1"]) == "41.19°")
        #expect(deg(r["cheek2"]) == "48.81°")
        #expect(deg(r["mainPlumb"]) == "30.26°")
        #expect(deg(r["mainLevel"]) == "59.74°")
    }

    @Test("R11: irregular-side jacks at 16 o.c. with the irregular common's cuts (UG p. 63)")
    func irregularJacks() {
        let r = solve(IrregularHip.spec, r11)
        #expect(fi(r["irregularJackIncrement"]) == "1′ 4-13/16″")
        #expect(fi(r["irregularJack1"]) == "2′ 9-5/8″")
        #expect(fi(r["irregularJack2"]) == "1′ 4-13/16″")
        #expect(r["irregularJack3"] == nil)
        #expect(deg(r["irregularPlumb"]) == "33.69°")
        #expect(deg(r["irregularLevel"]) == "56.31°")
    }

    @Test("R11: regular-side jacks at 16 o.c. step by spacing × R1/R2 × common factor (UG p. 63)")
    func regularJacks() {
        let r = solve(IrregularHip.spec, r11)
        #expect(fi(r["jackIncrement"]) == "1′ 9-3/16″")
        #expect(fi(r["jack1"]) == "2′ 10-3/8″")
        #expect(fi(r["jack2"]) == "1′ 1-1/4″")
        #expect(r["jack3"] == nil)
        #expect(r["jackSpacing"] == nil)
        #expect(deg(r["cheek2"]) == "48.81°") // the UG's CHK1 under the regular jacks
    }

    @Test("R12: jacks mate (JAC-JAC) → regular side at 14″ o.c., 1′ 6-1/2″ steps (UG pp. 64–65)")
    func mate() {
        var values = r11
        values["jacksMate"] = .toggle(true)
        let r = solve(IrregularHip.spec, values)
        #expect(fi(r["jackSpacing"]) == "1′ 2″")
        #expect(fi(r["jackIncrement"]) == "1′ 6-1/2″")
        // The UG lists these ascending; descending they are the same lengths, longest first.
        #expect(fi(r["jack1"]) == "3′ 1-1/16″")
        #expect(fi(r["jack2"]) == "1′ 6-1/2″")
        #expect(r["jack3"] == nil)
        #expect(fi(r["irregularJack1"]) == "2′ 9-5/8″")
        #expect(fi(r["irregularJack2"]) == "1′ 4-13/16″")
    }

    @Test("pitches as degrees reproduce R11; zero, negative and vertical pitches give nothing")
    func guards() {
        let fromDegrees = solve(IrregularHip.spec, [
            "pitch": degrees(30.2564), "run": ft(4), "irregularPitch": degrees(33.6901),
        ])
        #expect(fi(fromDegrees["hip"]) == "5′ 9-11/16″")
        #expect(fi(fromDegrees["jack1"]) == "2′ 10-3/8″")
        func empty(_ overrides: [String: FieldValue?]) -> Bool {
            var values = r11
            for (k, v) in overrides {
                values[k] = v
            }
            return solve(IrregularHip.spec, values).isEmpty
        }
        #expect(empty(["pitch": .number(.zero)]))
        #expect(empty(["irregularPitch": .number(.zero)]))
        #expect(empty(["pitch": .number(Fraction(-7))]))
        #expect(empty(["pitch": degrees(90)]))
        #expect(empty(["irregularPitch": degrees(90)]))
        #expect(empty(["run": ft(0)]))
        #expect(empty(["run": nil]))
        var withoutSpacing = r11
        withoutSpacing["spacing"] = inch(.zero)
        let noSpacing = solve(IrregularHip.spec, withoutSpacing)
        #expect(fi(noSpacing["hip"]) == "5′ 9-11/16″")
        #expect(noSpacing["jackIncrement"] == nil)
    }
}

struct RakeWallTests {
    @Test("R13: rise 4′, run 8′, 16 o.c., no base (UG p. 66)")
    func r13() {
        let r = solve(RakeWall.spec, ["rise": ft(4), "run": ft(8)])
        #expect(fi(r["stud1"]) == "3′ 4″")
        #expect(fi(r["stud2"]) == "2′ 8″")
        #expect(fi(r["stud3"]) == "2′ 0″")
        #expect(fi(r["stud4"]) == "1′ 4″")
        #expect(fi(r["stud5"]) == "8″")
        #expect(r["stud6"] == nil)
        #expect(fi(r["base"]) == "0″")
        #expect(deg(r["angle"]) == "26.57°")
    }

    @Test("R14: the same wall on a 5′ base (UG p. 67)")
    func r14() {
        let r = solve(RakeWall.spec, ["rise": ft(4), "run": ft(8), "base": ft(5)])
        #expect(fi(r["stud1"]) == "8′ 4″")
        #expect(fi(r["stud2"]) == "7′ 8″")
        #expect(fi(r["stud3"]) == "7′ 0″")
        #expect(fi(r["stud4"]) == "6′ 4″")
        #expect(fi(r["stud5"]) == "5′ 8″")
        #expect(r["stud6"] == nil)
        #expect(fi(r["base"]) == "5′ 0″")
        #expect(deg(r["angle"]) == "26.57°")
    }

    @Test("spacing from preferences; a run that is not a whole number of spacings; guards")
    func spacingAndGuards() {
        var prefs = CalcPreferences.defaults
        prefs.spacing = Fraction(24)
        let wide = solve(RakeWall.spec, ["rise": ft(4), "run": ft(8)], prefs: prefs)
        #expect(fi(wide["stud1"]) == "3′ 0″")
        #expect(fi(wide["stud3"]) == "1′ 0″")
        #expect(wide["stud4"] == nil)
        let odd = solve(RakeWall.spec, ["rise": ft(3), "run": ft(5), "spacing": inch(Fraction(16))])
        #expect(fi(odd["stud1"]) == "2′ 2-3/8″") // 26.4 in
        #expect(fi(odd["stud2"]) == "1′ 4-13/16″") // 16.8 in
        #expect(fi(odd["stud3"]) == "7-3/16″") // 7.2 in
        #expect(odd["stud4"] == nil)
        #expect(solve(RakeWall.spec, ["rise": ft(0), "run": ft(8)]).isEmpty)
        #expect(solve(RakeWall.spec, ["rise": ft(4), "run": ft(0)]).isEmpty)
        #expect(solve(RakeWall.spec, ["rise": ft(4)]).isEmpty)
        #expect(solve(RakeWall.spec, ["rise": ft(4), "run": ft(8), "spacing": inch(.zero)]).isEmpty)
    }
}
