import CalcKit
import Foundation
import Testing

private let en = Locale(identifier: "en_US")

/// Drives the engine with key sequences and checks the result and the expression line.
struct EntryEngineTests {
    private func run(_ keys: [Key], precision: Precision = .sixteenth, system: UnitSystem = .imperial) -> EntryEngine {
        var engine = EntryEngine()
        for key in keys {
            engine.press(key, precision: precision, system: system)
        }
        return engine
    }

    private func text(_ engine: EntryEngine, unit: DisplayUnit = .feetInches,
                      precision: Precision = .sixteenth) -> String? {
        guard let result = engine.result(precision: precision, system: .imperial) else { return nil }
        if result.kind == .scalar {
            return Format.scalar(result.value, locale: en).text
        }
        return Format.dimension(result, unit: unit, precision: precision, locale: en).text
    }

    private var d: (Int) -> Key {
        { .digit($0) }
    }

    @Test("D1: natural entry 5 ′ 1 ″ 1 ⁄ 2 reads as 5 ft 1-1/2 in and shows as 5′ 1-1⁄2″")
    func d1() {
        let e = run([d(5), .feet, d(1), .inches, d(1), .fractionBar, d(2), .equals])
        #expect(e.result(precision: .sixteenth, system: .imperial) == Measure.feet(5, 1, Fraction(1, 2)))
        #expect(e.expressionText == "5′ 1-1⁄2″")
        #expect(e.isCommitted)
    }

    @Test("D2: 44 ⁄ 64 + 1 ⁄ 64 = is 45/64 inch; the fraction alone is inches")
    func d2() {
        let e = run([d(4), d(4), .fractionBar, d(6), d(4), .plus, d(1), .fractionBar, d(6), d(4), .equals])
        #expect(text(e, precision: .sixtyFourth) == "0-45/64″")
        #expect(text(e) == "0-11/16″")
    }

