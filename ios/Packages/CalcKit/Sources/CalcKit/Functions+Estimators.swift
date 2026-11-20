import Foundation

// Estimators (features.md §2.7 X9–X18, §2.1 D29; UG pp. 34–37, 52, 77, 82): drywall sheets, blocks
// and bricks, balusters, and the weight of a volume. Exact `Fraction` arithmetic end to end: no
// formula here needs a double, so no result passes through an approximating initialiser. Counts stay
// fractional, as the Construction Master shows them, with a rounded-up companion for ordering.

/// Shared pieces of the estimators.
enum Estimate {
    /// Square inches in a square foot (a 4×8 sheet is 32 sq ft).
    static let squareFoot = Fraction(144)

    /// The smallest whole number not below `value`: what you order. Exact, so 4 stays 4 and 4.0001 is 5.
    static func wholeUp(_ value: Fraction) -> Fraction {
        value.remainder.isZero || value.isNegative ? Fraction(value.whole) : Fraction(value.whole + 1)
    }

    /// `value` plus a percentage, exactly (the UG p. 25 percent rule, as `Measure.applyingPercent`).
    static func adding(percent: Fraction, to value: Fraction) -> Fraction {
        value * (Fraction.one + percent * Fraction(1, 100))
    }

    /// A fractional count and its rounded-up companion, as two results (`id`, `idRounded`).
    static func countPair(_ id: String, _ value: Fraction) -> [FunctionResult] {
        [
            FunctionResult(id, .scalar(value), style: .count),
            FunctionResult(id + "Rounded", .scalar(wholeUp(value)), style: .count),
        ]
    }
}

/// Drywall (UG p. 52; X9, X10): sheets of 4×8, 4×9 and 4×12 for a wall area (length × height), or
/// for a wall length alone, where each 4-ft-wide sheet stands on end and covers 4 ft of wall.
public enum Drywall {
    /// Sheet sizes by result id and face area in square feet.
    static let sheets: [(id: String, squareFeet: Int)] = [
        ("sheets4x8", 32), ("sheets4x9", 36), ("sheets4x12", 48),
    ]

    public static let spec = FunctionSpec(
        id: "drywall",
        fields: [FunctionField("length", .length), FunctionField("height", .length, required: false)],
        defaults: { _ in FunctionInput() },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        guard let length = input.length("length"), length > .zero else { return [] }
        guard let height = input.length("height") else {
            // Length only (X10): 40 ft → 10 sheets of every size.
            guard let perRow = length / Fraction(48) else { return [] }
            return sheets.flatMap { Estimate.countPair($0.id, perRow) }
        }
        guard height > .zero else { return [] }
        let area = length * height
        var results = [FunctionResult("area", .squareInches(area))]
        for sheet in sheets {
            guard let count = area / (Fraction(sheet.squareFeet) * Estimate.squareFoot) else { return [] }
            results += Estimate.countPair(sheet.id, count)
        }
        return results
    }
}

/// Blocks, bricks and pavers (UG pp. 35–37; X11–X16): units of one face size over a wall area, or
/// along a length alone (one course: length ÷ unit width, X13, X14). Waste is added to the count.
/// Defaults are the standard block, 16 × 8 in = 128 sq in; a face brick is 21 sq in, a paver 32.
public enum Blocks {
    public static let defaultWidth = Fraction(16)
    public static let defaultHeight = Fraction(8)

    public static let spec = FunctionSpec(
        id: "blocks",
        fields: [
            FunctionField("length", .length),
            FunctionField("height", .length, required: false),
            FunctionField("blockWidth", .length),
            FunctionField("blockHeight", .length),
            FunctionField("waste", .percent),
        ],
        defaults: { _ in FunctionInput([
            "blockWidth": .dimension(.inches(defaultWidth)),
            "blockHeight": .dimension(.inches(defaultHeight)),
            "waste": .int(0),
        ]) },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        let blockWidth = input.length("blockWidth") ?? defaultWidth
        let blockHeight = input.length("blockHeight") ?? defaultHeight
        let waste = input["waste"]?.number ?? .zero
        guard let length = input.length("length"), length > .zero, blockWidth > .zero, blockHeight > .zero,
              !waste.isNegative else { return [] }
        var results: [FunctionResult] = []
        let count: Fraction?
        if let height = input.length("height") {
            guard height > .zero else { return [] }
            let area = length * height
            results.append(FunctionResult("area", .squareInches(area)))
            count = area / (blockWidth * blockHeight)
        } else {
            count = length / blockWidth
        }
        guard let blocks = count else { return [] }
        let withWaste = Estimate.adding(percent: waste, to: blocks)
        results += [
            FunctionResult("blocks", .scalar(blocks), style: .count),
            FunctionResult("blocksWithWaste", .scalar(withWaste), style: .count),
            FunctionResult("blocksRounded", .scalar(Estimate.wholeUp(withWaste)), style: .count),
        ]
        return results
    }
}

