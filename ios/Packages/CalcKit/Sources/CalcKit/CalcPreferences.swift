import Foundation

/// The calculator's visual option (ontology #look; SPEC choice 6).
public enum Look: String, Codable, CaseIterable, Sendable, Identifiable {
    case classic, glass, tape, daylight, blueprint

    public var id: String {
        rawValue
    }

    /// Classic: keys that look and press like a real calculator (Walt, 2026-11-20). Glass stays an option.
    public static let `default` = Look.classic
}

/// Settings (ontology #preferences): one `Codable` struct with defaults, JSON in UserDefaults.
/// Missing keys decode to defaults so new fields never break an older stored value.
public struct CalcPreferences: Codable, Hashable, Sendable {
    public var unitSystem: UnitSystem = .imperial
    public var precision: Precision = .default
    public var look: Look = .default
    /// Stairs defaults (UG p. 82): riser 7½″, tread 10″, headroom 6′ 8″, floor thickness 10″.
    public var desiredRiser = Fraction(15, 2)
    public var desiredTread = Fraction(10)
    public var headroom = Fraction(80)
    public var floorThickness = Fraction(10)
    public var riserLimited = false
    /// IRC R311.7.5.1 maximum riser.
    public var riserLimit = Fraction(31, 4)
    /// Concrete: NRMCA says 4–10 %; apps default to 10.
    public var wastePercent = 10
    public var bagPounds = 80
    /// Jack rafter and stud spacing on centre, inches.
    public var spacing = Fraction(16)

    public init() {}

    public static let defaults = CalcPreferences()

    private enum CodingKeys: String, CodingKey {
        case unitSystem, precision, look, desiredRiser, desiredTread, headroom, floorThickness
        case riserLimited, riserLimit, wastePercent, bagPounds, spacing
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CalcPreferences.defaults
        unitSystem = (try? c.decodeIfPresent(UnitSystem.self, forKey: .unitSystem)) ?? d.unitSystem
        precision = (try? c.decodeIfPresent(Precision.self, forKey: .precision)) ?? d.precision
        look = (try? c.decodeIfPresent(Look.self, forKey: .look)) ?? d.look
        desiredRiser = (try? c.decodeIfPresent(Fraction.self, forKey: .desiredRiser)) ?? d.desiredRiser
        desiredTread = (try? c.decodeIfPresent(Fraction.self, forKey: .desiredTread)) ?? d.desiredTread
        headroom = (try? c.decodeIfPresent(Fraction.self, forKey: .headroom)) ?? d.headroom
        floorThickness = (try? c.decodeIfPresent(Fraction.self, forKey: .floorThickness)) ?? d.floorThickness
        riserLimited = (try? c.decodeIfPresent(Bool.self, forKey: .riserLimited)) ?? d.riserLimited
        riserLimit = (try? c.decodeIfPresent(Fraction.self, forKey: .riserLimit)) ?? d.riserLimit
        wastePercent = (try? c.decodeIfPresent(Int.self, forKey: .wastePercent)) ?? d.wastePercent
        bagPounds = (try? c.decodeIfPresent(Int.self, forKey: .bagPounds)) ?? d.bagPounds
        spacing = (try? c.decodeIfPresent(Fraction.self, forKey: .spacing)) ?? d.spacing
    }

    /// Bag yields in cubic feet (QUIKRETE 1101): 80 lb 0.60, 60 lb 0.45, 50 lb 0.37, 40 lb 0.30.
    public static let bagYields: [Int: Fraction] = [
        80: Fraction(60, 100),
        60: Fraction(45, 100),
        50: Fraction(37, 100),
        40: Fraction(30, 100),
    ]
    public static let bagSizes = [40, 50, 60, 80]
}

/// Reads and writes `CalcPreferences` under one key. `UserDefaults` is thread-safe but not marked
/// Sendable, hence the unchecked conformance.
public struct CalcPreferencesStore: @unchecked Sendable {
    public static let key = "calc.preferences"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> CalcPreferences {
        guard let data = defaults.data(forKey: Self.key),
              let prefs = try? JSONDecoder().decode(CalcPreferences.self, from: data)
        else { return .defaults }
        return prefs
    }

    public func save(_ prefs: CalcPreferences) {
        if let data = try? JSONEncoder().encode(prefs) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
