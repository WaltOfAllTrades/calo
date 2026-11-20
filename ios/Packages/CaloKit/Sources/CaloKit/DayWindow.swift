import Foundation

/// The single definition of "today" (ontology #day-window, code-standards 5): the half-open interval
/// [start of the day containing `now`, start of the next day) in the given calendar and time zone.
/// `CaloKit` computes it, so the midnight rollover, the store queries and the pinned UI tests agree.
public struct DayWindow: Hashable, Sendable {
    public let start: Date
    public let end: Date

    public init(now: Date = Date(), calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: now)
        self.start = start
        // DST days are 23 or 25 hours long; the calendar, not arithmetic, finds the next midnight.
        end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    /// Date interval form, for queries.
    public var range: Range<Date> {
        start ..< end
    }

    /// When the next rollover fires: the window's end plus a small margin, as the web app did (E-C07).
    public var nextRollover: Date {
        end.addingTimeInterval(0.05)
    }
}