/// Balusters (UG p. 77; X18): how many fit a span at about the wanted gap, and the gap that results.
/// Whole balusters only; what is left of the span is shared among count + 1 equal gaps.
public enum Balusters {
    public static let defaultGap = Fraction(4)
    public static let defaultWidth = Fraction(3, 2)

    public static let spec = FunctionSpec(
        id: "balusters",
        fields: [
            FunctionField("span", .length),
            FunctionField("gap", .length),
            FunctionField("balusterWidth", .length),
        ],
        defaults: { _ in FunctionInput([
            "gap": .dimension(.inches(defaultGap)),
            "balusterWidth": .dimension(.inches(defaultWidth)),
        ]) },
        solve: { input, _ in solve(input) }
    )

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        let gap = input.length("gap") ?? defaultGap
        let width = input.length("balusterWidth") ?? defaultWidth
        guard let span = input.length("span"), span > .zero, width > .zero, !gap.isNegative,
              let fit = span / (gap + width) else { return [] }
        // 156 ÷ (4 + 1½) = 28.36 → 28 balusters, 42 in of wood, 114 in left over 29 gaps = 3-15/16 in.
        let count = fit.whole
        let total = Fraction(count) * width
        let remaining = span - total
        guard let actualGap = remaining / Fraction(count + 1) else { return [] }
        return [
            FunctionResult("balusters", .scalar(Fraction(count)), style: .count),
            FunctionResult("totalBalusterWidth", .inches(total), displayUnit: .decimalInches),
            FunctionResult("remaining", .inches(remaining), displayUnit: .decimalInches),
            FunctionResult("actualGap", .inches(actualGap), displayUnit: .decimalInches),
        ]
    }
}

/// Weight of a volume (UG pp. 34, 82; D29): cubic yards × density in tons per cubic yard. The default
/// density is concrete's, 1.5 ton/cu yd. 1 ton = 2,000 lb; 1 lb = 0.45359237 kg exactly.
public enum Weight {
    public static let defaultDensity = Fraction(3, 2)
    static let cubicInchesPerYard = Fraction(46656)
    static let poundsPerTon = Fraction(2000)
    static let kilogramsPerPound = Fraction(45_359_237, 100_000_000)

    public static let spec = FunctionSpec(
        id: "weight",
        fields: [
            FunctionField("volume", .volume, required: false),
            FunctionField("cubicYards", .number, required: false),
            FunctionField("density", .number),
        ],
        defaults: { _ in FunctionInput(["density": .number(defaultDensity)]) },
        solve: { input, _ in solve(input) }
    )

    /// The volume in cubic yards: a volume measure first, else the bare cubic-yard number.
    static func cubicYards(_ input: FunctionInput) -> Fraction? {
        if let measure = input["volume"]?.dimension, measure.kind == .volume {
            return measure.value / cubicInchesPerYard
        }
        return input["cubicYards"]?.number
    }

    static func solve(_ input: FunctionInput) -> [FunctionResult] {
        let density = input["density"]?.number ?? defaultDensity
        guard let yards = cubicYards(input), yards > .zero, density > .zero else { return [] }
        let tons = yards * density
        let pounds = tons * poundsPerTon
        let kilograms = pounds * kilogramsPerPound
        guard let metricTons = kilograms / Fraction(1000) else { return [] }
        return [
            FunctionResult("pounds", .scalar(pounds), style: .count),
            FunctionResult("tons", .scalar(tons), style: .count),
            FunctionResult("kilograms", .scalar(kilograms), style: .count),
            FunctionResult("metricTons", .scalar(metricTons), style: .count),
        ]
    }
}
