import CalcKit
import Foundation
import Testing

private let en = Locale(identifier: "en_US")

/// Helpers: solve a spec directly (the estimators are called by spec, not by registry id), read a
/// result as the UG would show it. Defaults come from the spec, then the test's values override.
private func solve(_ spec: FunctionSpec, _ values: [String: FieldValue],
                   prefs: CalcPreferences = .defaults) -> [String: FunctionResult] {
    var input = spec.defaults(prefs)
    for (k, v) in values {
        input[k] = v
    }
    return Dictionary(uniqueKeysWithValues: spec.solve(input, prefs).map { ($0.id, $0) })
}

private func fi(_ r: FunctionResult?, _ precision: Precision = .sixteenth) -> String? {
    r.map { Format.dimension($0.value, unit: $0.displayUnit ?? .feetInches, precision: precision, locale: en).text }
}

private func count(_ r: FunctionResult?) -> String? {
    r.map { Format.scalar($0.value.value, locale: en).text }
}

private func sqft(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .sqFt, precision: .sixteenth, locale: en).text }
}

private func ft(_ f: Int, _ i: Int = 0, _ fr: Fraction = .zero) -> FieldValue {
    .dimension(.feet(f, i, fr))
}

private func inch(_ v: Fraction) -> FieldValue {
    .dimension(.inches(v))
}

struct DrywallTests {
    @Test("X9: 150 sq ft (15′ × 10′) → 4.6875, 4.166667, 3.125 sheets; 5, 5, 4 to order (UG p. 52)")
    func area() {
        let r = solve(Drywall.spec, ["length": ft(15), "height": ft(10)])
        #expect(sqft(r["area"]) == "150 sq ft")
        #expect(count(r["sheets4x8"]) == "4.6875")
        #expect(count(r["sheets4x9"]) == "4.166667")
        #expect(count(r["sheets4x12"]) == "3.125")
        #expect(count(r["sheets4x8Rounded"]) == "5")
        #expect(count(r["sheets4x9Rounded"]) == "5")
        #expect(count(r["sheets4x12Rounded"]) == "4")
        #expect(r["sheets4x8"]?.style == .count)
    }

    @Test("X10: 40 ft of wall alone → 10 sheets of each size (UG p. 52)")
    func length() {
        let r = solve(Drywall.spec, ["length": ft(40)])
        #expect(r["area"] == nil)
        #expect(count(r["sheets4x8"]) == "10")
        #expect(count(r["sheets4x9"]) == "10")
        #expect(count(r["sheets4x12"]) == "10")
        #expect(count(r["sheets4x12Rounded"]) == "10")
        // A whole count rounds to itself; a hair over rounds up.
        let over = solve(Drywall.spec, ["length": ft(40, 0, Fraction(1, 16))])
        #expect(count(over["sheets4x8Rounded"]) == "11")
    }

    @Test("zero or negative sizes and a missing length give nothing")
    func guards() {
        #expect(solve(Drywall.spec, ["length": ft(0)]).isEmpty)
        #expect(solve(Drywall.spec, ["length": ft(10), "height": ft(0)]).isEmpty)
        #expect(solve(Drywall.spec, ["length": .dimension(.feet(10, negative: true))]).isEmpty)
        #expect(solve(Drywall.spec, ["height": ft(8)]).isEmpty)
        #expect(!Drywall.spec.isComplete(Drywall.spec.defaults(.defaults)))
    }
}

struct BlocksTests {
    @Test("X11: 37′ 8″ × 4′ wall, 16 × 8 block, +5 % → 169.5, 177.975, 178 (UG p. 35)")
    func x11() {
        let r = solve(Blocks.spec, ["length": ft(37, 8), "height": ft(4), "waste": .int(5)])
        #expect(sqft(r["area"]) == "150.6667 sq ft")
        #expect(count(r["blocks"]) == "169.5")
        #expect(count(r["blocksWithWaste"]) == "177.975")
        #expect(count(r["blocksRounded"]) == "178")
    }

    @Test("X12: 300 sq ft (30′ × 10′) +3 % → 337.5, 347.625, 348 (UG p. 35)")
    func x12() {
        let r = solve(Blocks.spec, ["length": ft(30), "height": ft(10), "waste": .number(Fraction(3))])
        #expect(count(r["blocks"]) == "337.5")
        #expect(count(r["blocksWithWaste"]) == "347.625")
        #expect(count(r["blocksRounded"]) == "348")
    }

    @Test("X13, X14: one course along 150 ft +3 % → 112.5, 115.875, 116; 20 ft → 15 (UG p. 36)")
    func course() {
        let x13 = solve(Blocks.spec, ["length": ft(150), "waste": .int(3)])
        #expect(x13["area"] == nil)
        #expect(count(x13["blocks"]) == "112.5")
        #expect(count(x13["blocksWithWaste"]) == "115.875")
        #expect(count(x13["blocksRounded"]) == "116")
        let x14 = solve(Blocks.spec, ["length": ft(20)])
        #expect(count(x14["blocks"]) == "15")
        #expect(count(x14["blocksWithWaste"]) == "15")
        #expect(count(x14["blocksRounded"]) == "15")
    }

    @Test("X15: face brick 21 sq in (7 × 3) on 40′ × 8′ +3 % → 2194.286, 2260.114, 2261 (UG p. 37)")
    func x15() {
        let r = solve(
            Blocks.spec,
            [
                "length": ft(40), "height": ft(8), "blockWidth": inch(Fraction(7)),
                "blockHeight": inch(Fraction(3)), "waste": .int(3),
            ]
        )
        #expect(count(r["blocks"]) == "2,194.286")
        #expect(count(r["blocksWithWaste"]) == "2,260.114")
        #expect(count(r["blocksRounded"]) == "2,261")
    }

