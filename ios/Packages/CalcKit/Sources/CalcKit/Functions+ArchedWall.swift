import Foundation

/// Arched wall (UG pp. 41–44; features.md X5, X6): the circle through a chord and rise, plus the stud
/// heights of the wall over (outside) or under (inside) the arch.
///
/// Stud rule, fitted to the UG's figures: studs sit every `spacing` from the centre of the chord outward
/// (the centre stud itself is not listed), stopping before the chord's end. For an *outside* wall, the
/// wall above an arched opening, a stud reaches from the level crown line down to the arc:
/// `base + rise − arcHeight(x)`. For an *inside* wall, the fill under the arch, a stud reaches from the
/// chord up to the arc: `base + arcHeight(x)`. `arcHeight(x) = √(r² − x²) − (r − rise)` with `x` from
/// the centre. Outside heights grow toward the ends (X5: 2-9/16″, 11-3/16″, 2′ 9-1/8″); inside heights
/// shrink (X6: 4′ 10-11/16″ … 1′ 6-1/4″). `base` is a wall height under the arch (X5: 2′ adds 2′).
public enum ArchedWall {
    public static let spec = FunctionSpec(
        id: "archedWall",
        fields: [
            FunctionField("chord", .length),
            FunctionField("rise", .length),
            FunctionField("spacing", .length),
            FunctionField("base", .length, required: false),
            FunctionField("inside", .toggle, required: false),
        ],
        defaults: { prefs in FunctionInput([
            "spacing": .dimension(.inches(prefs.spacing)),
            "base": .dimension(.inches(.zero)),
            "inside": .toggle(false),
        ]) },
        solve: { input, prefs in solve(input, prefs) }
    )

    /// The most studs one solve lists: a tiny spacing on a long chord stops here instead of flooding the sheet.
    static let maxStuds = 200

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        guard let chord = input.length("chord")?.doubleValue, let rise = input.length("rise")?.doubleValue,
              chord > 0, rise > 0 else { return [] }
        let spacing = (input.length("spacing") ?? prefs.spacing).doubleValue
        let base = input.length("base")?.doubleValue ?? 0
        guard spacing > 0, base.isFinite else { return [] }
        let inside = input["inside"]?.toggle ?? false
        let radius = radius(chord: chord, rise: rise)
        let theta = 2 * asin(min(1, chord / (2 * radius)))
        guard radius.isFinite, theta.isFinite else { return [] }
        var results = [
            FunctionResult("radius", inches: radius),
            FunctionResult("arcAngle", degrees: Trig.deg(theta)),
            FunctionResult("arcLength", inches: radius * theta),
            FunctionResult("segment", squareInches: radius * radius / 2 * (theta - sin(theta))),
            FunctionResult("pie", squareInches: radius * radius * theta / 2),
        ]
        results += studs(chord: chord, rise: rise, spacing: spacing, base: base, inside: inside)
        results.append(FunctionResult("base", inches: base))
        return results
    }

    /// The same circle as CircleArc's chord-and-rise case (formulas.md §3.6), kept local on purpose.
    static func radius(chord: Double, rise: Double) -> Double {
        (chord * chord / 4 + rise * rise) / (2 * rise)
    }

    /// `stud1`, `stud2`, … from the centre outward; see the type comment for the rule.
    static func studs(chord: Double, rise: Double, spacing: Double, base: Double, inside: Bool) -> [FunctionResult] {
        let radius = radius(chord: chord, rise: rise)
        var results: [FunctionResult] = []
        var index = 1
        while index <= maxStuds {
            let x = Double(index) * spacing
            guard x < chord / 2 - 1e-9 else { break }
            let arcHeight = max(0, radius * radius - x * x).squareRoot() - (radius - rise)
            let height = inside ? arcHeight : rise - arcHeight
            results.append(FunctionResult("stud\(index)", inches: base + height))
            index += 1
        }
        return results
    }
}
