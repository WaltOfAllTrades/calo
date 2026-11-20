import CalcKit
import Testing

struct FractionTests {
    @Test("fractions reduce and normalise their sign")
    func normalisation() {
        #expect(Fraction(6, 8) == Fraction(3, 4))
        #expect(Fraction(3, -4).numerator == -3)
        #expect(Fraction(3, -4).denominator == 4)
        #expect(Fraction(0, 5) == .zero)
        #expect(Fraction(-0, 5).denominator == 1)
    }

    @Test("exact arithmetic on tape values")
    func arithmetic() {
        // 5' 3-1/2" + 2' 9-3/4" in inches: 63.5 + 33.75 = 97.25 = 8' 1-1/4"
        let a = Fraction(127, 2)
        let b = Fraction(135, 4)
        #expect(a + b == Fraction(389, 4))
        #expect(a - b == Fraction(119, 4))
        #expect(Fraction(1, 3) * Fraction(3, 1) == .one)
        #expect(Fraction(1, 2) / Fraction(1, 4) == Fraction(2))
        #expect(Fraction(1, 2) / .zero == nil)
        #expect(-Fraction(1, 2) == Fraction(-1, 2))
    }

    @Test("whole and remainder carry the sign")
    func parts() {
        let v = Fraction(-389, 4) // -97.25
        #expect(v.whole == -97)
        #expect(v.remainder == Fraction(-1, 4))
        #expect(Fraction(7, 2).whole == 3)
        #expect(Fraction(7, 2).remainder == Fraction(1, 2))
    }

    @Test("rounding to a tape denominator, ties away from zero")
    func rounding() {
        #expect(Fraction(1, 3).rounded(toDenominator: 16) == Fraction(5, 16))
        #expect(Fraction(1, 32).rounded(toDenominator: 16) == Fraction(1, 16))
        #expect(Fraction(-1, 32).rounded(toDenominator: 16) == Fraction(-1, 16))
        #expect(Fraction(approximating: 0.3333, denominator: 64) == Fraction(21, 64))
    }

    @Test("decimal strings parse exactly", arguments: [
        ("3.25", Fraction(13, 4)), ("-0.5", Fraction(-1, 2)), ("7", Fraction(7)),
        (".125", Fraction(1, 8)), ("10.", Fraction(10)),
    ])
    func decimal(text: String, expected: Fraction) {
        #expect(Fraction(decimalString: text) == expected)
    }

    @Test("bad decimal strings are rejected", arguments: ["", "1.2.3", "abc", "1,5"])
    func badDecimal(text: String) {
        #expect(Fraction(decimalString: text) == nil)
    }

    @Test("ordering and description")
    func ordering() {
        #expect(Fraction(1, 3) < Fraction(1, 2))
        #expect(Fraction(-1, 2) < .zero)
        #expect(Fraction(3, 4).description == "3/4")
        #expect(Fraction(8, 4).description == "2")
    }
}