    @Test("D10–D17 arithmetic through the keys")
    func arithmetic() {
        #expect(text(run([d(1), d(1), .inches, .plus, d(2), .feet, d(1), .inches, .equals])) == "3′ 0″")
        #expect(text(run([
            d(5), .feet, d(7), .inches, d(1), .fractionBar, d(2), .plus,
            d(1),
            d(8),
            .feet,
            d(8),
            .inches,
            .equals,
        ])) == "24′ 3-1/2″")
        #expect(text(run([d(1), d(1), .feet, d(7), .inches, d(1), .fractionBar, d(2), .minus, d(3), .feet, .equals])) ==
            "8′ 7-1/2″")
        #expect(text(run([d(8), d(1), .inches, .minus, d(3), d(2), .inches, .equals]), unit: .decimalInches) == "49″")
        #expect(text(
            run([
                d(5),
                .feet,
                d(3),
                .inches,
                .times,
                d(1), d(1), .feet, d(6), .inches, d(1), .fractionBar, d(2), .equals,
            ]),
            unit: .sqFt
        ) == "60.59375 sq ft")
        #expect(text(run([d(2), .feet, d(7), .inches, .times, d(1), d(0), .equals])) == "25′ 10″")
        #expect(text(run([d(3), d(0), .feet, d(4), .inches, .divide, d(7), .inches, .equals])) == "52")
        #expect(text(run([d(2), d(0), .feet, d(3), .inches, .divide, d(9), .equals])) == "2′ 3″")
    }

    @Test("inches may follow feet without a mark: 5 ′ 3 + reads 5′ 3″")
    func trailingInches() {
        let e = run([d(5), .feet, d(3), .plus, d(1), .inches, .equals])
        #expect(e.result(precision: .sixteenth, system: .imperial) == Measure.feet(5, 4))
    }

    @Test("D18–D21 percent")
    func percent() {
        #expect(text(run([d(5), d(0), d(0), .feet, .times, d(1), d(8), .percent, .equals])) == "90′ 0″")
        #expect(text(run([d(1), d(3), d(7), .feet, .feet, .plus, d(1), d(0), .percent, .equals]), unit: .sqFt) ==
            "150.7 sq ft")
        #expect(text(run([d(5), d(5), d(2), .feet, d(6), .inches, .minus, d(2), d(0), .percent, .equals])) == "442′ 0″")
        #expect(text(run([d(5), d(0), .percent, .equals])) == "0.5")
    }

    @Test("D22 running total: 5′ 4-1/2″ + 8″ + 3.5 yd through chained equals")
    func runningTotal() {
        var e = run([d(5), .feet, d(4), .inches, d(1), .fractionBar, d(2), .plus, d(8), .inches, .equals])
        #expect(text(e) == "6′ 0-1/2″")
        e.press(.plus, precision: .sixteenth, system: .imperial)
        e.press(.digit(1), precision: .sixteenth, system: .imperial)
        e.press(.digit(2), precision: .sixteenth, system: .imperial)
        e.press(.digit(6), precision: .sixteenth, system: .imperial)
        e.press(.inches, precision: .sixteenth, system: .imperial) // 3.5 yd = 126 in
        e.press(.equals, precision: .sixteenth, system: .imperial)
        #expect(text(e) == "16′ 6-1/2″")
    }

    @Test("parentheses and precedence")
    func parentheses() {
        #expect(text(run([.open, d(2), .feet, .plus, d(3), .inches, .close, .times, d(4), .equals])) == "9′ 0″")
        #expect(text(run([d(2), .plus, d(3), .times, d(4), .equals])) == "14")
        // E-K08: a missing close is supplied at =.
        #expect(text(run([.open, d(2), .plus, d(3), .times, d(4), .equals])) == "14")
        // Unmatched close is ignored.
        #expect(run([d(2), .close]).expressionText == "2")
    }

    @Test("E-K02: a fraction bar after a decimal is refused")
    func decimalThenFraction() {
        let e = run([d(3), .point, d(5), .fractionBar, d(2)])
        #expect(e.expressionText == "3.52")
    }

    @Test("E-K04: a bare number added to a length is inches and the line says so")
    func impliedUnit() {
        let e = run([d(5), .feet, .plus, d(3), .equals])
        #expect(e.result(precision: .sixteenth, system: .imperial) == Measure.feet(5, 3))
        #expect(e.expressionText == "5′ + 3″")
        let metric = run([d(5), .feet, .plus, d(3), .equals], system: .metric)
        #expect(metric.result(precision: .sixteenth, system: .metric)?.converted(to: .millimetres) == Fraction(1527, 1))
        #expect(metric.expressionText == "5′ + 3 mm")
        // Multiplying by a bare number keeps it a scalar.
        let scaled = run([d(5), .feet, .times, d(3), .equals])
        #expect(scaled.expressionText == "5′ × 3")
    }

    @Test("E-K05: a fraction without a denominator uses the precision")
    func missingDenominator() {
        let e = run([d(1), d(5), .fractionBar, .plus, d(1), .inches, .equals])
        #expect(text(e) == "1-15/16″")
        let exact = run([d(1), d(5), .fractionBar, .plus, d(1), .inches, .equals], precision: .exact)
        #expect(exact.result(precision: .exact, system: .imperial) == Measure.inches(Fraction(79, 64)))
    }

    @Test("E-K06, E-K07, E-K09: stray marks, doubled operators, trailing operator")
    func strays() {
        #expect(run([.feet, .inches, .fractionBar]).expressionText == "")
        #expect(run([d(2), .plus, .times, d(3), .equals])
            .result(precision: .sixteenth, system: .imperial) == .scalar(Fraction(6)))
        #expect(run([d(2), .plus, .equals]).result(precision: .sixteenth, system: .imperial) == .scalar(Fraction(2)))
        #expect(run([.equals]).isEmpty)
    }

    @Test("backspace walks back through a fraction and a mark")
    func backspace() {
        var e = run([d(5), .feet, d(3), .inches, d(1), .fractionBar, d(2), .inches])
        #expect(e.expressionText == "5′ 3-1⁄2″")
        let steps: [String] = ["5′ 3″ 1⁄2", "5′ 3″ 1⁄", "5′ 3″ 1", "5′ 3″", "5′ 3", "5′", "5", ""]
        for expected in steps {
            e.press(.backspace, precision: .sixteenth, system: .imperial)
            #expect(e.expressionText == expected)
        }
    }

    @Test("E-K25: backspace on a result makes it an editable value; typing after = starts fresh; an operator continues")
    func afterEquals() {
        var e = run([d(2), .feet, .plus, d(1), .feet, .equals])
        e.press(.backspace, precision: .sixteenth, system: .imperial)
        #expect(!e.isCommitted)
        #expect(e.result(precision: .sixteenth, system: .imperial) == Measure.feet(Fraction(3)))
        var fresh = run([d(2), .plus, d(1), .equals])
        fresh.press(.digit(7), precision: .sixteenth, system: .imperial)
        #expect(fresh.expressionText == "7")
        var cont = run([d(2), .plus, d(1), .equals])
        cont.press(.times, precision: .sixteenth, system: .imperial)
        cont.press(.digit(5), precision: .sixteenth, system: .imperial)
        cont.press(.equals, precision: .sixteenth, system: .imperial)
        #expect(cont.result(precision: .sixteenth, system: .imperial) == .scalar(Fraction(15)))
    }

    @Test("undo restores after = and after AC")
    func undo() {
        var e = run([d(2), .plus, d(3), .equals])
        e.press(.undo, precision: .sixteenth, system: .imperial)
        #expect(!e.isCommitted)
        #expect(e.expressionText == "2 + 3")
        e.press(.allClear, precision: .sixteenth, system: .imperial)
        #expect(e.isEmpty)
        e.press(.undo, precision: .sixteenth, system: .imperial)
        #expect(e.expressionText == "2 + 3")
    }

    @Test("errors: divide by zero and a dimension mismatch keep the expression")
    func errors() {
        let z = run([d(5), .feet, .divide, d(0), .equals])
        #expect(z.error == .divideByZero)
        #expect(z.expressionText == "5′ ÷ 0")
        let m = run([d(5), .feet, .plus, d(2), .feet, .feet, .equals])
        #expect(m.error == .dimensionMismatch(.length, .area))
    }

    @Test("memory: M+, M−, MR, MC and the kind check (E-K15)")
    func memory() {
        var e = run([d(5), .feet, .equals, .memoryAdd])
        #expect(e.memory == Measure.feet(Fraction(5)))
        e.press(.allClear, precision: .sixteenth, system: .imperial)
        e.press(.digit(1), precision: .sixteenth, system: .imperial)
        e.press(.feet, precision: .sixteenth, system: .imperial)
        e.press(.equals, precision: .sixteenth, system: .imperial)
        e.press(.memorySubtract, precision: .sixteenth, system: .imperial)
        #expect(e.memory == Measure.feet(Fraction(4)))
        e.press(.allClear, precision: .sixteenth, system: .imperial)
        e.press(.memoryRecall, precision: .sixteenth, system: .imperial)
        e.press(.plus, precision: .sixteenth, system: .imperial)
        e.press(.digit(1), precision: .sixteenth, system: .imperial)
        e.press(.feet, precision: .sixteenth, system: .imperial)
        e.press(.equals, precision: .sixteenth, system: .imperial)
        #expect(e.result(precision: .sixteenth, system: .imperial) == Measure.feet(Fraction(5)))
        e.press(.allClear, precision: .sixteenth, system: .imperial)
        for key in [d(2), .feet, .feet, .equals, .memoryAdd] {
            e.press(key, precision: .sixteenth, system: .imperial)
        }
        #expect(e.error == .dimensionMismatch(.length, .area))
        #expect(e.memory == Measure.feet(Fraction(4)))
        e.press(.memoryClear, precision: .sixteenth, system: .imperial)
        #expect(e.memory == nil)
    }

    @Test("insert replaces a half-typed number (E-K13) and the tape line carries the expression")
    func insertAndTape() {
        var e = run([d(5), .feet, .plus, d(1)])
        e.insert(Measure.feet(Fraction(2)))
        e.press(.equals, precision: .sixteenth, system: .imperial)
        #expect(e.result(precision: .sixteenth, system: .imperial) == Measure.feet(Fraction(7)))
        var fresh = EntryEngine()
        for key in [d(2), .plus, d(3)] {
            fresh.press(key, precision: .sixteenth, system: .imperial)
        }
        let line = fresh.press(.equals, precision: .sixteenth, system: .imperial, now: Date(timeIntervalSince1970: 0))
        #expect(line?.expression == "2 + 3")
        #expect(line?.result == .scalar(Fraction(5)))
    }

    @Test("snapshot round trip restores everything (E-K16)")
    func snapshot() throws {
        var e = run([d(5), .feet, d(3), .inches, .plus, d(1), .feet])
        e.press(.memoryAdd, precision: .sixteenth, system: .imperial)
        e.cycleUnit(system: .imperial, kind: .length)
        let data = try JSONEncoder().encode(e)
        let restored = try JSONDecoder().decode(EntryEngine.self, from: data)
        #expect(restored == e)
        #expect(restored.expressionText == "5′ 3″ + 1′")
        #expect(restored.displayUnit == .decimalFeet)
    }

    @Test("square and cubic marks: 100 ′′ is 100 sq ft; 2 ″″ is 2 sq in")
    func powers() {
        #expect(text(run([d(1), d(0), d(0), .feet, .feet, .equals]), unit: .sqFt) == "100 sq ft")
        #expect(text(run([d(2), .inches, .inches, .equals]), unit: .sqIn) == "2 sq in")
        #expect(run([d(1), .feet, .feet, .feet]).result(precision: .sixteenth, system: .imperial)?.kind == .volume)
    }
}