    @Test("X16: pavers 32 sq in (8 × 4) on 5′ × 15′ → 337.5, 338 (UG p. 37)")
    func x16() {
        let r = solve(
            Blocks.spec,
            ["length": ft(5), "height": ft(15), "blockWidth": inch(Fraction(8)), "blockHeight": inch(Fraction(4))]
        )
        #expect(count(r["blocks"]) == "337.5")
        #expect(count(r["blocksWithWaste"]) == "337.5")
        #expect(count(r["blocksRounded"]) == "338")
    }

    @Test("defaults are the 16 × 8 block with no waste; bad sizes give nothing")
    func defaultsAndGuards() {
        let defaults = Blocks.spec.defaults(.defaults)
        #expect(defaults["blockWidth"] == inch(Fraction(16)))
        #expect(defaults["blockHeight"] == inch(Fraction(8)))
        #expect(defaults["waste"] == .int(0))
        #expect(!Blocks.spec.isComplete(defaults))
        #expect(solve(Blocks.spec, ["length": ft(0), "height": ft(4)]).isEmpty)
        #expect(solve(Blocks.spec, ["length": ft(10), "height": ft(0)]).isEmpty)
        #expect(solve(Blocks.spec, ["length": ft(10), "height": ft(4), "blockWidth": inch(.zero)]).isEmpty)
        #expect(solve(Blocks.spec, ["length": ft(10), "height": ft(4), "waste": .int(-5)]).isEmpty)
    }
}

struct BalustersTests {
    @Test("X18: span 156″, ~4″ gap, 1-1/2″ balusters → 28; 42″ wood; 114″ left; 3-15/16″ gaps (UG p. 77)")
    func x18() {
        let r = solve(Balusters.spec, ["span": inch(Fraction(156))])
        #expect(count(r["balusters"]) == "28")
        #expect(fi(r["totalBalusterWidth"]) == "42″")
        #expect(fi(r["remaining"]) == "114″")
        #expect(fi(r["actualGap"]) == "3-15/16″")
        #expect(r["actualGap"]?.displayUnit == .decimalInches)
        // Exactly: 114 ÷ 29.
        #expect(r["actualGap"]?.value.value == Fraction(114, 29))
    }

    @Test("a span that fits a whole number of balusters, a tiny span, and guards")
    func edges() {
        // 10 balusters of 1½″ at 4″: 11 gaps of 4 + 15 = 59″; floor(59 ÷ 5.5) = 10, gap = 44 ÷ 11 = 4″.
        let even = solve(Balusters.spec, ["span": inch(Fraction(59))])
        #expect(count(even["balusters"]) == "10")
        #expect(fi(even["actualGap"]) == "4″")
        let tiny = solve(Balusters.spec, ["span": inch(Fraction(1))])
        #expect(count(tiny["balusters"]) == "0")
        #expect(fi(tiny["actualGap"]) == "1″")
        #expect(solve(Balusters.spec, ["span": inch(.zero)]).isEmpty)
        #expect(solve(Balusters.spec, ["span": inch(Fraction(100)), "balusterWidth": inch(.zero)]).isEmpty)
        #expect(solve(Balusters.spec, ["span": inch(Fraction(100)), "gap": inch(Fraction(-1))]).isEmpty)
        #expect(!Balusters.spec.isComplete(Balusters.spec.defaults(.defaults)))
    }
}

struct WeightTests {
    @Test("D29: 5 cu yd at 1.5 ton/cu yd → 15,000 lb, 7.5 ton, 6,803.886 kg, 6.803886 t (UG p. 34)")
    func d29() {
        let r = solve(Weight.spec, ["volume": .dimension(.cubicInches(Fraction(5 * 46656)))])
        #expect(count(r["pounds"]) == "15,000")
        #expect(count(r["tons"]) == "7.5")
        #expect(count(r["kilograms"]) == "6,803.886")
        #expect(count(r["metricTons"]) == "6.803886")
        // Exactly 15,000 × 0.45359237 kg.
        #expect(r["kilograms"]?.value.value == Fraction(680_388_555, 100_000))
    }

    @Test("cubic yards as a bare number is the fallback; a volume measure wins; density is read")
    func fallback() {
        let bare = solve(Weight.spec, ["cubicYards": .number(Fraction(5))])
        #expect(count(bare["tons"]) == "7.5")
        #expect(count(bare["pounds"]) == "15,000")
        let both = solve(
            Weight.spec,
            ["volume": .dimension(.cubicInches(Fraction(46656))), "cubicYards": .number(Fraction(5))]
        )
        #expect(count(both["tons"]) == "1.5")
        let dense = solve(Weight.spec, ["cubicYards": .int(2), "density": .number(Fraction(2))])
        #expect(count(dense["tons"]) == "4")
        #expect(count(dense["pounds"]) == "8,000")
    }

    @Test("no volume, a length where a volume should be, zero or negative values give nothing")
    func guards() {
        #expect(solve(Weight.spec, [:]).isEmpty)
        #expect(solve(Weight.spec, ["volume": ft(5)]).isEmpty)
        #expect(solve(Weight.spec, ["cubicYards": .number(.zero)]).isEmpty)
        #expect(solve(Weight.spec, ["cubicYards": .number(Fraction(5)), "density": .number(.zero)]).isEmpty)
        #expect(solve(Weight.spec, ["cubicYards": .number(Fraction(-5))]).isEmpty)
        #expect(Weight.spec.defaults(.defaults)["density"] == .number(Fraction(3, 2)))
    }
}
