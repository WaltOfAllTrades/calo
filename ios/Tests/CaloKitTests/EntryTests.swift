import CaloKit
import Foundation
import Testing

struct EntryTests {
    @Test("the sign rule: add is positive, subtract negative")
    func signedCalories() {
        #expect(Entry.Intent.add.signedCalories(250) == 250)
        #expect(Entry.Intent.subtract.signedCalories(250) == -250)
        #expect(Entry.Intent.subtract.signedCalories(0) == 0)
    }

    @Test("name and details are trimmed and never nil")
    func trimming() {
        let entry = Entry(calories: 10, name: "  Apple \n", details: "\t", createdAt: Date())
        #expect(entry.name == "Apple")
        #expect(entry.details == "")
        #expect(entry.updatedAt == entry.createdAt)
    }

    @Test("remaining is target minus logged and may go negative")
    func totals() {
        #expect(DashTotals(logged: 1240, target: 2000).remaining == 760)
        #expect(DashTotals(logged: 2300, target: 2000).remaining == -300)
    }
}

struct DayWindowTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    @Test("the window is [midnight, next midnight) in the given zone")
    func bounds() {
        let window = DayWindow(now: date(2026, 11, 20, 10, 0), calendar: calendar)
        #expect(window.start == date(2026, 11, 20))
        #expect(window.end == date(2026, 11, 21))
        #expect(window.contains(date(2026, 11, 20, 23, 59, 59)))
        #expect(!window.contains(date(2026, 11, 21)))
        #expect(!window.contains(date(2026, 11, 19, 23, 59, 59)))
    }

    @Test("a 25-hour DST day still ends at the next midnight")
    func dstFallBack() {
        // 2026-11-01 is the US fall-back day in America/New_York.
        let window = DayWindow(now: date(2026, 11, 1, 12, 0), calendar: calendar)
        #expect(window.end == date(2026, 11, 2))
        #expect(window.end.timeIntervalSince(window.start) == 25 * 3600)
    }

    @Test("the next rollover is just after the window ends")
    func rollover() {
        let window = DayWindow(now: date(2026, 11, 20, 10, 0), calendar: calendar)
        #expect(window.nextRollover > window.end)
        #expect(window.nextRollover.timeIntervalSince(window.end) < 1)
    }
}

struct SettingsTests {
    @Test("defaults match the web app")
    func defaults() {
        let s = Settings.defaults
        #expect(s.dailyTarget == 2000)
        #expect(s.showName == false)
        #expect(s.showDetails == false)
        #expect(s.showsAnyField == false)
    }

    @Test("missing and unknown keys decode to defaults")
    func decoding() throws {
        let partial = Data(#"{"showName": true, "someFutureKey": 3}"#.utf8)
        let s = try JSONDecoder().decode(Settings.self, from: partial)
        #expect(s.showName == true)
        #expect(s.dailyTarget == 2000)
        #expect(s.showsAnyField)
    }

    @Test("the target is clamped to 0…99999")
    func clamping() {
        #expect(Settings(dailyTarget: -5).dailyTarget == 0)
        #expect(Settings(dailyTarget: 1_000_000).dailyTarget == 99999)
    }

    @Test("the store round-trips through an isolated defaults suite")
    func store() throws {
        let suite = try #require(UserDefaults(suiteName: "calo.tests.\(UUID().uuidString)"))
        let store = SettingsStore(defaults: suite)
        #expect(store.load() == .defaults)
        store.save(Settings(dailyTarget: 1500, showName: true, showDetails: false))
        #expect(store.load() == Settings(dailyTarget: 1500, showName: true, showDetails: false))
    }
}
