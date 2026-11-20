import CalcKit
import Foundation
import Testing

private let en = Locale(identifier: "en_US")

struct DimensionTests {
    @Test("feet-inches construction and exact metric")
    func construction() {
        let d = Measure.feet(5, 3, Fraction(1, 2))
        #expect(d.value == Fraction(127, 2))
        #expect(d.kind == .length)
        // 1 in = 25.4 mm exactly.
        #expect(Measure.inches(.one).converted(to: .millimetres) == Fraction(254, 10))
        #expect(Measure.inches(Fraction(254, 10)).converted(to: .millimetres) == Fraction(6_451_600, 10000))
        #expect(abs((Measure.feet(Fraction(14)).converted(to: .metres)?.doubleValue ?? 0) - 4.2672) < 1e-12)
    }

    @Test("the algebra table (formulas.md §1)")
    func algebra() throws {
        let ft5 = Measure.feet(Fraction(5))
        let in3 = Measure.inches(Fraction(3))
        #expect(try ft5.adding(in3) == Measure.feet(5, 3))
        #expect(try ft5.subtracting(in3) == Measure.feet(4, 9))
        #expect(try ft5.multiplied(by: in3).kind == .area)
        #expect(try ft5.multiplied(by: in3).value == Fraction(180))
        #expect(try ft5.multiplied(by: in3).multiplied(by: in3).kind == .volume)
        #expect(try ft5.divided(by: in3) == .scalar(Fraction(20)))
        #expect(try ft5.multiplied(by: .scalar(Fraction(3))) == Measure.feet(Fraction(15)))
        #expect(try ft5.divided(by: .scalar(Fraction(2))) == Measure.feet(2, 6))
        let area = try ft5.multiplied(by: ft5)
        #expect(try area.divided(by: ft5) == ft5)
        let volume = try area.multiplied(by: in3)
        #expect(try volume.divided(by: area) == in3)
        #expect(try volume.divided(by: in3) == area)
        #expect(throws: CalcError.dimensionMismatch(.length, .area)) { try ft5.adding(area) }
        #expect(throws: CalcError.divideByZero) { try ft5.divided(by: .scalar(.zero)) }
    }

    @Test("percent rules D18–D21")
    func percent() throws {
        let ft500 = Measure.feet(Fraction(500))
        #expect(try ft500.applyingPercent(Fraction(18), operation: .multiply) == Measure.feet(Fraction(90)))
        let sq137 = Measure.squareFeet(Fraction(137))
        #expect(try sq137.applyingPercent(Fraction(10), operation: .add).converted(to: .sqFt) == Fraction(1507, 10))
        #expect(try Measure.feet(552, 6).applyingPercent(Fraction(20), operation: .subtract) == Measure
            .feet(Fraction(442)))
        let yd350 = Measure(Fraction(350) * Fraction(46656), .volume)
        #expect(try yd350.applyingPercent(Fraction(80), operation: .divide).converted(to: .cuYd) == Fraction(875, 2))
    }

    @Test("arithmetic D10–D17 through the algebra")
    func arithmetic() throws {
        #expect(try Measure.inches(Fraction(11)).adding(Measure.feet(2, 1)) == Measure.feet(Fraction(3)))
        #expect(try Measure.feet(5, 7, Fraction(1, 2)).adding(Measure.feet(18, 8)) == Measure.feet(
            24,
            3,
            Fraction(1, 2)
        ))
        #expect(try Measure.feet(11, 7, Fraction(1, 2)).subtracting(Measure.feet(Fraction(3))) == Measure.feet(
            8,
            7,
            Fraction(1, 2)
        ))
        let area = try Measure.feet(5, 3).multiplied(by: Measure.feet(11, 6, Fraction(1, 2)))
        #expect(area.converted(to: .sqFt) == Fraction(3878, 64)) // 60.59375
        #expect(try Measure.feet(2, 7).multiplied(by: .scalar(Fraction(10))) == Measure.feet(25, 10))
        #expect(try Measure.feet(30, 4).divided(by: Measure.inches(Fraction(7))) == .scalar(Fraction(52)))
        #expect(try Measure.feet(20, 3).divided(by: .scalar(Fraction(9))) == Measure.feet(2, 3))
    }

    @Test("overflow surfaces as tooLarge, never a crash (E-K10)")
    func overflow() {
        let huge = Measure.scalar(Fraction(Int.max / 2))
        #expect(throws: CalcError.tooLarge) { try huge.multiplied(by: .scalar(Fraction(4))) }
        #expect(throws: CalcError.tooLarge) { try huge.adding(huge).adding(huge) }
    }
}

struct PrecisionAndFormatTests {
    private func fi(_ d: Measure, _ p: Precision = .sixteenth) -> String {
        Format.dimension(d, unit: .feetInches, precision: p, locale: en).text
    }

