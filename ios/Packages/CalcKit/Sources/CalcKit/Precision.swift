import Foundation

/// The display denominator (ontology #precision). Rounding is display-only (SPEC choice 4) and
/// `round(_:)` is the only rounding in the product (code-standards 5).
public enum Precision: Int, Codable, CaseIterable, Sendable, Identifiable {
    case half = 2, quarter = 4, eighth = 8, sixteenth = 16, thirtySecond = 32, sixtyFourth = 64
    case exact = 0

    public var id: Int {
        rawValue
    }

    public static let `default` = Precision.sixteenth

    /// The denominator used when a typed fraction has none (E-K05): exact falls back to 64.
    public var entryDenominator: Int {
        self == .exact ? 64 : rawValue
    }

    public func round(_ value: Fraction) -> Fraction {
        self == .exact ? value : value.rounded(toDenominator: rawValue)
    }

    /// The chip's cycle: 1/16 → 1/32 → 1/64 → exact → 1/2 → 1/4 → 1/8 → 1/16.
    public var next: Precision {
        switch self {
        case .sixteenth: .thirtySecond
        case .thirtySecond: .sixtyFourth
        case .sixtyFourth: .exact
        case .exact: .half
        case .half: .quarter
        case .quarter: .eighth
        case .eighth: .sixteenth
        }
    }

    /// "1/16" or "exact" (the latter localised by the caller).
    public var label: String? {
        self == .exact ? nil : "1/\(rawValue)"
    }
}

/// A formatted value and whether display rounding changed it (the chip's ≈, P-04).
public struct Formatted: Hashable, Sendable {
    public let text: String
    public let isRounded: Bool

    public init(_ text: String, isRounded: Bool = false) {
        self.text = text
        self.isRounded = isRounded
    }
}

/// The only formatter (SPEC door-keeping 3). Strings per formulas.md §5.
public enum Format {
    static let minus = "\u{2212}"

    public static func dimension(_ dimension: Measure, unit: DisplayUnit, precision: Precision,
                                 locale: Locale = .current) -> Formatted {
        switch unit {
        case .feetInches: return feetInches(dimension.value, precision: precision)
        case .decimalInches: return fractionalInches(dimension.value, precision: precision)
        case .degrees: return Formatted(decimal(dimension.value.doubleValue, fraction: 0 ... 2, locale: locale) + "°")
        case .pitch:
            let pitch = AngleFormat.pitch(fromDegrees: dimension.value.doubleValue)
            guard let exact = Fraction(approximating: pitch, denominator: 1024) else { return Formatted("—") }
            let snapped = precision.round(exact)
            let text = (snapped.isNegative ? minus : "") + mixedInches(snapped.magnitude, suffix: " " + suffix(.pitch))
            return Formatted(text, isRounded: snapped != exact)
        case .dms:
            return Formatted(AngleFormat.dms(dimension.value.doubleValue))
        case .grade:
            let grade = AngleFormat.grade(fromDegrees: dimension.value.doubleValue)
            return Formatted(decimal(grade, fraction: 0 ... 2, locale: locale) + " " + suffix(.grade))
        default:
            let value = dimension.doubleValue(in: unit)
            let text: String = unit.isMetric && unit.kind == .length
                ? decimal(value, fraction: 0 ... 3, locale: locale)
                : significant(value, locale: locale)
            // Rounded when the shown digits do not read back to the exact value (P-04).
            let shown = Fraction(decimalString: text.filter { $0.isNumber || $0 == "." || $0 == "-" }
                .replacingOccurrences(
                    of: "\u{2212}",
                    with: "-"
                ))
            let exact = dimension.converted(to: unit)
            let isRounded = shown != nil && exact != nil && shown != exact
            return Formatted(text + " " + suffix(unit), isRounded: isRounded)
        }
    }

