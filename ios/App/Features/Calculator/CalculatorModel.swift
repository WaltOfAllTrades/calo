import CalcKit
import DesignSystem
import Foundation
import Observation
import OSLog
import SwiftUI

/// What the calculator screens need from outside: the preferences store and the history files.
/// `-calc.uitest` gives an empty tape, default preferences and a scratch directory.
@Observable
final class CalcEnvironment {
    let preferences: CalcPreferencesStore
    let history: HistoryStore
    let now: @Sendable () -> Date

    init(preferences: CalcPreferencesStore, history: HistoryStore, now: @escaping @Sendable () -> Date = { Date() }) {
        self.preferences = preferences
        self.history = history
        self.now = now
    }

    static func live() -> CalcEnvironment {
        let directory = (try? HistoryStore.defaultDirectory())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("calc")
        return CalcEnvironment(preferences: CalcPreferencesStore(), history: HistoryStore(directory: directory))
    }

    static func uiTest() -> CalcEnvironment {
        let suite = UserDefaults(suiteName: "calc.uitest.\(UUID().uuidString)") ?? .standard
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("calc-uitest-\(UUID().uuidString)")
        return CalcEnvironment(
            preferences: CalcPreferencesStore(defaults: suite),
            history: HistoryStore(directory: directory)
        )
    }

    static func fromProcess(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> CalcEnvironment {
        arguments.contains("-calc.uitest") ? uiTest() : live()
    }
}

/// The calculator's screen model: wraps the `EntryEngine` value, the tape and the preferences, and
/// saves every change so a relaunch restores it all (P-05, P-06; E-K16). Formatting goes through
/// `Format` with the preferences' precision and the chip's unit.
@Observable
final class CalculatorModel {
    private(set) var engine = EntryEngine()
    private(set) var tape = Tape()
    private(set) var preferences = CalcPreferences.defaults
    private(set) var isRestored = false
    private let env: CalcEnvironment
    private let logger = Logger(subsystem: "com.waltofalltrades.calo", category: "calc")

    init(env: CalcEnvironment) {
        self.env = env
        preferences = env.preferences.load()
    }

    /// Loads the saved engine and tape before first render (K-022).
    func restore() async {
        guard !isRestored else { return }
        if let saved = await env.history.load(EntryEngine.self, named: HistoryStore.engineName) {
            engine = saved
        }
        if let saved = await env.history.load(Tape.self, named: HistoryStore.tapeName) {
            tape = saved
        }
        isRestored = true
    }

    // MARK: Derived display

    var result: Measure? {
        engine.result(precision: preferences.precision, system: preferences.unitSystem)
    }

    var displayUnit: DisplayUnit? {
        guard let result, result.kind != .scalar else { return nil }
        return engine.displayUnit ?? DisplayUnit.defaultUnit(for: result.kind, system: preferences.unitSystem)
    }

    /// The result text and whether rounding changed it (the chip's ≈).
    var formatted: Formatted? {
        guard let result else { return nil }
        if result.kind == .scalar {
            return Format.scalar(result.value)
        }
        guard let unit = displayUnit else { return nil }
        return Format.dimension(result, unit: unit, precision: preferences.precision)
    }

    var expressionText: String {
        engine.expressionText
    }

    var error: CalcError? {
        engine.error
    }

    var memory: Measure? {
        engine.memory
    }

    var canUndo: Bool {
        engine.canUndo
    }

    func formats() -> [(unit: DisplayUnit, formatted: Formatted)] {
        guard let result, result.kind != .scalar else { return [] }
        return Format.formats(for: result, system: preferences.unitSystem, precision: preferences.precision)
    }

    /// A tape line's result at the current precision and system (SPEC choice 4).
    func text(for line: TapeLine) -> String {
        if line.result.kind == .scalar {
            return Format.scalar(line.result.value).text
        }
        let unit = DisplayUnit.defaultUnit(for: line.result.kind, system: preferences.unitSystem) ?? .decimalInches
        return Format.dimension(line.result, unit: unit, precision: preferences.precision).text
    }

    // MARK: Actions

    func press(_ key: Key) {
        if let line = engine.press(
            key,
            precision: preferences.precision,
            system: preferences.unitSystem,
            now: env.now()
        ) {
            tape.append(line)
            persistTape()
        }
        persistEngine()
    }

    func insert(_ value: Measure) {
        engine.insert(value)
        persistEngine()
    }

    func cycleUnit() {
        guard let result, result.kind != .scalar else { return }
        engine.cycleUnit(system: preferences.unitSystem, kind: result.kind)
        persistEngine()
    }

    func cyclePrecision() {
        preferences.precision = preferences.precision.next
        save(preferences)
    }

    func deleteTapeLine(id: UUID) {
        tape.delete(id: id)
        persistTape()
    }

    func clearTape() {
        tape.clear()
        persistTape()
    }

    func save(_ preferences: CalcPreferences) {
        self.preferences = preferences
        env.preferences.save(preferences)
        if let unit = engine.displayUnit, unit.kind != result?.kind {
            engine.setDisplayUnit(nil)
        }
    }

    /// Saves are chained so an older snapshot can never overwrite a newer one (E-K16).
    private var saveChain: Task<Void, Never>?

    private func persistEngine() {
        let snapshot = engine
        enqueueSave { env in try await env.history.save(snapshot, as: HistoryStore.engineName) }
    }

    private func persistTape() {
        let snapshot = tape
        enqueueSave { env in try await env.history.save(snapshot, as: HistoryStore.tapeName) }
    }

    private func enqueueSave(_ work: @escaping @Sendable (CalcEnvironment) async throws -> Void) {
        let previous = saveChain
        let env = env
        let logger = logger
        saveChain = Task {
            await previous?.value
            do { try await work(env) } catch { logger.error("calc save failed") }
        }
    }
}

extension EnvironmentValues {
    @Entry var calc: CalcEnvironment = .live()
}
