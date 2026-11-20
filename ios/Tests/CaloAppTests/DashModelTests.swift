@testable import Calo
import CaloKit
import Foundation
import Testing

/// A clock the test can move.
final nonisolated class TestClock: @unchecked Sendable {
    var now: Date
    init(_ now: Date) {
        self.now = now
    }
}

/// The Dash's numbers and the day rollover (calo/tests.md → DashModelTests; E-C06, E-C07).
@MainActor
struct DashModelTests {
    private func environment(now: Date, entries: [Entry]) -> (CaloEnvironment, TestClock) {
        let clock = TestClock(now)
        let suite = UserDefaults(suiteName: "calo.dash.tests.\(UUID().uuidString)") ?? .standard
        let env = CaloEnvironment(
            store: MemoryLogStore(seed: entries), settingsStore: SettingsStore(defaults: suite),
            now: { clock.now }
        )
        return (env, clock)
    }

    private var tenAM: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 10))!
    }

    @Test("logged and remaining come from today's entries and the target")
    func totals() async {
        let (env, _) = environment(now: tenAM, entries: [
            Entry(calories: 400, createdAt: tenAM.addingTimeInterval(-3600)),
            Entry(calories: -50, createdAt: tenAM.addingTimeInterval(-60)),
            Entry(calories: 999, createdAt: tenAM.addingTimeInterval(-86400)),
        ])
        let dash = DashModel(env: env)
        await dash.refresh()
        #expect(dash.totals.logged == 350)
        #expect(dash.totals.remaining == 1650)
        dash.save(Settings(dailyTarget: 300))
        await dash.refresh()
        #expect(dash.totals.remaining == -50) // E-C06
    }

    @Test("a refresh after midnight moves the window and empties the numbers (E-C07)")
    func rollover() async {
        let (env, clock) = environment(now: tenAM, entries: [Entry(calories: 400, createdAt: tenAM)])
        let dash = DashModel(env: env)
        await dash.refresh()
        #expect(dash.totals.logged == 400)
        let before = dash.window
        clock.now = before.end.addingTimeInterval(60)
        await dash.refresh()
        #expect(dash.window != before)
        #expect(dash.window.start == before.end)
        #expect(dash.totals.logged == 0)
        #expect(dash.totals.remaining == 2000)
        dash.stopRollover()
    }
}
