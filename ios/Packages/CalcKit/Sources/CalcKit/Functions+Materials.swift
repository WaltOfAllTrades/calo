import Foundation

/// Concrete (formulas.md §3.3): slab, footing or column volume, waste, bags.
public enum Concrete {
    public static let spec = FunctionSpec(
        id: "concrete",
        fields: [
            FunctionField("length", .length, required: false),
            FunctionField("width", .length, required: false),
            FunctionField("depth", .length, required: false),
            FunctionField("diameter", .length, required: false),
            FunctionField("height", .length, required: false),
            FunctionField("count", .count),
            FunctionField("waste", .percent),
            FunctionField("bag", .bagSize),
        ],
        defaults: { prefs in
            FunctionInput(["count": .int(1), "waste": .int(prefs.wastePercent), "bag": .int(prefs.bagPounds)])
        },
        solve: { input, prefs in solve(input, prefs) }
    )

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        let count = Double(input["count"]?.int ?? 1)
        let waste = input["waste"]?.number?.doubleValue ?? Double(prefs.wastePercent)
        let requestedBag = input["bag"]?.int ?? prefs.bagPounds
        // An unknown bag size snaps to the nearest one that has a yield.
        let bag = CalcPreferences.bagSizes.min { abs($0 - requestedBag) < abs($1 - requestedBag) } ?? 80
        var cubicInches: Double?
        if let d = input.length("diameter"), let h = input.length("height") {
            let r = d.doubleValue / 2
            cubicInches = Double.pi * r * r * h.doubleValue
        } else if let l = input.length("length"), let w = input.length("width"), let d = input.length("depth") {
            cubicInches = l.doubleValue * w.doubleValue * d.doubleValue
        }
        guard let cubicInches else { return [] }
        let volume = cubicInches * count
        let withWaste = volume * (1 + waste / 100)
        let yield = (CalcPreferences.bagYields[bag] ?? Fraction(3, 5)).doubleValue * 1728 // cu in per bag
        guard volume.isFinite, volume >= 0 else { return [] }
        let bags = (withWaste / yield - 1e-9).rounded(.up)
        var results: [FunctionResult] = []
        if let l = input.length("length"), let w = input.length("width"), input.length("diameter") == nil {
            results.append(FunctionResult("area", squareInches: l.doubleValue * w.doubleValue))
        }
        results += [
            FunctionResult("volume", cubicInches: volume),
            FunctionResult("withWaste", cubicInches: withWaste),
            FunctionResult("bags", count: max(0, bags)),
        ]
        return results
    }
}

/// Board feet (formulas.md §3.4): thickness × width × length(ft) ÷ 12 × count; cost per MBM.
public enum BoardFeet {
    public static let spec = FunctionSpec(
        id: "boardFeet",
        fields: [
            FunctionField("thickness", .length),
            FunctionField("width", .length),
            FunctionField("length", .length),
            FunctionField("count", .count),
            FunctionField("pricePerMbm", .money, required: false),
        ],
        defaults: { _ in FunctionInput(["count": .int(1)]) },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        guard let t = input.length("thickness"), let w = input.length("width"),
              let l = input.length("length") else { return [] }
        let count = Fraction(input["count"]?.int ?? 1)
        // All three are inches; 1 board foot = 144 cubic inches.
        guard let cubic = (t * w).multiplied(by: l),
              let boardFeet = (cubic * count).divided(by: Fraction(144)) else { return [] }
        var results = [FunctionResult("boardFeet", .scalar(boardFeet), style: .count)]
        if let price = input["pricePerMbm"]?.number {
            results.append(FunctionResult("cost", .scalar(boardFeet * price * Fraction(1, 1000)), style: .money))
        }
        return results
    }
}

/// Square-up / diagonal (formulas.md §3.5): any two of rise, run, diagonal; area and perimeter.
public enum SquareUp {
    public static let spec = FunctionSpec(
        id: "squareUp",
        fields: [
            FunctionField("rise", .length, required: false),
            FunctionField("run", .length, required: false),
            FunctionField("diagonal", .length, required: false),
        ],
        defaults: { _ in FunctionInput() },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        let rise = input.length("rise")?.doubleValue
        let run = input.length("run")?.doubleValue
        let diag = input.length("diagonal")?.doubleValue
        let a: Double, b: Double, c: Double
        switch (rise, run, diag) {
        case let (r?, n?, _): a = r; b = n; c = (r * r + n * n).squareRoot()
        case let (r?, nil, d?) where d > r: a = r; c = d; b = (d * d - r * r).squareRoot()
        case let (nil, n?, d?) where d > n: b = n; c = d; a = (d * d - n * n).squareRoot()
        default: return []
        }
        let angle = Trig.deg(atan2(a, b))
        return [
            FunctionResult("diagonal", inches: c),
            FunctionResult("rise", inches: a),
            FunctionResult("run", inches: b),
            FunctionResult("angle", degrees: angle),
            FunctionResult("pitch", inches: 12 * a / max(b, 1e-9)),
            FunctionResult("area", squareInches: a * b),
            FunctionResult("perimeter", inches: 2 * (a + b)),
        ]
    }
}

