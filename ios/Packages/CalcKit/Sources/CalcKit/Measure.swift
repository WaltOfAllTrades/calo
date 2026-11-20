import Foundation

/// Why an operation could not produce a value (ontology #engine.error). Shown in the result slot.
public enum CalcError: Error, Hashable, Sendable, Codable {
    case divideByZero
    case dimensionMismatch(Measure.Kind, Measure.Kind)
    case incomplete
    case tooLarge
}

/// A `Fraction` with a kind (ontology #dimension; named `Measure` in code because Foundation already
/// exports a `Dimension`, and `DisplayUnit` for #unit for the same reason). Lengths are inches, areas square inches,
/// volumes
/// cubic inches, angles degrees, scalars bare. Metric is exact because 1 in = 254/10 mm.
public struct Measure: Hashable, Sendable, Codable, CustomStringConvertible {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case scalar, length, area, volume, angle
    }

    public let value: Fraction
    public let kind: Kind

    public init(_ value: Fraction, _ kind: Kind) {
        self.value = value
        self.kind = kind
    }

    public static func scalar(_ value: Fraction) -> Measure {
        Measure(value, .scalar)
    }

    public static func inches(_ value: Fraction) -> Measure {
        Measure(value, .length)
    }

    public static func feet(_ value: Fraction) -> Measure {
        Measure(value * Fraction(12), .length)
    }

    /// Feet, inches and a fraction of an inch, all non-negative; the sign is applied to the whole.
    public static func feet(_ feet: Int, _ inches: Int = 0, _ fraction: Fraction = .zero,
                            negative: Bool = false) -> Measure {
        let total = Fraction(feet * 12 + inches) + fraction
        return Measure(negative ? -total : total, .length)
    }

    public static func squareInches(_ value: Fraction) -> Measure {
        Measure(value, .area)
    }

    public static func squareFeet(_ value: Fraction) -> Measure {
        Measure(value * Fraction(144), .area)
    }

    public static func cubicInches(_ value: Fraction) -> Measure {
        Measure(value, .volume)
    }

    public static func cubicFeet(_ value: Fraction) -> Measure {
        Measure(value * Fraction(1728), .volume)
    }

    public static func degrees(_ value: Fraction) -> Measure {
        Measure(value, .angle)
    }

    public var isZero: Bool {
        value.isZero
    }

    public var description: String {
        "\(value) \(kind.rawValue)"
    }

    /// The value in a unit, exactly, for linear units; angle units go through `AngleFormat`.
    public func converted(to unit: DisplayUnit) -> Fraction? {
        guard unit.kind == kind, let factor = unit.factor, let result = value / factor else { return nil }
        return result
    }

    public func doubleValue(in unit: DisplayUnit) -> Double {
        if let exact = converted(to: unit) {
            return exact.doubleValue
        }
        return value.doubleValue
    }

    // MARK: Algebra (formulas.md §1)

    public func adding(_ other: Measure) throws -> Measure {
        guard kind == other.kind else { throw CalcError.dimensionMismatch(kind, other.kind) }
        guard let sum = value.adding(other.value) else { throw CalcError.tooLarge }
        return Measure(sum, kind)
    }

    public func subtracting(_ other: Measure) throws -> Measure {
        try adding(Measure(-other.value, other.kind))
    }

    public func multiplied(by other: Measure) throws -> Measure {
        guard let kind = Kind.product(kind, other.kind) else { throw CalcError.dimensionMismatch(kind, other.kind) }
        guard let product = value.multiplied(by: other.value) else { throw CalcError.tooLarge }
        return Measure(product, kind)
    }

    public func divided(by other: Measure) throws -> Measure {
        guard !other.value.isZero else { throw CalcError.divideByZero }
        guard let kind = Kind.quotient(kind, other.kind) else { throw CalcError.dimensionMismatch(kind, other.kind) }
        guard let quotient = value.divided(by: other.value) else { throw CalcError.tooLarge }
        return Measure(quotient, kind)
    }

    public func scaled(by factor: Fraction) throws -> Measure {
        guard let product = value.multiplied(by: factor) else { throw CalcError.tooLarge }
        return Measure(product, kind)
    }

    public func negated() -> Measure {
        Measure(-value, kind)
    }

    /// The percent rules (UG p. 25): `x + p%`, `x − p%`, `x × p%`, `x ÷ p%`.
    public func applyingPercent(_ percent: Fraction, operation: Operation) throws -> Measure {
        let p = percent * Fraction(1, 100)
        switch operation {
        case .add: return try scaled(by: Fraction.one + p)
        case .subtract: return try scaled(by: Fraction.one - p)
        case .multiply: return try scaled(by: p)
        case .divide:
            guard !p.isZero, let inverse = Fraction.one / p else { throw CalcError.divideByZero }
            return try scaled(by: inverse)
        }
    }

    public enum Operation: String, Codable, Sendable, CaseIterable {
        case add, subtract, multiply, divide
    }
}

public extension Measure.Kind {
    /// What × gives: length² = area, area × length = volume, scalar leaves the other kind alone.
    static func product(_ a: Measure.Kind, _ b: Measure.Kind) -> Measure.Kind? {
        switch (a, b) {
        case let (.scalar, k), let (k, .scalar): k
        case (.length, .length): .area
        case (.length, .area), (.area, .length): .volume
        case (.angle, .angle): .scalar
        default: nil
        }
    }

    /// What ÷ gives: same kinds cancel to a scalar; volume ÷ area = length, and so on.
    static func quotient(_ a: Measure.Kind, _ b: Measure.Kind) -> Measure.Kind? {
        switch (a, b) {
        case let (k, .scalar): k
        case let (x, y) where x == y: .scalar
        case (.area, .length): .length
        case (.volume, .area): .length
        case (.volume, .length): .area
        default: nil
        }
    }
}
