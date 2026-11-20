import Foundation

/// Display units (ontology #unit). Each linear unit has an exact factor to its kind's base
/// (inches, square inches, cubic inches); angle units convert through `AngleFormat`.
public enum DisplayUnit: String, Codable, CaseIterable, Sendable, Identifiable {
    case feetInches, decimalFeet, decimalInches, yards, millimetres, centimetres, metres
    case sqIn, sqFt, sqYd, sqM
    case cuIn, cuFt, cuYd, cuM, litres
    case degrees, pitch, grade, dms

    public var id: String {
        rawValue
    }

    public var kind: Measure.Kind {
        switch self {
        case .feetInches, .decimalFeet, .decimalInches, .yards, .millimetres, .centimetres, .metres: .length
        case .sqIn, .sqFt, .sqYd, .sqM: .area
        case .cuIn, .cuFt, .cuYd, .cuM, .litres: .volume
        case .degrees, .pitch, .grade, .dms: .angle
        }
    }

    /// 1 in = 25.4 mm exactly, so 1 mm = 5/127 in.
    static let inchesPerMillimetre = Fraction(5, 127)

    /// How many base units one of this unit is. Nil for angle units (not a linear factor).
    public var factor: Fraction? {
        let mm = Self.inchesPerMillimetre
        switch self {
        case .feetInches, .decimalFeet: return Fraction(12)
        case .decimalInches: return .one
        case .yards: return Fraction(36)
        case .millimetres: return mm
        case .centimetres: return mm * Fraction(10)
        case .metres: return mm * Fraction(1000)
        case .sqIn: return .one
        case .sqFt: return Fraction(144)
        case .sqYd: return Fraction(1296)
        case .sqM: return (mm * Fraction(1000)) * (mm * Fraction(1000))
        case .cuIn: return .one
        case .cuFt: return Fraction(1728)
        case .cuYd: return Fraction(46656)
        case .cuM: return (mm * Fraction(1000)) * (mm * Fraction(1000)) * (mm * Fraction(1000))
        case .litres: return (mm * Fraction(100)) * (mm * Fraction(100)) * (mm * Fraction(100))
        case .degrees, .pitch, .grade, .dms: return nil
        }
    }

    public var isMetric: Bool {
        switch self {
        case .millimetres, .centimetres, .metres, .sqM, .cuM, .litres: true
        default: false
        }
    }

    /// The chip's cycle for a kind, starting at the system's default (screens.md → unit chip).
    public static func cycle(for kind: Measure.Kind, system: UnitSystem) -> [DisplayUnit] {
        switch (kind, system) {
        case (.length, .imperial): [
                .feetInches,
                .decimalFeet,
                .decimalInches,
                .yards,
                .millimetres,
                .centimetres,
                .metres,
            ]
        case (.length, .metric): [.millimetres, .centimetres, .metres, .feetInches, .decimalFeet, .decimalInches]
        case (.area, .imperial): [.sqFt, .sqIn, .sqYd, .sqM]
        case (.area, .metric): [.sqM, .sqFt, .sqIn]
        case (.volume, .imperial): [.cuYd, .cuFt, .cuIn, .cuM, .litres]
        case (.volume, .metric): [.cuM, .litres, .cuYd, .cuFt]
        case (.angle, _): [.degrees, .pitch, .grade, .dms]
        case (.scalar, _): []
        }
    }

    public static func defaultUnit(for kind: Measure.Kind, system: UnitSystem) -> DisplayUnit? {
        cycle(for: kind, system: system).first
    }

    /// The next unit after `unit` in its cycle, wrapping.
    public static func next(after unit: DisplayUnit, system: UnitSystem) -> DisplayUnit {
        let cycle = cycle(for: unit.kind, system: system)
        guard let index = cycle.firstIndex(of: unit) else { return cycle.first ?? unit }
        return cycle[(index + 1) % cycle.count]
    }
}

/// Picks default units and the base unit for a bare number added to a length (E-K04).
public enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case imperial, metric

    /// What a bare number means next to a length: inches or millimetres.
    public var bareLengthUnit: DisplayUnit {
        self == .imperial ? .decimalInches : .millimetres
    }
}

/// Angle conversions (formulas.md §3.2): pitch is inches of rise per 12 of run; grade is percent.
public enum AngleFormat {
    /// Inches per 12 of run. Capped so a 90° angle (vertical) cannot overflow a fraction (E-K19).
    public static func pitch(fromDegrees degrees: Double) -> Double {
        min(max(12 * tan(degrees * .pi / 180), -1_000_000), 1_000_000)
    }

    public static func degrees(fromPitch pitch: Double) -> Double {
        atan(pitch / 12) * 180 / .pi
    }

    public static func grade(fromDegrees degrees: Double) -> Double {
        100 * tan(degrees * .pi / 180)
    }

    public static func degrees(fromGrade grade: Double) -> Double {
        atan(grade / 100) * 180 / .pi
    }

    /// Degrees, minutes, seconds for display (D27): 23.71° → "23°42′36″".
    public static func dms(_ degrees: Double) -> String {
        let sign = degrees < 0 ? "\u{2212}" : ""
        let total = Int((abs(degrees) * 3600).rounded())
        let minutes = String(format: "%02d", (total % 3600) / 60)
        let seconds = String(format: "%02d", total % 60)
        return "\(sign)\(total / 3600)°\(minutes)′\(seconds)″"
    }
}
