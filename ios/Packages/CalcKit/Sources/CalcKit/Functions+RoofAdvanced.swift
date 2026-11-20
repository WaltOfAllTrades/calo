import Foundation

/// Pitch in inches per 12 from any angle field, or from a number typed as inches per 12. Mirrors
/// `Roof.pitchInchesPer12`, which is hard-wired to the "pitch" field; the irregular hip has two.
func pitchInchesPer12(_ input: FunctionInput, field: String) -> Double? {
    guard let value = input[field] else { return nil }
    switch value {
    case let .dimension(d) where d.kind == .angle: return AngleFormat.pitch(fromDegrees: d.value.doubleValue)
    case let .dimension(d): return d.value.doubleValue
    case let .number(f): return f.doubleValue
    case let .int(i): return Double(i)
    case .toggle: return nil
    }
}

/// Irregular hip / valley (UG pp. 62–65, R11–R12): two roof planes of different pitch meet at one
/// ridge height, so the hip's plan is a rectangle R1 × R2, not a square, and the jacks on each side
/// step by a different increment.
///
/// Geometry (plain words): the main side runs R1 at pitch p1, so the ridge sits h = R1·p1/12 above
/// the plate. The irregular side must reach the same ridge, so its run is R2 = h·12/p2. The hip is
/// the space diagonal of the R1 × R2 × h box; its plumb cut is atan(h ÷ plan diagonal). The cheek
/// angles are the two plan angles of the hip, atan(R2/R1) and atan(R1/R2). A jack on the main side
/// sits at k × spacing along the irregular wall and meets the hip after a run of k × spacing × R1/R2
/// (similar triangles), so the main jacks shorten by spacing × R1/R2 × common factor; the irregular
/// jacks mirror that with the sides swapped. "Mate" (JAC-JAC) moves the main-side jacks to a
/// spacing of spacing × R2/R1 so each one meets an irregular jack at the hip.
public enum IrregularHip {
    public static let spec = FunctionSpec(
        id: "irregularHip",
        fields: [
            FunctionField("pitch", .angle),
            FunctionField("run", .length),
            FunctionField("irregularPitch", .angle),
            FunctionField("spacing", .length),
            FunctionField("jacksMate", .toggle, required: false),
        ],
        defaults: { prefs in
            FunctionInput(["spacing": .dimension(.inches(prefs.spacing)), "jacksMate": .toggle(false)])
        },
        solve: { input, prefs in solve(input, prefs) }
    )

    /// The box the hip spans: main run, irregular run and ridge height, all in inches.
    struct Box {
        var mainRun: Double
        var irregularRun: Double
        var rise: Double

        var mainFactor: Double {
            (mainRun * mainRun + rise * rise).squareRoot() / mainRun
        }

        var irregularFactor: Double {
            (irregularRun * irregularRun + rise * rise).squareRoot() / irregularRun
        }

        var common: Double {
            mainRun * mainFactor
        }

        var irregularCommon: Double {
            irregularRun * irregularFactor
        }

        var planDiagonal: Double {
            (mainRun * mainRun + irregularRun * irregularRun).squareRoot()
        }

        var hip: Double {
            (planDiagonal * planDiagonal + rise * rise).squareRoot()
        }
    }

