import Foundation

/// An exact rational number: the calculator's arithmetic type end to end (code-standards 7). The
/// denominator is always positive and the pair is always reduced, so equal values compare equal.
/// Construction-calculator inputs are inches with a power-of-two denominator; the tape never sees a
/// floating-point error because none is ever introduced.
///
/// Arithmetic runs in 128-bit intermediates and reduces before narrowing back to `Int`; the checked
/// forms (`adding`, `multiplied(by:)`, `divided(by:)`) return nil when a value cannot be represented,
/// and the engine turns that into `tooLarge` (E-K10). Nothing reachable from the keypad traps.
public struct Fraction: Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
    public let numerator: Int
    public let denominator: Int

    /// Reduces and normalises the sign. A zero denominator is a programming error.
    public init(_ numerator: Int, _ denominator: Int = 1) {
        precondition(denominator != 0, "Fraction with zero denominator")
        let reduced = Self.reduce(Int128(numerator), Int128(denominator))
        self.numerator = Int(reduced.n)
        self.denominator = Int(reduced.d)
    }

    /// From 128-bit parts; nil when the reduced value does not fit `Int`.
    init?(wide numerator: Int128, _ denominator: Int128) {
        guard denominator != 0 else { return nil }
        let reduced = Self.reduce(numerator, denominator)
        guard let n = Int(exactly: reduced.n), let d = Int(exactly: reduced.d) else { return nil }
        self.numerator = n
        self.denominator = d
    }

    private static func reduce(_ n: Int128, _ d: Int128) -> (n: Int128, d: Int128) {
        let sign: Int128 = d < 0 ? -1 : 1
        let divisor = gcd(n.magnitude, d.magnitude)
        let g = divisor == 0 ? 1 : Int128(divisor)
        return (sign * n / g, sign * d / g)
    }

    /// Validates what comes off disk: a zero denominator is rejected, an unreduced pair repaired.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let n = try c.decode(Int.self, forKey: .numerator)
        let d = try c.decode(Int.self, forKey: .denominator)
        guard d != 0 else {
            throw DecodingError.dataCorruptedError(forKey: .denominator, in: c, debugDescription: "zero denominator")
        }
        self.init(n, d)
    }

    private enum CodingKeys: String, CodingKey {
        case numerator, denominator
    }

    public static let zero = Fraction(0)
    public static let one = Fraction(1)

    public var isZero: Bool {
        numerator == 0
    }

    public var isNegative: Bool {
        numerator < 0
    }

    public var isInteger: Bool {
        denominator == 1
    }

    public var magnitude: Fraction {
        Fraction(abs(numerator), denominator)
    }

    /// Whole part toward zero and the proper remainder, both carrying the sign of the value.
    public var whole: Int {
        numerator / denominator
    }

    public var remainder: Fraction {
        Fraction(numerator % denominator, denominator)
    }

    public var doubleValue: Double {
        Double(numerator) / Double(denominator)
    }

    public var description: String {
        denominator == 1 ? "\(numerator)" : "\(numerator)/\(denominator)"
    }

    // MARK: Checked arithmetic (the engine's path)

    public func adding(_ other: Fraction) -> Fraction? {
        let n = Int128(numerator) * Int128(other.denominator) + Int128(other.numerator) * Int128(denominator)
        return Fraction(wide: n, Int128(denominator) * Int128(other.denominator))
    }

    public func subtracting(_ other: Fraction) -> Fraction? {
        adding(-other)
    }

    public func multiplied(by other: Fraction) -> Fraction? {
        Fraction(wide: Int128(numerator) * Int128(other.numerator), Int128(denominator) * Int128(other.denominator))
    }

    /// Division by zero returns nil, as does an unrepresentable result.
    public func divided(by other: Fraction) -> Fraction? {
        guard !other.isZero else { return nil }
        return Fraction(
            wide: Int128(numerator) * Int128(other.denominator),
            Int128(denominator) * Int128(other.numerator)
        )
    }

    // MARK: Operators (formulas and tests; on overflow they approximate rather than trap)

    public static func + (lhs: Fraction, rhs: Fraction) -> Fraction {
        lhs.adding(rhs) ?? Fraction(approximating: lhs.doubleValue + rhs.doubleValue, denominator: 1024) ?? .zero
    }

    public static func - (lhs: Fraction, rhs: Fraction) -> Fraction {
        lhs.subtracting(rhs) ?? Fraction(approximating: lhs.doubleValue - rhs.doubleValue, denominator: 1024) ?? .zero
    }

    public static func * (lhs: Fraction, rhs: Fraction) -> Fraction {
        lhs
            .multiplied(by: rhs) ?? Fraction(approximating: lhs.doubleValue * rhs.doubleValue, denominator: 1024) ??
            .zero
    }

    public static func / (lhs: Fraction, rhs: Fraction) -> Fraction? {
        lhs.divided(by: rhs)
    }

    public static prefix func - (value: Fraction) -> Fraction {
        Fraction(-value.numerator, value.denominator)
    }

    public static func < (lhs: Fraction, rhs: Fraction) -> Bool {
        Int128(lhs.numerator) * Int128(rhs.denominator) < Int128(rhs.numerator) * Int128(lhs.denominator)
    }

    // MARK: Conversion

    /// The nearest fraction with the given denominator (ties round away from zero, as a tape reads).
    public func rounded(toDenominator target: Int) -> Fraction {
        precondition(target > 0)
        let scaled = Int128(numerator) * Int128(target)
        let d = Int128(denominator)
        let q = scaled / d
        let r = scaled % d
        let adjust: Int128 = r.magnitude * 2 >= d.magnitude ? (scaled < 0 ? -1 : 1) : 0
        return Fraction(wide: q + adjust, Int128(target)) ?? self
    }

    /// A double snapped to the nearest 1/`denominator`. Nil for NaN, infinity or a value beyond `Int`.
    /// Used only at the edges (trig, roots, metric).
    public init?(approximating value: Double, denominator: Int) {
        precondition(denominator > 0)
        let scaled = (value * Double(denominator)).rounded(.toNearestOrAwayFromZero)
        guard scaled.isFinite, abs(scaled) < 9.0e18 else { return nil }
        self.init(Int(scaled), denominator)
    }

    /// Parses a decimal string ("3.25", "-0.5", "7") exactly, as tenths/hundredths/… Never binary.
    /// Up to 9 decimals and 18 integer digits; longer input is rejected rather than trapped.
    public init?(decimalString raw: String) {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        let negative = text.hasPrefix("-")
        let body = negative ? String(text.dropFirst()) : text
        let parts = body.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, parts.allSatisfy({ $0.allSatisfy(\.isNumber) }) else { return nil }
        let wholeText = parts[0].isEmpty ? "0" : String(parts[0])
        let fracText = parts.count == 2 ? String(parts[1]) : ""
        guard wholeText.count <= 18, fracText.count <= 9, let whole = Int128(wholeText) else { return nil }
        var scale: Int128 = 1
        for _ in 0 ..< fracText.count {
            scale *= 10
        }
        let frac = fracText.isEmpty ? Int128(0) : (Int128(fracText) ?? 0)
        let n = whole * scale + frac
        self.init(wide: negative ? -n : n, scale)
    }

    static func gcd(_ a: UInt128, _ b: UInt128) -> UInt128 {
        var (a, b) = (a, b)
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return a
    }
}
