import Foundation
import GRDB
import OSLog

/// Where entries live (SPEC door-keeping 2). One protocol, two implementations: GRDB on disk (or in
/// memory) for the app, and `MemoryLogStore` for tests and the UI-test launch. Every method takes
/// the day window it should look at, so "today" is decided once, by `DayWindow`, outside the store.
public protocol LogStore: Sendable {
    /// Adds an entry and returns it with its assigned id.
    @discardableResult
    func add(_ entry: Entry) async throws -> Entry
    /// Entries created inside the window, oldest first.
    func entries(in window: DayWindow) async throws -> [Entry]
    /// Logged and remaining for the window against the given target.
    func totals(in window: DayWindow, target: Int) async throws -> DashTotals
    /// Rewrites calories, name and details; sets `updatedAt` to `now`.
    func update(id: Int64, calories: Int, name: String, details: String, now: Date) async throws
    func delete(id: Int64) async throws
    /// Deletes every entry inside the window.
    func clear(in window: DayWindow) async throws
}

/// GRDB-backed store (architecture §3). `DatabaseQueue` is enough: one writer, short transactions.
public actor GRDBLogStore: LogStore {
    private let queue: DatabaseQueue

    /// Opens (and migrates) the database file at `url`, or an in-memory database when `url` is nil.
    public init(url: URL?) throws {
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            // Readable while the phone is locked after first unlock; the app never runs in the
            // background, so a stricter class would only add failure modes.
            if url != nil {
                try db.execute(sql: "PRAGMA journal_mode = WAL")
            }
        }
        if let url {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            queue = try DatabaseQueue(path: url.path, configuration: configuration)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
        } else {
            queue = try DatabaseQueue(configuration: configuration)
        }
        try Self.migrator.migrate(queue)
    }

    /// Index names in the schema, for the migration test (architecture §3 asks for `entry_createdAt`).
    public func indexNames() async throws -> [String] {
        try await queue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'entry'")
        }
    }

    /// The default on-device location: Application Support/calo.sqlite.
    public static func defaultURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("calo.sqlite")
    }

    /// Migrations are append-only: `v1` is never edited (architecture §3).
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "entry") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("calories", .integer).notNull()
                t.column("name", .text).notNull().defaults(to: "")
                t.column("details", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            try db.create(index: "entry_createdAt", on: "entry", columns: ["createdAt"])
        }
        return migrator
    }

    public func add(_ entry: Entry) async throws -> Entry {
        try await queue.write { db in
            var row = EntryRow(entry)
            try row.insert(db)
            return row.entry
        }
    }

    public func entries(in window: DayWindow) async throws -> [Entry] {
        try await queue.read { db in
            try EntryRow
                .filter(Column("createdAt") >= window.start && Column("createdAt") < window.end)
                .order(Column("createdAt"), Column("id"))
                .fetchAll(db)
                .map(\.entry)
        }
    }

    public func totals(in window: DayWindow, target: Int) async throws -> DashTotals {
        let logged = try await queue.read { db in
            try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(SUM(calories), 0) FROM entry WHERE createdAt >= ? AND createdAt < ?",
                arguments: [window.start, window.end]
            ) ?? 0
        }
        return DashTotals(logged: logged, target: target)
    }

    public func update(id: Int64, calories: Int, name: String, details: String, now: Date) async throws {
        let trimmed = Entry(calories: calories, name: name, details: details, createdAt: now)
        try await queue.write { db in
            try db.execute(
                sql: "UPDATE entry SET calories = ?, name = ?, details = ?, updatedAt = ? WHERE id = ?",
                arguments: [trimmed.calories, trimmed.name, trimmed.details, now, id]
            )
        }
    }

    public func delete(id: Int64) async throws {
        _ = try await queue.write { db in
            try EntryRow.deleteOne(db, key: id)
        }
    }

    public func clear(in window: DayWindow) async throws {
        _ = try await queue.write { db in
            try EntryRow
                .filter(Column("createdAt") >= window.start && Column("createdAt") < window.end)
                .deleteAll(db)
        }
    }
}

/// The table row. Kept apart from `Entry` so the domain type carries no GRDB conformances.
private struct EntryRow: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "entry"
    var id: Int64?
    var calories: Int
    var name: String
    var details: String
    var createdAt: Date
    var updatedAt: Date

    init(_ entry: Entry) {
        id = entry.id == 0 ? nil : entry.id
        calories = entry.calories
        name = entry.name
        details = entry.details
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    var entry: Entry {
        Entry(id: id ?? 0, calories: calories, name: name, details: details, createdAt: createdAt, updatedAt: updatedAt)
    }
}

/// In-memory store for tests and the `-calo.uitest` launch. Same contract, no database.
public actor MemoryLogStore: LogStore {
    private var rows: [Entry] = []
    private var nextId: Int64 = 1
    /// Set to make every write throw (E-C02 in tests).
    public var failsWrites = false

    public init(seed: [Entry] = [], failsWrites: Bool = false) {
        self.failsWrites = failsWrites
        for entry in seed {
            var copy = entry
            copy.id = nextId
            nextId += 1
            rows.append(copy)
        }
    }

    public func setFailsWrites(_ fails: Bool) {
        failsWrites = fails
    }

    public func add(_ entry: Entry) async throws -> Entry {
        try failIfAsked()
        var copy = entry
        copy.id = nextId
        nextId += 1
        rows.append(copy)
        return copy
    }

    public func entries(in window: DayWindow) async throws -> [Entry] {
        rows.filter { window.contains($0.createdAt) }
            .sorted { ($0.createdAt, $0.id) < ($1.createdAt, $1.id) }
    }

    public func totals(in window: DayWindow, target: Int) async throws -> DashTotals {
        let logged = try await entries(in: window).reduce(0) { $0 + $1.calories }
        return DashTotals(logged: logged, target: target)
    }

    public func update(id: Int64, calories: Int, name: String, details: String, now: Date) async throws {
        try failIfAsked()
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = Entry(calories: calories, name: name, details: details, createdAt: now)
        rows[index].calories = trimmed.calories
        rows[index].name = trimmed.name
        rows[index].details = trimmed.details
        rows[index].updatedAt = now
    }

    public func delete(id: Int64) async throws {
        try failIfAsked()
        rows.removeAll { $0.id == id }
    }

    public func clear(in window: DayWindow) async throws {
        try failIfAsked()
        rows.removeAll { window.contains($0.createdAt) }
    }

    private func failIfAsked() throws {
        if failsWrites {
            throw LogStoreError.writeFailed
        }
    }
}

public enum LogStoreError: Error, Sendable {
    case writeFailed
}
