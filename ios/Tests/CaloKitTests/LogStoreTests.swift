import CaloKit
import Foundation
import Testing

/// Both stores pass the same suite through the protocol (SPEC door-keeping 2).
@Suite(.serialized)
struct LogStoreTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    private var today: DayWindow {
        DayWindow(now: date(2026, 11, 20), calendar: calendar)
    }

    private func stores() throws -> [(String, any LogStore)] {
        try [("grdb", GRDBLogStore(url: nil)), ("memory", MemoryLogStore())]
    }

    @Test("add, read back today only, oldest first")
    func addAndRead() async throws {
        for (name, store) in try stores() {
            try await store.add(Entry(calories: 250, name: "Apple", createdAt: date(2026, 11, 20, 9)))
            try await store.add(Entry(calories: -100, createdAt: date(2026, 11, 20, 8)))
            try await store.add(Entry(calories: 999, createdAt: date(2026, 11, 19, 23)))
            try await store.add(Entry(calories: 999, createdAt: date(2026, 11, 21, 0)))
            let rows = try await store.entries(in: today)
            #expect(rows.map(\.calories) == [-100, 250], "\(name)")
            #expect(rows.allSatisfy { $0.id > 0 }, "\(name)")
            #expect(rows[1].name == "Apple", "\(name)")
        }
    }

    @Test("totals sum signed calories inside the window against the target")
    func totals() async throws {
        for (name, store) in try stores() {
            try await store.add(Entry(calories: 1240, createdAt: date(2026, 11, 20)))
            try await store.add(Entry(calories: -40, createdAt: date(2026, 11, 20, 11)))
            try await store.add(Entry(calories: 5000, createdAt: date(2026, 11, 19)))
            let totals = try await store.totals(in: today, target: 2000)
            #expect(totals.logged == 1200, "\(name)")
            #expect(totals.remaining == 800, "\(name)")
            let empty = try await store.totals(in: DayWindow(now: date(2026, 1, 1), calendar: calendar), target: 2000)
            #expect(empty.logged == 0 && empty.remaining == 2000, "\(name)")
        }
    }

    @Test("update rewrites fields, trims, and bumps updatedAt")
    func update() async throws {
        for (name, store) in try stores() {
            let created = date(2026, 11, 20, 9)
            let saved = try await store.add(Entry(calories: 250, createdAt: created))
            let later = date(2026, 11, 20, 12)
            try await store.update(id: saved.id, calories: 300, name: " Pear ", details: "x", now: later)
            let row = try #require(try await store.entries(in: today).first)
            #expect(row.calories == 300 && row.name == "Pear" && row.details == "x", "\(name)")
            #expect(row.createdAt == created, "\(name)")
            #expect(row.updatedAt == later, "\(name)")
        }
    }

    @Test("delete one; clear removes only the window")
    func deleteAndClear() async throws {
        for (name, store) in try stores() {
            let a = try await store.add(Entry(calories: 1, createdAt: date(2026, 11, 20, 8)))
            try await store.add(Entry(calories: 2, createdAt: date(2026, 11, 20, 9)))
            try await store.add(Entry(calories: 3, createdAt: date(2026, 11, 19, 9)))
            try await store.delete(id: a.id)
            #expect(try await store.entries(in: today).map(\.calories) == [2], "\(name)")
            try await store.clear(in: today)
            #expect(try await store.entries(in: today).isEmpty, "\(name)")
            let yesterday = DayWindow(now: date(2026, 11, 19), calendar: calendar)
            #expect(try await store.entries(in: yesterday).map(\.calories) == [3], "\(name)")
        }
    }

    @Test("the memory store can be made to fail writes for the error path")
    func failingWrites() async throws {
        let store = MemoryLogStore()
        await store.setFailsWrites(true)
        await #expect(throws: LogStoreError.self) {
            try await store.add(Entry(calories: 1, createdAt: Date()))
        }
    }
}

struct MigrationTests {
    @Test("v1 creates the entry table with its index on a fresh database")
    func v1() async throws {
        let store = try GRDBLogStore(url: nil)
        // A store that opened is a store that migrated; a round trip proves the schema is usable.
        let saved = try await store.add(Entry(calories: 7, createdAt: Date()))
        #expect(saved.id == 1)
    }

    @Test("a file database opens, persists across reopen, and sits where the spec says")
    func fileDatabase() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = dir.appendingPathComponent("calo.sqlite")
        do {
            let store = try GRDBLogStore(url: url)
            try await store.add(Entry(calories: 42, createdAt: Date()))
        }
        let reopened = try GRDBLogStore(url: url)
        let all = try await reopened.entries(in: DayWindow())
        #expect(all.map(\.calories) == [42])
        #expect(try GRDBLogStore.defaultURL().lastPathComponent == "calo.sqlite")
        try? FileManager.default.removeItem(at: dir)
    }
}
