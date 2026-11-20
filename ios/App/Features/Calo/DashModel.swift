import CaloKit
import Foundation
import Observation

/// Today's numbers (ontology #dash) and the day itself (ontology #day-window). Owns the rollover:
/// at the window's end, and whenever the app returns to the foreground on a new day, the window and
/// the totals recompute (E-C07, E-C08). Settings are read here too so the target is always current.
@Observable
final class DashModel {
    private(set) var window: DayWindow
    private(set) var totals = DashTotals(logged: 0, target: Settings.defaults.dailyTarget)
    private(set) var settings: Settings
    private let env: CaloEnvironment
    private var rolloverTask: Task<Void, Never>?

    init(env: CaloEnvironment) {
        self.env = env
        window = DayWindow(now: env.now(), calendar: env.calendar)
        settings = env.settingsStore.load()
    }

    /// Re-reads settings, recomputes the window for `now`, and reloads the totals.
    func refresh() async {
        settings = env.settingsStore.load()
        let current = DayWindow(now: env.now(), calendar: env.calendar)
        if current != window {
            window = current
        }
        if let fresh = try? await env.store.totals(in: window, target: settings.dailyTarget) {
            totals = fresh
        } else {
            totals = DashTotals(logged: totals.logged, target: settings.dailyTarget)
        }
        armRollover()
    }

    /// Cancels the midnight timer (the screen is going away).
    func stopRollover() {
        rolloverTask?.cancel()
        rolloverTask = nil
    }

    isolated deinit {
        rolloverTask?.cancel()
    }

    func save(_ settings: Settings) {
        env.settingsStore.save(settings)
        self.settings = settings
    }

    /// A timer for the next midnight plus the web app's 50 ms margin; re-armed after each refresh.
    private func armRollover() {
        rolloverTask?.cancel()
        let delay = window.nextRollover.timeIntervalSince(env.now())
        guard delay > 0 else { return }
        rolloverTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }
}
