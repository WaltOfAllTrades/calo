import CalcKit
import Testing

struct NaturalEntryTests {
    @Test("length spellings", arguments: [
        ("5' 3 1/2\"", Measure.feet(5, 3, Fraction(1, 2))),
        ("5′ 3-1/2″", Measure.feet(5, 3, Fraction(1, 2))),
        ("63.5\"", Measure.inches(Fraction(127, 2))),
        ("3.5'", Measure.feet(3, 6)),
        ("1/2", Measure.inches(Fraction(1, 2))),
        ("7", Measure.inches(Fraction(7))),
        ("1500 mm", Measure.inches(Fraction(1500) * Fraction(5, 127))),
        ("2.5 m", Measure.inches(Fraction(2500) * Fraction(5, 127))),
        ("-0-5/16\"", Measure.inches(Fraction(-5, 16))),
        ("12 ft", Measure.feet(Fraction(12))),
    ])
    func lengths(text: String, expected: Measure) {
        #expect(NaturalEntry.parse(text, expecting: .length) == .dimension(expected))
    }

    @Test("angles and pitches")
    func angles() throws {
        let thirty = try #require(NaturalEntry.parse("30°", expecting: .angle)?.dimension)
        #expect(abs(thirty.value.doubleValue - 30) < 1e-9)
        let sevenTwelve = try #require(NaturalEntry.parse("7/12", expecting: .pitch)?.dimension)
        #expect(abs(sevenTwelve.value.doubleValue - 30.2564) < 0.001)
        let bare = try #require(NaturalEntry.parse("7", expecting: .pitch)?.dimension)
        #expect(bare == sevenTwelve)
        let grade = try #require(NaturalEntry.parse("58.78702%", expecting: .angle)?.dimension)
        #expect(abs(grade.value.doubleValue - 30.45) < 0.001)
        let bareAngle = try #require(NaturalEntry.parse("45", expecting: .angle)?.dimension)
        #expect(bareAngle.value == Fraction(45))
    }

    @Test("counts, percents, money, rejects")
    func others() {
        #expect(NaturalEntry.parse("84", expecting: .count) == .int(84))
        #expect(NaturalEntry.parse("8.5", expecting: .count) == nil)
        #expect(NaturalEntry.parse("10 %", expecting: .percent) == .number(Fraction(10)))
        #expect(NaturalEntry.parse("$1,250.50", expecting: .money) == .number(Fraction(125_050, 100)))
        #expect(NaturalEntry.parse("abc", expecting: .length) == nil)
        #expect(NaturalEntry.parse("", expecting: .length) == nil)
        #expect(NaturalEntry.parse("1/0", expecting: .length) == nil)
    }
}

private extension FieldValue {
    var dimension: Measure? {
        if case let .dimension(d) = self {
            return d
        }
        return nil
    }
}