    @Test("D2: 45/64 at every precision")
    func d2() {
        let v = Measure.inches(Fraction(45, 64))
        #expect(fi(v, .sixteenth) == "0-11/16″")
        #expect(fi(v, .half) == "0-1/2″")
        #expect(fi(v, .thirtySecond) == "0-23/32″")
        #expect(fi(v, .quarter) == "0-3/4″")
        #expect(fi(v, .sixtyFourth) == "0-45/64″")
        #expect(fi(v, .eighth) == "0-3/4″")
        #expect(fi(v, .exact) == "0-45/64″")
        #expect(Format.dimension(v, unit: .feetInches, precision: .sixteenth, locale: en).isRounded)
        #expect(!Format.dimension(v, unit: .feetInches, precision: .sixtyFourth, locale: en).isRounded)
    }

    @Test("feet-inch strings: whole feet keep 0″, sub-foot drops feet, negatives lead with a minus")
    func strings() {
        #expect(fi(.feet(15, 9, Fraction(1, 2))) == "15′ 9-1/2″")
        #expect(fi(.feet(Fraction(14))) == "14′ 0″")
        #expect(fi(.feet(0, 3, Fraction(1, 2))) == "3-1/2″")
        #expect(fi(.inches(Fraction(-5, 16))) == "\u{2212}0-5/16″")
        #expect(fi(.feet(24, 3, Fraction(1, 2))) == "24′ 3-1/2″")
        // 11-63/64 at 1/16 rounds up to the next foot.
        #expect(fi(.feet(0, 11, Fraction(63, 64))) == "1′ 0″")
    }

    @Test("D3–D9 conversions")
    func conversions() {
        let ft14 = Measure.feet(Fraction(14))
        #expect(Format.dimension(ft14, unit: .yards, precision: .sixteenth, locale: en).text == "4.666667 yd")
        #expect(Format.dimension(ft14, unit: .decimalInches, precision: .sixteenth, locale: en).text == "168″")
        #expect(Format.dimension(ft14, unit: .metres, precision: .sixteenth, locale: en).text == "4.267 m")
        #expect(Format.dimension(ft14, unit: .centimetres, precision: .sixteenth, locale: en).text == "426.72 cm")
        #expect(Format.dimension(ft14, unit: .millimetres, precision: .sixteenth, locale: en).text == "4,267.2 mm")
        let d4 = Measure.feet(15, 9, Fraction(1, 2))
        #expect(Format.dimension(d4, unit: .decimalFeet, precision: .sixteenth, locale: en).text == "15.79167 ft")
        let d5 = Measure.feet(Fraction(1732, 100))
        #expect(fi(d5) == "17′ 3-13/16″")
        let d7 = Measure.inches(Fraction(90625, 10000))
        #expect(fi(d7) == "9-1/16″")
        #expect(Format.dimension(d7, unit: .decimalFeet, precision: .sixteenth, locale: en).text == "0.755208 ft")
        let sq14 = Measure.squareFeet(Fraction(14))
        #expect(Format.dimension(sq14, unit: .sqIn, precision: .sixteenth, locale: en).text == "2,016 sq in")
        #expect(Format.dimension(sq14, unit: .sqYd, precision: .sixteenth, locale: en).text == "1.555556 sq yd")
        #expect(Format.dimension(sq14, unit: .sqM, precision: .sixteenth, locale: en).text == "1.300643 m²")
        let cu14 = Measure.cubicFeet(Fraction(14))
        #expect(Format.dimension(cu14, unit: .cuIn, precision: .sixteenth, locale: en).text == "24,192 cu in")
        #expect(Format.dimension(cu14, unit: .cuYd, precision: .sixteenth, locale: en).text == "0.518519 cu yd")
        #expect(Format.dimension(cu14, unit: .cuM, precision: .sixteenth, locale: en).text == "0.396436 m³")
    }

    @Test("angles: degrees, pitch, grade and D:M:S (R1, R2, D27)")
    func angles() {
        let a = Measure.degrees(Fraction(3045, 100))
        #expect(Format.dimension(a, unit: .degrees, precision: .sixteenth, locale: en).text == "30.45°")
        #expect(Format.dimension(a, unit: .grade, precision: .sixteenth, locale: en).text == "58.79 % grade")
        #expect(Format.dimension(a, unit: .pitch, precision: .sixteenth, locale: en).text == "7-1/16 in/12")
        let fromGrade = AngleFormat.degrees(fromGrade: 47.25)
        #expect(abs(fromGrade - 25.29) < 0.005)
        #expect(AngleFormat.dms(23.71) == "23°42′36″")
        #expect(AngleFormat.dms(53.1301) == "53°07′48″")
    }

    @Test("unit cycles and the precision chip cycle")
    func cycles() {
        #expect(DisplayUnit.cycle(for: .length, system: .imperial).first == .feetInches)
        #expect(DisplayUnit.cycle(for: .volume, system: .imperial).first == .cuYd)
        #expect(DisplayUnit.cycle(for: .length, system: .metric).first == .millimetres)
        #expect(DisplayUnit.cycle(for: .scalar, system: .imperial).isEmpty)
        #expect(DisplayUnit.next(after: .metres, system: .imperial) == .feetInches)
        #expect(Precision.sixteenth.next == .thirtySecond)
        #expect(Precision.sixtyFourth.next == .exact)
        #expect(Precision.exact.next == .half)
        #expect(Precision.exact.entryDenominator == 64)
        #expect(Format.formats(for: .feet(Fraction(14)), system: .imperial, precision: .sixteenth, locale: en)
            .count == 7)
    }
}
