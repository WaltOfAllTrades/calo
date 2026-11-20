import CaloKit
import Foundation
import Observation
import OSLog
import SwiftUI

/// What the Calo screens need from outside: the store, the settings, and the clock. Built once at
/// launch from the process arguments, so the UI tests get an in-memory store and a pinned "now"
/// (`-calo.uitest`) and the app gets the real database.
@Observable
final class CaloEnvironment {
    let store: any LogStore
    let settingsStore: SettingsStore
    let calendar: Calendar
    let now: @Sendable () -> Date
    /// Set when the database could not be opened (E-C14): enter fails, nothing crashes.
    let storeError: (any Error)?

    init(store: any LogStore, settingsStore: SettingsStore, calendar: Calendar = .current,
         now: @escaping @Sendable () -> Date = { Date() }, storeError: (any Error)? = nil) {
        self.store = store
        self.settingsStore = settingsStore
        self.calendar = calendar
        self.now = now
        self.storeError = storeError
    }

    /// The pinned clock for UI tests: 2026-11-20 10:00 in the device zone (calo/tests.md).
    static let uiTestNow: Date = {
        var components = DateComponents(year: 2026, month: 11, day: 20, hour: 10)
        components.calendar = .current
        return components.date ?? Date()
    }()

    static func live() -> CaloEnvironment {
        do {
            let store = try GRDBLogStore(url: GRDBLogStore.defaultURL())
            return CaloEnvironment(store: store, settingsStore: SettingsStore())
        } catch {
            Logger(subsystem: "com.waltofalltrades.calo", category: "store").error("database unavailable")
            // A store that fails every write: the screen shows error.failed on enter (E-C14).
            let broken = MemoryLogStore(failsWrites: true)
            return CaloEnvironment(store: broken, settingsStore: SettingsStore(), storeError: error)
        }
    }

    /// `-calo.uitest`: memory store seeded with two entries for today, isolated settings, pinned clock.
    static func uiTest() -> CaloEnvironment {
        let now = uiTestNow
        let seed = [
            Entry(calories: 400, name: "Oatmeal", details: "with berries", createdAt: now.addingTimeInterval(-7200)),
            Entry(calories: -50, createdAt: now.addingTimeInterval(-3600)),
        ]
        let suite = UserDefaults(suiteName: "calo.uitest.\(UUID().uuidString)") ?? .standard
        return CaloEnvironment(
            store: MemoryLogStore(seed: seed), settingsStore: SettingsStore(defaults: suite),
            now: { now }
        )
    }

    static func fromProcess(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> CaloEnvironment {
        arguments.contains("-calo.uitest") ? uiTest() : live()
    }
}

extension EnvironmentValues {
    @Entry var calo: CaloEnvironment = .live()
}
