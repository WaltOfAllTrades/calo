import Foundation

/// Stairs (formulas.md §3.1; UG pp. 15–16, 71–76). Riser count from the desired riser, rounded; the
/// displayed riser and tread (rounded to the precision) feed the stringer, opening and incline, as
/// the Construction Master does (S3, S4). Code limits warn and never block (SPEC choice 5).
public enum Stairs {
    public static let spec = FunctionSpec(
        id: "stairs",
        fields: [
            FunctionField("rise", .length, required: false),
            FunctionField("run", .length, required: false),
            FunctionField("riser", .length),
            FunctionField("tread", .length),
            FunctionField("headroom", .length),
            FunctionField("floorThickness", .length),
            FunctionField("riserLimited", .toggle, required: false),
        ],
        defaults: { prefs in
            FunctionInput([
                "riser": .dimension(.inches(prefs.desiredRiser)),
                "tread": .dimension(.inches(prefs.desiredTread)),
                "headroom": .dimension(.inches(prefs.headroom)),
                "floorThickness": .dimension(.inches(prefs.floorThickness)),
                "riserLimited": .toggle(prefs.riserLimited),
            ])
        },
        solve: { input, prefs in solve(input, prefs) }
    )

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        let desiredRiser = input.length("riser") ?? prefs.desiredRiser
        let desiredTread = input.length("tread") ?? prefs.desiredTread
        let headroom = input.length("headroom") ?? prefs.headroom
        let floor = input.length("floorThickness") ?? prefs.floorThickness
        let riserLimited = input["riserLimited"]?.toggle ?? prefs.riserLimited
        let precision = prefs.precision
        let rise = input.length("rise")
        let run = input.length("run")
        guard rise != nil || run != nil else { return [] } // E-K17
        // Zero or negative sizes have no stair; a riser-limited loop on a negative riser would never end.
        guard desiredRiser > .zero, desiredTread > .zero, (rise ?? .one) >= .zero, (run ?? .one) >= .zero,
              rise.map({ $0 > .zero }) ?? true || run.map({ $0 > .zero }) ?? false else { return [] }

        let layout = layout(Inputs(
            rise: rise, run: run, desiredRiser: desiredRiser, desiredTread: desiredTread,
            riserLimited: riserLimited, riserLimit: prefs.riserLimit
        ))
        let (risers, treads, totalRise, totalRun, treadDepth) = (
            layout.risers, layout.treads, layout.totalRise, layout.totalRun, layout.treadDepth
        )
        let riser = totalRise / Double(risers)
        let riserShown = Trig.snapped(riser, precision)
        let treadShown = Trig.snapped(treadDepth, precision)
        let stringer = (pow(Double(treads) * treadShown, 2) + pow(Double(treads) * riserShown, 2)).squareRoot()
        // A riser that rounds to nothing has no opening or incline to speak of.
        let opening = riserShown > 0 ? (headroom.doubleValue + floor.doubleValue) * treadShown / riserShown : 0
        let incline = treadShown > 0 ? Trig.deg(atan(riserShown / treadShown)) : (riserShown > 0 ? 90 : 0)
        let riserOverage = Double(risers) * riserShown - totalRise
        let treadOverage = Double(treads) * treadShown - totalRun

        let riserWarning: FunctionResult.Warning? = riserShown > CodeLimits.maxRiser
            .doubleValue + 1e-9 ? .riserOverLimit : nil
        let treadWarning: FunctionResult.Warning? = treadShown < CodeLimits.minTread
            .doubleValue - 1e-9 ? .treadUnderMinimum : nil
        let headroomWarning: FunctionResult.Warning? = headroom < CodeLimits.minHeadroom ? .headroomUnderMinimum : nil