    static func box(_ input: FunctionInput) -> Box? {
        // E-K19: a pitch of 90° or more (vertical) is refused; 1000 in/12 is 89.3°. A flat main pitch
        // has no ridge height for the irregular side to meet, so both pitches must be positive.
        guard let mainPitch = Roof.pitchInchesPer12(input),
              let irregularPitch = pitchInchesPer12(input, field: "irregularPitch"),
              mainPitch.isFinite, irregularPitch.isFinite,
              mainPitch > 0, irregularPitch > 0, mainPitch < 1000, irregularPitch < 1000,
              let run = input.length("run")?.doubleValue, run > 0
        else { return nil }
        let rise = run * mainPitch / 12
        return Box(mainRun: run, irregularRun: rise * 12 / irregularPitch, rise: rise)
    }

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        guard let box = box(input) else { return [] }
        let plumb = Trig.deg(atan(box.rise / box.planDiagonal))
        let mainPlumb = Trig.deg(atan(box.rise / box.mainRun))
        let irregularPlumb = Trig.deg(atan(box.rise / box.irregularRun))
        var results: [FunctionResult] = [
            FunctionResult("rise", inches: box.rise),
            FunctionResult("common", inches: box.common),
            FunctionResult("irregularRun", inches: box.irregularRun),
            FunctionResult("irregularCommon", inches: box.irregularCommon),
            FunctionResult("hip", inches: box.hip),
            FunctionResult("plumb", degrees: plumb),
            FunctionResult("level", degrees: 90 - plumb),
            FunctionResult("cheek1", degrees: Trig.deg(atan(box.irregularRun / box.mainRun))),
            FunctionResult("cheek2", degrees: Trig.deg(atan(box.mainRun / box.irregularRun))),
            FunctionResult("mainPlumb", degrees: mainPlumb),
            FunctionResult("mainLevel", degrees: 90 - mainPlumb),
            FunctionResult("irregularPlumb", degrees: irregularPlumb),
            FunctionResult("irregularLevel", degrees: 90 - irregularPlumb),
        ]
        let spacing = (input.length("spacing") ?? prefs.spacing).doubleValue
        guard spacing > 0 else { return results }
        let mate = input["jacksMate"]?.toggle ?? false
        // Irregular-side jacks: spaced along the main wall, each gains run spacing × R2/R1 (UG p. 63).
        let irregularIncrement = spacing * box.irregularRun / box.mainRun * box.irregularFactor
        results.append(FunctionResult("irregularJackIncrement", inches: irregularIncrement))
        results += jacks("irregularJack", from: box.irregularCommon, by: irregularIncrement)
        // Main-side jacks keep the o.c. spacing, or mate: spacing × R2/R1 so they meet the irregular jacks.
        let mainSpacing = mate ? spacing * box.irregularRun / box.mainRun : spacing
        let mainIncrement = mainSpacing * box.mainRun / box.irregularRun * box.mainFactor
        if mate {
            results.append(FunctionResult("jackSpacing", inches: mainSpacing))
        }
        results.append(FunctionResult("jackIncrement", inches: mainIncrement))
        results += jacks("jack", from: box.common, by: mainIncrement)
        return results
    }

    /// Jacks descending from the common, longest first; the UG lists none at zero for irregular roofs.
    static func jacks(_ prefix: String, from common: Double, by increment: Double) -> [FunctionResult] {
        var results: [FunctionResult] = []
        var remaining = common - increment
        var index = 1
        while remaining > 1e-9, index <= 40 {
            results.append(FunctionResult("\(prefix)\(index)", inches: remaining))
            remaining -= increment
            index += 1
        }
        return results
    }
}

/// Rake wall (UG pp. 66–67, R13–R14): stud heights under a sloped top plate, from the tall end down,
/// one per spacing, with an optional base (a flat wall under the rake) added to every stud.
///
/// Plain words: the plate drops rise ÷ run per inch of run, so the stud k spacings from the tall end
/// is rise − k × spacing × rise/run tall, plus the base. Studs stop before the short end: a stud at
/// the run itself would be the end post, which the UG does not list.
public enum RakeWall {
    public static let spec = FunctionSpec(
        id: "rakeWall",
        fields: [
            FunctionField("rise", .length),
            FunctionField("run", .length),
            FunctionField("spacing", .length),
            FunctionField("base", .length, required: false),
        ],
        defaults: { prefs in
            FunctionInput(["spacing": .dimension(.inches(prefs.spacing)), "base": .dimension(.inches(.zero))])
        },
        solve: { input, prefs in solve(input, prefs) }
    )

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        guard let rise = input.length("rise")?.doubleValue, let run = input.length("run")?.doubleValue,
              rise > 0, run > 0 else { return [] }
        let spacing = (input.length("spacing") ?? prefs.spacing).doubleValue
        let base = max(0, input.length("base")?.doubleValue ?? 0)
        guard spacing > 0 else { return [] }
        var results: [FunctionResult] = [
            FunctionResult("angle", degrees: Trig.deg(atan(rise / run))),
        ]
        let slope = rise / run
        var index = 1
        while Double(index) * spacing < run - 1e-9, index <= 200 {
            results.append(FunctionResult("stud\(index)", inches: rise - Double(index) * spacing * slope + base))
            index += 1
        }
        results.append(FunctionResult("base", inches: base))
        return results
    }
}
