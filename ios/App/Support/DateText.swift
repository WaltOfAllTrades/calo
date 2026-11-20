import Foundation

/// The one place dates and times become text (architecture §6). Calo's header has the web app's
/// three widths; the log has its time column.
enum DateText {
    static func headerFull(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    static func headerMedium(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.wide).day())
    }

    static func headerShort(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}
