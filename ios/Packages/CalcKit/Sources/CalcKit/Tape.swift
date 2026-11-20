import Foundation

/// The last 200 results (ontology #tape), newest first. Persisted by `HistoryStore` (P-05, P-06).
public struct Tape: Hashable, Codable, Sendable {
    public static let capacity = 200
    public private(set) var lines: [TapeLine] = []

    public init(lines: [TapeLine] = []) {
        self.lines = Array(lines.prefix(Self.capacity))
    }

    public var isEmpty: Bool {
        lines.isEmpty
    }

    /// Newest first; the oldest line drops when the tape is full (E-K14).
    public mutating func append(_ line: TapeLine) {
        lines.insert(line, at: 0)
        if lines.count > Self.capacity {
            lines.removeLast(lines.count - Self.capacity)
        }
    }

    public mutating func delete(id: UUID) {
        lines.removeAll { $0.id == id }
    }

    public mutating func clear() {
        lines.removeAll()
    }
}

/// Atomic JSON files in Application Support (SPEC door-keeping 5). Generic over the value so the
/// tape and the engine snapshot share one writer. The directory is injectable for tests.
public actor HistoryStore {
    private let directory: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public init(directory: URL) {
        self.directory = directory
    }

    public static func defaultDirectory() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("calc", isDirectory: true)
    }

    public func save(_ value: some Encodable, as name: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(value)
        try data.write(
            to: directory.appendingPathComponent(name + ".json"),
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    public func load<T: Decodable>(_ type: T.Type, named name: String) -> T? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(name + ".json")) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    public static let tapeName = "tape"
    public static let engineName = "engine"
}
