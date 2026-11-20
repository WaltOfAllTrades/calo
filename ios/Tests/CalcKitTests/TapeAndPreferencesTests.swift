import CalcKit
import Foundation
import Testing

struct TapeAndHistoryTests {
    private func line(_ n: Int) -> TapeLine {
        TapeLine(expression: "\(n)", result: .scalar(Fraction(n)), date: Date(timeIntervalSince1970: TimeInterval(n)))
    }

    @Test("newest first, capped at 200 (E-K14), delete and clear")
    func tape() {
        var tape = Tape()
        for n in 1 ... 205 {
            tape.append(line(n))
        }
        #expect(tape.lines.count == 200)
        #expect(tape.lines.first?.expression == "205")
        #expect(tape.lines.last?.expression == "6")
        let id = tape.lines[3].id
        tape.delete(id: id)
        #expect(tape.lines.count == 199)
        #expect(!tape.lines.contains { $0.id == id })
        tape.clear()
        #expect(tape.isEmpty)
    }

    @Test("the history store writes atomically and reloads the tape and an engine")
    func history() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = HistoryStore(directory: dir)
        var tape = Tape()
        tape.append(line(1))
        try await store.save(tape, as: HistoryStore.tapeName)
        var engine = EntryEngine()
        engine.press(.digit(4), precision: .sixteenth, system: .imperial)
        engine.press(.feet, precision: .sixteenth, system: .imperial)
        try await store.save(engine, as: HistoryStore.engineName)
        let loadedTape = await store.load(Tape.self, named: HistoryStore.tapeName)
        #expect(loadedTape == tape)
        let loadedEngine = await store.load(EntryEngine.self, named: HistoryStore.engineName)
        #expect(loadedEngine == engine)
        #expect(await store.load(Tape.self, named: "missing") == nil)
        #expect(try HistoryStore.defaultDirectory().lastPathComponent == "calc")
        try? FileManager.default.removeItem(at: dir)
    }
}

struct PreferencesTests {
    @Test("defaults match the ontology")
    func defaults() {
        let p = CalcPreferences.defaults
        #expect(p.unitSystem == .imperial)
        #expect(p.precision == .sixteenth)
        #expect(p.look == .glass)
        #expect(p.desiredRiser == Fraction(15, 2))
        #expect(p.desiredTread == Fraction(10))
        #expect(p.headroom == Fraction(80))
        #expect(p.floorThickness == Fraction(10))
        #expect(p.riserLimited == false)
        #expect(p.riserLimit == Fraction(31, 4))
        #expect(p.wastePercent == 10)
        #expect(p.bagPounds == 80)
        #expect(p.spacing == Fraction(16))
        #expect(CalcPreferences.bagYields[80] == Fraction(3, 5))
    }

    @Test("missing and unknown keys decode to defaults; the store round-trips")
    func decoding() throws {
        let partial = Data(#"{"look": "daylight", "future": 1}"#.utf8)
        let p = try JSONDecoder().decode(CalcPreferences.self, from: partial)
        #expect(p.look == .daylight)
        #expect(p.precision == .sixteenth)
        let suite = try #require(UserDefaults(suiteName: "calc.tests.\(UUID().uuidString)"))
        let store = CalcPreferencesStore(defaults: suite)
        #expect(store.load() == .defaults)
        var changed = CalcPreferences()
        changed.unitSystem = .metric
        changed.precision = .exact
        store.save(changed)
        #expect(store.load() == changed)
    }
}