/// Circle & arc (formulas.md §3.6): from a diameter, a chord and rise, or a diameter with an arc.
public enum CircleArc {
    public static let spec = FunctionSpec(
        id: "circle",
        fields: [
            FunctionField("diameter", .length, required: false),
            FunctionField("chord", .length, required: false),
            FunctionField("rise", .length, required: false),
            FunctionField("arcAngle", .angle, required: false),
            FunctionField("arcLength", .length, required: false),
        ],
        defaults: { _ in FunctionInput() },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        var radius: Double?
        var theta: Double? // radians
        if let d = input.length("diameter")?.doubleValue {
            radius = d / 2
            if let angle = input.angleDegrees("arcAngle") {
                theta = Trig.rad(angle)
            } else if let length = input.length("arcLength")?.doubleValue {
                theta = length / (d / 2)
            }
        } else if let c = input.length("chord")?.doubleValue, let h = input.length("rise")?.doubleValue, h > 0, c > 0 {
            let r = (c * c / 4 + h * h) / (2 * h)
            radius = r
            theta = 2 * asin(min(1, c / (2 * r)))
        }
        guard let r = radius, r > 0, r.isFinite, (theta ?? 0).isFinite else { return [] }
        var results: [FunctionResult] = [
            FunctionResult("radius", inches: r),
            FunctionResult("diameter", inches: 2 * r),
            FunctionResult("circumference", inches: 2 * .pi * r),
            FunctionResult("area", squareInches: .pi * r * r),
        ]
        if let t = theta {
            results += [
                FunctionResult("arcAngle", degrees: Trig.deg(t)),
                FunctionResult("arcLength", inches: r * t),
                FunctionResult("chord", inches: 2 * r * sin(t / 2)),
                FunctionResult("rise", inches: r - r * cos(t / 2)),
                FunctionResult(
                    "segment",
                    squareInches: r * r / 2 * (t - sin(t))
                ),
                FunctionResult("pie", squareInches: r * r * t / 2),
            ]
        }
        return results
    }
}

/// Compound miter (formulas.md §3.7; UG p. 45): spring angle and corner angle → miter and bevel.
public enum CompoundMiter {
    public static let spec = FunctionSpec(
        id: "miter",
        fields: [FunctionField("spring", .angle), FunctionField("corner", .angle)],
        defaults: { _ in FunctionInput([
            "spring": .dimension(.degrees(Fraction(45))),
            "corner": .dimension(.degrees(Fraction(90))),
        ]) },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        guard let spring = input.angleDegrees("spring"), let corner = input.angleDegrees("corner"), corner > 0,
              corner < 180 else { return [] }
        let s = Trig.rad(spring)
        let half = Trig.rad(corner / 2)
        let miter = Trig.deg(atan(sin(s) / tan(half)))
        let bevel = Trig.deg(asin(cos(s) * cos(half)))
        return [FunctionResult("miter", degrees: miter), FunctionResult("bevel", degrees: bevel)]
    }
}

/// Polygon (formulas.md §3.8; UG p. 49): circumscribed radius and sides.
public enum Polygon {
    public static let spec = FunctionSpec(
        id: "polygon",
        fields: [FunctionField("radius", .length), FunctionField("sides", .count)],
        defaults: { _ in FunctionInput(["sides": .int(6)]) },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        guard let r = input.length("radius")?.doubleValue, let n = input["sides"]?.int,
              n >= 3 else { return [] } // E-K20
        // Interior ("full") angle = 180 − 360/n (UG p. 49: 6 sides → 120°, half 60°).
        let central = 360.0 / Double(n)
        let full = 180 - central
        let side = 2 * r * sin(Trig.rad(central / 2))
        let area = Double(n) * r * r * sin(Trig.rad(central)) / 2
        return [
            FunctionResult("fullAngle", degrees: full),
            FunctionResult("halfAngle", degrees: full / 2),
            FunctionResult("side", inches: side),
            FunctionResult("perimeter", inches: Double(n) * side),
            FunctionResult("area", squareInches: area),
        ]
    }
}

/// Studs (formulas.md §3.9; UG p. 78): ceil(length ÷ spacing) + 1.
public enum Studs {
    public static let spec = FunctionSpec(
        id: "studs",
        fields: [FunctionField("length", .length), FunctionField("spacing", .length)],
        defaults: { prefs in FunctionInput(["spacing": .dimension(.inches(prefs.spacing))]) },
        solve: { input, prefs in solve(input, prefs) }
    )

    static func solve(_ input: FunctionInput, _ prefs: CalcPreferences) -> [FunctionResult] {
        guard let length = input.length("length"), let spacing = input.length("spacing") ?? Optional(prefs.spacing),
              spacing > .zero else { return [] }
        let count = (length.doubleValue / spacing.doubleValue - 1e-9).rounded(.up) + 1
        return [FunctionResult("studs", count: count)]
    }
}