    /// Scalars and counts: integers exactly, otherwise up to 7 significant digits.
    public static func scalar(_ value: Fraction, locale: Locale = .current) -> Formatted {
        if value.isInteger {
            return Formatted(value.numerator.formatted(.number.grouping(.automatic).locale(locale))
                .replacingOccurrences(
                    of: "-",
                    with: minus
                ))
        }
        let text = significant(value.doubleValue, locale: locale)
        let shown = Fraction(decimalString: text.filter { $0.isNumber || $0 == "." || $0 == "-" }.replacingOccurrences(
            of: "\u{2212}",
            with: "-"
        ))
        return Formatted(text, isRounded: shown != nil && shown != value)
    }

    /// `15′ 9-1/2″`, `0-45/64″`, `14′ 0″`, `3-1/2″`; negative with a leading minus.
    public static func feetInches(_ inches: Fraction, precision: Precision) -> Formatted {
        var magnitude = inches.magnitude
        let rounded = precision.round(magnitude)
        let isRounded = rounded != magnitude
        let negative = inches.isNegative && !rounded.isZero // never −0″
        magnitude = rounded
        var feet = magnitude.whole / 12
        var rest = magnitude - Fraction(feet * 12)
        if rest == Fraction(12) {
            feet += 1; rest = .zero
        }
        let inchText = mixedInches(rest, suffix: "″")
        let text = feet > 0 ? "\(feet)′ \(inchText)" : inchText
        return Formatted((negative ? minus : "") + text, isRounded: isRounded)
    }

    /// Inches only, as a mixed number: `63-1/2″`, `0-3/8″`.
    public static func fractionalInches(_ inches: Fraction, precision: Precision) -> Formatted {
        let negative = inches.isNegative
        let rounded = precision.round(inches.magnitude)
        return Formatted(
            (negative ? minus : "") + mixedInches(rounded, suffix: "″"),
            isRounded: rounded != inches.magnitude
        )
    }

    /// `3-1/2`, `0-45/64`, `9` with the suffix attached.
    static func mixedInches(_ value: Fraction, suffix: String) -> String {
        let whole = value.whole
        let rest = value.remainder.magnitude
        if rest.isZero {
            return "\(whole)\(suffix)"
        }
        return "\(whole)-\(rest.numerator)/\(rest.denominator)\(suffix)"
    }

    /// Seven significant digits, and never more than six decimals (the Construction Master's display:
    /// `15.79167`, `0.755208`, `195.8333`).
    static func significant(_ value: Double, locale: Locale) -> String {
        let style: FloatingPointFormatStyle<Double> = abs(value) < 1
            ? .number.precision(.fractionLength(0 ... 6))
            : .number.precision(.significantDigits(1 ... 7))
        return value.formatted(style.grouping(.automatic).locale(locale)).replacingOccurrences(of: "-", with: minus)
    }

    static func decimal(_ value: Double, fraction: ClosedRange<Int>, locale: Locale) -> String {
        value.formatted(.number.precision(.fractionLength(fraction)).grouping(.automatic).locale(locale))
            .replacingOccurrences(of: "-", with: minus)
    }

    // swiftlint:disable:next cyclomatic_complexity
    public static func suffix(_ unit: DisplayUnit) -> String {
        switch unit {
        case .feetInches: "ft-in"
        case .decimalFeet: "ft"
        case .decimalInches: "in"
        case .yards: "yd"
        case .millimetres: "mm"
        case .centimetres: "cm"
        case .metres: "m"
        case .sqIn: "sq in"
        case .sqFt: "sq ft"
        case .sqYd: "sq yd"
        case .sqM: "m²"
        case .cuIn: "cu in"
        case .cuFt: "cu ft"
        case .cuYd: "cu yd"
        case .cuM: "m³"
        case .litres: "L"
        case .degrees: "°"
        case .pitch: "in/12"
        case .grade: "% grade"
        case .dms: "d:m:s"
        }
    }

    /// Every unit of the dimension's kind with its text (the formats sheet, P-08).
    public static func formats(
        for dimension: Measure,
        system: UnitSystem,
        precision: Precision,
        locale: Locale = .current
    )
        -> [(unit: DisplayUnit, formatted: Formatted)] {
        DisplayUnit.cycle(for: dimension.kind, system: system).map { (
            $0,
            self.dimension(dimension, unit: $0, precision: precision, locale: locale)
        ) }
    }
}
