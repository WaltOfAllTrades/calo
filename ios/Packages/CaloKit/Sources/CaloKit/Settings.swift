import Foundation

/// Calo's settings (ontology #settings): one `Codable` struct with defaults, stored as JSON in
/// `UserDefaults` by `SettingsStore`. Missing keys decode to their defaults; unknown keys are ignored,
/// so adding a field later never breaks an older stored value (SPEC door-keeping 5).
public struct Settings: Codable, Hashable, Sendable {
    public static let targetRange = 0 ... 99999

    public var dailyTarget: Int
    public var showName: Bool
    public var showDetails: Bool

    public init(dailyTarget: Int = 2000, showName: Bool = false, showDetails: Bool = false) {
        self.dailyTarget = Self.targetRange.clamped(dailyTarget)
        self.showName = showName
        self.showDetails = showDetails
    }

    public static let defaults = Settings()

    private enum CodingKeys: String, CodingKey {
        case dailyTarget, showName, showDetails
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Settings.defaults
        self.init(
            dailyTarget: (try? container.decodeIfPresent(Int.self, forKey: .dailyTarget)) ?? defaults.dailyTarget,
            showName: (try? container.decodeIfPresent(Bool.self, forKey: .showName)) ?? defaults.showName,
            showDetails: (try? container.decodeIfPresent(Bool.self, forKey: .showDetails)) ?? defaults.showDetails
        )
    }

    /// True when either details field is shown (the web app's `has-details`; E-C11).
    public var showsAnyField: Bool {
        showName || showDetails
    }
}

private extension ClosedRange<Int> {
    func clamped(_ value: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

/// Reads and writes `Settings` as JSON under one key. The defaults suite is injectable for tests.
/// `UserDefaults` is thread-safe but not marked Sendable, hence the unchecked conformance.
public struct SettingsStore: @unchecked Sendable {
    public static let key = "calo.settings"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> Settings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(Settings.self, from: data)
        else { return .defaults }
        return settings
    }

    public func save(_ settings: Settings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
