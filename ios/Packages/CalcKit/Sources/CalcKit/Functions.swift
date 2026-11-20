import Foundation

/// A labelled input of a function (ontology #function.field).
public struct FunctionField: Hashable, Sendable, Identifiable {
    public enum Kind: String, Hashable, Sendable {
        case length, angle, count, percent, toggle, bagSize, money
    }

    public let id: String
    public let kind: Kind
    public let isRequired: Bool

    public init(_ id: String, _ kind: Kind, required: Bool = true) {
        self.id = id
        self.kind = kind
        isRequired = required
    }
}

/// A typed field value.
public enum FieldValue: Hashable, Sendable, Codable {
    case dimension(Measure)
    case number(Fraction)
    case toggle(Bool)
    case int(Int)

    var dimension: Measure? {
        if case let .dimension(d) = self {
            d
        } else {
            nil
        }
    }

    var number: Fraction? {
        switch self {
        case let .number(f): f
        case let .int(i): Fraction(i)
        case let .dimension(d): d.value
        case .toggle: nil
        }
    }

    var toggle: Bool? {
        if case let .toggle(b) = self {
            b
        } else {
            nil
        }
    }

    var int: Int? {
        switch self {
        case let .int(i): i
        case let .number(f): f.denominator == 1 ? f.numerator : nil
        default: nil
        }
    }
}

/// The values a function is solved with, by field id.
public struct FunctionInput: Hashable, Sendable {
    public var values: [String: FieldValue]

    public init(_ values: [String: FieldValue] = [:]) {
        self.values = values
    }

    public subscript(id: String) -> FieldValue? {
        get { values[id] }
        set { values[id] = newValue }
    }

    func length(_ id: String) -> Fraction? {
        guard let d = values[id]?.dimension, d.kind == .length else { return values[id]?.number }
        return d.value
    }

    func angleDegrees(_ id: String) -> Double? {
        guard let d = values[id]?.dimension, d.kind == .angle else { return values[id]?.number?.doubleValue }
        return d.value.doubleValue
    }
}

/// One labelled output (ontology #function.result). Counts and money are scalars with a style.
public struct FunctionResult: Hashable, Sendable, Identifiable {
    public enum Style: String, Hashable, Sendable {
        case dimension, count, money
    }

    public enum Warning: String, Hashable, Sendable {
        case riserOverLimit, treadUnderMinimum, headroomUnderMinimum
    }

    public let id: String
    public let value: Measure
    public let style: Style
    public let warning: Warning?
    /// A unit the result reads best in (riser heights in inches, not feet-inches); nil = the kind's default.
    public let displayUnit: DisplayUnit?

    public init(
        _ id: String, _ value: Measure, style: Style = .dimension, warning: Warning? = nil,
        displayUnit: DisplayUnit? = nil
    ) {
        self.id = id
        self.value = value
        self.style = style
        self.warning = warning
        self.displayUnit = displayUnit
    }

    /// Doubles from a formula snap to a fine grid; a non-finite or absurd value becomes zero rather
    /// than a trap (the caller guards the inputs that could produce one).
    public init(_ id: String, inches: Double, warning: Warning? = nil, inInches: Bool = false) {
        self.init(
            id, .inches(Fraction(approximating: inches, denominator: 1024) ?? .zero), warning: warning,
            displayUnit: inInches ? .decimalInches : nil
        )
    }

    public init(_ id: String, degrees: Double) {
        self.init(id, .degrees(Fraction(approximating: degrees, denominator: 10000) ?? .zero))
    }

    public init(_ id: String, count: Double, style: Style = .count) {
        self.init(id, .scalar(Fraction(approximating: count, denominator: 1_000_000) ?? .zero), style: style)
    }

    public init(_ id: String, squareInches: Double) {
        self.init(id, .squareInches(Fraction(approximating: squareInches, denominator: 1 << 20) ?? .zero))
    }

    public init(_ id: String, cubicInches: Double) {
        self.init(id, .cubicInches(Fraction(approximating: cubicInches, denominator: 4096) ?? .zero))
    }
}

/// One trade calculation (ontology #function; SPEC door-keeping 2). The registry is the one list the
/// Functions sheet renders; a new function is a new `static let` on its own type, added here.
public struct FunctionSpec: Sendable, Identifiable {
    public let id: String
    public let fields: [FunctionField]
    public let defaults: @Sendable (CalcPreferences) -> FunctionInput
    public let solve: @Sendable (FunctionInput, CalcPreferences) -> [FunctionResult]

    public static let registry: [FunctionSpec] = [
        Stairs.spec, Roof.spec, Concrete.spec, BoardFeet.spec, SquareUp.spec,
        CircleArc.spec, CompoundMiter.spec, Polygon.spec, Studs.spec,
    ]

    public static func named(_ id: String) -> FunctionSpec? {
        registry.first { $0.id == id }
    }

    /// True when every required field has a value.
    public func isComplete(_ input: FunctionInput) -> Bool {
        fields.allSatisfy { !$0.isRequired || input[$0.id] != nil }
    }
}

// MARK: - Shared helpers

enum Trig {
    static func rad(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    static func deg(_ radians: Double) -> Double {
        radians * 180 / .pi
    }

    /// Rounds a length to the display precision for use inside a formula (the UG does this for stairs).
    static func snapped(_ inches: Double, _ precision: Precision) -> Double {
        guard let exact = Fraction(approximating: inches, denominator: 1024) else { return inches }
        return precision.round(exact).doubleValue
    }
}

/// IRC limits the warnings check (formulas.md §3.1).
public enum CodeLimits {
    public static let maxRiser = Fraction(31, 4) // 7¾″ R311.7.5.1
    public static let minTread = Fraction(10) // R311.7.5.2
    public static let minHeadroom = Fraction(80) // 6′ 8″ R311.7.2
}
