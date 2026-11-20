import Foundation

/// One logged amount of calories (ontology #entry). `calories` is already signed: an add is positive,
/// a subtract negative. The sign rule lives in `Entry.Intent.signedCalories(_:)` and nowhere else
/// (code-standards 5).
public struct Entry: Identifiable, Hashable, Sendable, Codable {
    /// Whether the next entry adds or subtracts (ontology #entry.intent). Resets to `add` after enter.
    public enum Intent: String, Sendable, Codable, CaseIterable {
        case add, subtract

        /// The stored value for a typed magnitude. The only place the sign rule exists.
        public func signedCalories(_ magnitude: Int) -> Int {
            switch self {
            case .add: magnitude
            case .subtract: -magnitude
            }
        }
    }

    public var id: Int64
    public var calories: Int
    public var name: String
    public var details: String
    public var createdAt: Date
    public var updatedAt: Date

    /// Name and details are trimmed and never nil: the web app stored empty strings.
    public init(
        id: Int64 = 0, calories: Int, name: String = "", details: String = "",
        createdAt: Date, updatedAt: Date? = nil
    ) {
        self.id = id
        self.calories = calories
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

/// Logged and remaining for a day (ontology #dash). Computed, never stored.
public struct DashTotals: Hashable, Sendable {
    public let logged: Int
    public let target: Int

    public init(logged: Int, target: Int) {
        self.logged = logged
        self.target = target
    }

    /// May be negative; the dash shows a real minus sign (E-C06).
    public var remaining: Int {
        target - logged
    }
}
