import Foundation

/// One measurement as typed (formulas.md §2): `5′ 3″ 1⁄2` (shown `5′ 3-1⁄2″`), `3.5′`, `44⁄64`,
/// `100′′` (square feet). The inch mark separates whole inches from a fraction, as on the
/// Construction Master; a fraction typed right after a foot mark has no whole inches (`5′ 3⁄4`).
public struct NumberToken: Hashable, Codable, Sendable {
    enum Slot: String, Codable, Sendable { case whole, numerator, denominator }

    /// Digits before the foot mark; whole inches; the fraction's halves. All as typed.
    public var feet: String?
    public var inches: String?
    public var numerator: String?
    public var denominator: String?
    /// The inch mark was pressed after the whole inches, or after the fraction.
    public var inchMark = false
    public var fractionClosed = false
    /// The numerator came straight from the whole slot (`5′ 3⁄4`), so backspace returns there.
    var numeratorFromWhole = false
    /// Digits being typed now, not yet assigned to a slot.
    var current = ""
    var slot = Slot.whole
    /// 1 = linear, 2 = square, 3 = cubic; set by repeated unit marks.
    public var power = 1
    public var negative = false
    /// Set at evaluation when a bare number was read as a length (E-K04): the mark the line shows.
    public var impliedUnit: DisplayUnit?

    public init() {}

    public var isEmpty: Bool {
        feet == nil && inches == nil && numerator == nil && denominator == nil && current.isEmpty && !inchMark
    }

    var hasUnitMark: Bool {
        feet != nil || inchMark
    }

    var hasFraction: Bool {
        numerator != nil || slot != .whole
    }

    var hasDecimal: Bool {
        (feet ?? "").contains(".") || (inches ?? "").contains(".") || current.contains(".")
    }

    var isPlainDigits: Bool {
        !hasUnitMark && !hasFraction && !negative
    }

    /// The text on the expression line, exactly as typed: `5′ 3″ 1⁄2` while the fraction is open,
    /// `5′ 3-1⁄2″` once it is closed, with the implied mark when one was given (E-K04).
    public var text: String {
        let feetMarks = ["", "′", "′′", "′′′"]
        let inchMarks = ["", "″", "″″", "″″″"]
        let mark = inchMarks[min(power, 3)]
        var parts: [String] = []
        if let feet {
            parts.append(feet + feetMarks[min(power, 3)])
        }
        var base = inches ?? ""
        if slot == .whole, !current.isEmpty {
            base += current
        }
        var fraction = ""
        if numerator != nil || slot != .whole {
            fraction = numerator ?? ""
            if slot == .numerator {
                fraction += current
            }
            if numerator != nil {
                fraction += "⁄" + (denominator ?? "")
            }
            if slot == .denominator {
                fraction += current
            }
        }
        var inchText: String = if fractionClosed {
            base + (base.isEmpty ? "" : "-") + fraction + mark
        } else if inchMark {
            base + mark + (fraction.isEmpty ? "" : " " + fraction)
        } else {
            base + (fraction.isEmpty || base.isEmpty ? "" : "-") + fraction
        }
        if !inchText.isEmpty {
            parts.append(inchText)
        }
        var text = parts.joined(separator: " ")
        if let impliedUnit, !hasUnitMark, !hasFraction {
            text += impliedUnit == .decimalInches ? "″" : " " + Format.suffix(impliedUnit)
        }
        return (negative ? Format.minus : "") + text
    }

    // swiftlint:disable cyclomatic_complexity
    /// The value. A fraction without a denominator uses `entryDenominator` (E-K05). Fractions are
    /// inches even without a mark (UG D2). A bare number is a scalar.
    func dimension(entryDenominator: Int) throws -> Measure {
        var wholeFeet = Fraction.zero
        var wholeInches = Fraction.zero
        var fraction = Fraction.zero
        if let feet {
            guard let f = Fraction(decimalString: feet) else { throw CalcError.incomplete }
            wholeFeet = f
        }
        let inchesText = inches ?? (slot == .whole ? current : "")
        if !inchesText.isEmpty {
            guard let i = Fraction(decimalString: inchesText) else { throw CalcError.incomplete }
            wholeInches = i
        }
        let numeratorText = numerator ?? (slot == .numerator ? current : "")
        if !numeratorText.isEmpty {
            // Digits after an inch mark that never got their bar are not a number yet.
            guard numerator != nil, let n = Int(numeratorText) else { throw CalcError.incomplete }
            let denominatorText = denominator ?? (slot == .denominator ? current : "")
            let d = Int(denominatorText) ?? entryDenominator
            guard d > 0 else { throw CalcError.divideByZero }
            fraction = Fraction(n, d)
        }
        let signed: (Fraction) -> Fraction = { negative ? -$0 : $0 }
        guard hasUnitMark || numerator != nil else {
            return Measure(signed(wholeInches), .scalar)
        }
        if power > 1 {
            // `100′′` is 100 square feet; `2″″` is 2 square inches.
            let feetBase = power == 2 ? Fraction(144) : Fraction(1728)
            guard let value = feet != nil ? wholeFeet.multiplied(by: feetBase) : wholeInches.adding(fraction) else {
                throw CalcError.tooLarge
            }
            return Measure(signed(value), power == 2 ? .area : .volume)
        }
        guard let feetInches = wholeFeet.multiplied(by: Fraction(12)), let whole = feetInches.adding(wholeInches),
              let total = whole.adding(fraction) else { throw CalcError.tooLarge }
        return Measure(signed(total), .length)
    }

    // swiftlint:enable cyclomatic_complexity
}
