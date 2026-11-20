import Foundation

/// Parses a measurement typed as text in a function field: `5' 3 1/2"`, `5′ 3-1/2″`, `63.5"`, `3.5'`,
/// `1500 mm`, `2.5 m`, `7` (bare: inches for lengths, degrees for angles, inches per 12 for pitch).
/// Same vocabulary as the keypad, so a value copied from the tape pastes back in.
public enum NaturalEntry {
    public enum Expecting: Sendable {
        case length, angle, pitch, count, percent, money
    }

    public static func parse(_ raw: String, expecting: Expecting = .length) -> FieldValue? {
        let text = raw
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "″", with: "\"")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "⁄", with: "/")
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
        guard !text.isEmpty else { return nil }
        switch expecting {
        case .count:
            return Int(text).map { .int($0) }
        case .percent:
            return Fraction(decimalString: text.replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespaces)).map { .number($0) }
        case .money:
            return Fraction(decimalString: text.replacingOccurrences(of: "$", with: "").replacingOccurrences(
                of: ",",
                with: ""
            )).map { .number($0) }
        case .angle:
            return angle(text, bareIsPitch: false).map { .dimension($0) }
        case .pitch:
            return angle(text, bareIsPitch: true).map { .dimension($0) }
        case .length:
            return length(text).map { .dimension($0) }
        }
    }

    /// `30°`, `30 deg`, `7/12`, `7:12`, `58.8%`, or a bare number (degrees, or in/12 for pitch fields).
    static func angle(_ text: String, bareIsPitch: Bool) -> Measure? {
        func degrees(_ value: Double) -> Measure {
            .degrees(Fraction(approximating: value, denominator: 10000) ?? .zero)
        }
        if text.hasSuffix("%") || text.hasSuffix("% grade") {
            let number = text.replacingOccurrences(of: "grade", with: "").replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Fraction(decimalString: number).map { degrees(AngleFormat.degrees(fromGrade: $0.doubleValue)) }
        }
        if text.hasSuffix("°") || text.hasSuffix("deg") {
            let number = text.replacingOccurrences(of: "deg", with: "").replacingOccurrences(of: "°", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Fraction(decimalString: number).map { degrees($0.doubleValue) }
        }
        let pitchParts = text.split(whereSeparator: { $0 == "/" || $0 == ":" })
        if pitchParts.count == 2, let rise = Fraction(decimalString: String(pitchParts[0])),
           let run = Fraction(decimalString: String(pitchParts[1])), !run.isZero {
            return degrees(AngleFormat.degrees(fromPitch: rise.doubleValue * 12 / run.doubleValue))
        }
        guard let number = Fraction(decimalString: text) else { return nil }
        return bareIsPitch ? degrees(AngleFormat.degrees(fromPitch: number.doubleValue)) : degrees(number.doubleValue)
    }

    /// Feet, inches and fractions in any usual spelling; metric with a unit suffix; bare = inches.
    static func length(_ text: String) -> Measure? {
        let metric: [(String, DisplayUnit)] = [
            ("mm", .millimetres),
            ("cm", .centimetres),
            ("m", .metres),
            ("yd", .yards),
            ("ft", .decimalFeet),
            ("in", .decimalInches),
        ]
        for (suffix, unit) in metric where text.hasSuffix(suffix) {
            let number = String(text.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            guard let value = Fraction(decimalString: number), let factor = unit.factor else { return nil }
            return .inches(value * factor)
        }
        var negative = false
        var body = text
        if body.hasPrefix("-") {
            negative = true; body.removeFirst()
        }
        var feet = Fraction.zero
        var rest = body
        if let quote = rest.firstIndex(of: "'") {
            guard let f = Fraction(decimalString: String(rest[..<quote]).trimmingCharacters(in: .whitespaces))
            else { return nil }
            feet = f
            rest = String(rest[rest.index(after: quote)...])
        }
        rest = rest.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
        var inches = Fraction.zero
        if !rest.isEmpty {
            // `3 1/2`, `3-1/2`, `1/2`, `3.5`
            let pieces = rest.replacingOccurrences(of: "-", with: " ").split(separator: " ").map(String.init)
            var whole: Fraction = .zero
            var fraction: Fraction = .zero
            for piece in pieces {
                if piece.contains("/") {
                    let halves = piece.split(separator: "/")
                    guard halves.count == 2, let n = Int(halves[0]), let d = Int(halves[1]), d > 0 else { return nil }
                    fraction = Fraction(n, d)
                } else {
                    guard let w = Fraction(decimalString: piece) else { return nil }
                    whole = w
                }
            }
            inches = whole + fraction
        }
        let total = feet * Fraction(12) + inches
        return .inches(negative ? -total : total)
    }
}