        return [
            FunctionResult("risers", count: Double(risers)),
            FunctionResult("riserHeight", inches: riser, warning: riserWarning, inInches: true),
            FunctionResult("riserOverage", inches: riserOverage, inInches: true),
            FunctionResult("treads", count: Double(treads)),
            FunctionResult("treadDepth", inches: treadDepth, warning: treadWarning, inInches: true),
            FunctionResult("treadOverage", inches: treadOverage, inInches: true),
            FunctionResult("totalRun", inches: totalRun),
            FunctionResult("totalRise", inches: totalRise),
            FunctionResult("stringer", inches: stringer),
            FunctionResult("opening", inches: opening, warning: headroomWarning),
            FunctionResult("incline", degrees: incline),
        ]
    }

    struct Layout {
        var risers: Int
        var treads: Int
        var totalRise: Double
        var totalRun: Double
        var treadDepth: Double
    }

    /// Riser and tread counts (UG p. 15): risers = rise ÷ desired riser, rounded; treads = risers − 1.
    /// Riser limited treats the desired riser as a ceiling (UG p. 16). Run-only mode (S2) works backwards.
    struct Inputs {
        var rise: Fraction?
        var run: Fraction?
        var desiredRiser: Fraction
        var desiredTread: Fraction
        var riserLimited: Bool
        var riserLimit: Fraction
    }

    static func layout(_ input: Inputs) -> Layout {
        let (rise, run) = (input.rise, input.run)
        let (desiredRiser, desiredTread) = (input.desiredRiser, input.desiredTread)
        let (riserLimited, riserLimit) = (input.riserLimited, input.riserLimit)
        if let rise {
            let totalRise = rise.doubleValue
            var risers = max(1, Int((totalRise / desiredRiser.doubleValue).rounded()))
            if riserLimited {
                // The ceiling is the stricter of the desired riser and the limit setting (S4: 7½ desired).
                let ceiling = min(desiredRiser, riserLimit).doubleValue
                while totalRise / Double(risers) > ceiling + 1e-9, risers < 10000 {
                    risers += 1
                }
            }
            let treads = max(0, risers - 1) // one riser (a single step up) has no tread
            if let run {
                return Layout(
                    risers: risers, treads: treads, totalRise: totalRise, totalRun: run.doubleValue,
                    treadDepth: treads > 0 ? run.doubleValue / Double(treads) : 0
                )
            }
            return Layout(
                risers: risers, treads: treads, totalRise: totalRise,
                totalRun: Double(treads) * desiredTread.doubleValue, treadDepth: desiredTread.doubleValue
            )
        }
        let totalRun = run?.doubleValue ?? 0
        let treads = max(1, Int((totalRun / desiredTread.doubleValue).rounded()))
        return Layout(
            risers: treads + 1, treads: treads, totalRise: Double(treads + 1) * desiredRiser.doubleValue,
            totalRun: totalRun, treadDepth: totalRun / Double(treads)
        )
    }
}

/// Roof (formulas.md §3.2; UG pp. 10–13, 57–69): common, hip/valley, cuts, jacks, roof area.
public enum Roof {
    public static let spec = FunctionSpec(
        id: "roof",
        fields: [
            FunctionField("pitch", .angle),
            FunctionField("run", .length, required: false),
            FunctionField("span", .length, required: false),
            FunctionField("spacing", .length),
            FunctionField("planLength", .length, required: false),
            FunctionField("planWidth", .length, required: false),
        ],
        defaults: { prefs in FunctionInput(["spacing": .dimension(.inches(prefs.spacing))]) },
        solve: { input, prefs in solve(input, prefs) }
    )

    /// Pitch in inches per 12 from an angle field, or from a number typed as inches per 12.
    static func pitchInchesPer12(_ input: FunctionInput) -> Double? {
        guard let value = input["pitch"] else { return nil }
        switch value {
        case let .dimension(d) where d.kind == .angle: return AngleFormat.pitch(fromDegrees: d.value.doubleValue)
        case let .dimension(d): return d.value.doubleValue
        case let .number(f): return f.doubleValue
        case let .int(i): return Double(i)
        case .toggle: return nil
        }
    }

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        // E-K19: a pitch of 90° or more (vertical) is refused; 1000 in/12 is 89.3°.
        guard let pitch = pitchInchesPer12(input), pitch.isFinite, abs(pitch) < 1000 else { return [] }
        let slope = pitch / 12
        let commonFactor = (1 + slope * slope).squareRoot()
        let hipFactor = (2 + slope * slope).squareRoot()
        let plumb = Trig.deg(atan(slope))
        let hipPlumb = Trig.deg(atan(pitch / (12 * 2.0.squareRoot())))
        var results: [FunctionResult] = [
            FunctionResult("pitchDegrees", degrees: plumb),
        ]
        let run: Double? = input.length("run")?.doubleValue ?? input.length("span").map { $0.doubleValue / 2 }
        if let run {
            let common = run * commonFactor
            let hip = run * hipFactor
            results += [
                FunctionResult("rise", inches: run * slope),
                FunctionResult("common", inches: common),
                FunctionResult("plumb", degrees: plumb),
                FunctionResult("level", degrees: 90 - plumb),
                FunctionResult("hip", inches: hip),
                FunctionResult("hipPlumb", degrees: hipPlumb),
                FunctionResult("hipLevel", degrees: 90 - hipPlumb),
                FunctionResult("cheek", degrees: 45),
            ]
            let spacing = (input.length("spacing") ?? prefs.spacing).doubleValue
            if spacing > 0 {
                let increment = spacing * commonFactor
                results.append(FunctionResult("jackIncrement", inches: increment))
                var remaining = common - increment
                var index = 1
                while remaining > 1e-9, index <= 40 {
                    results.append(FunctionResult("jack\(index)", inches: remaining))
                    remaining -= increment
                    index += 1
                }
                results.append(FunctionResult("jack\(index)", inches: 0))
            }
        }
        if let length = input.length("planLength"), let width = input.length("planWidth") {
            let plan = length.doubleValue * width.doubleValue // sq in
            let roof = plan * commonFactor
            results += [
                FunctionResult("planArea", squareInches: plan),
                FunctionResult("roofArea", squareInches: roof),
                FunctionResult("squares", count: roof / 14400),
                FunctionResult("bundles", count: roof / (14400 / 3)),
                FunctionResult("sheets", count: roof / 4608),
            ]
        }
        return results
    }
}
