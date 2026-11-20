import Foundation

/// Degrees, minutes, seconds (D27; UG pp. 78–81). Entry in the usual spellings and the two-digit display
/// the UG prints as `DMS 53.07.48`. Independent of `AngleFormat.dms`, which pads nothing.
public enum DMS {
    /// `23°42'39"`, `23°42′39″`, `23 42 39`, `23.42.39`, `42'`, `30°89'` (minutes over 59 carry, so
    /// 31°29′0″ per D27). A bare decimal (`23.71`) reads as degrees. Nil for anything else.
    public static func degrees(fromText raw: String) -> Double? {
        var text = normalised(raw)
        var sign = 1.0
        if text.hasPrefix("-") {
            sign = -1
            text.removeFirst()
        }
        guard !text.isEmpty, let parts = components(text), parts.count <= 3 else { return nil }
        var values: [Double] = []
        for part in parts {
            guard let value = Fraction(decimalString: part)?.doubleValue, value >= 0 else { return nil }
            values.append(value)
        }
        while values.count < 3 {
            values.append(0)
        }
        return sign * (values[0] + values[1] / 60 + values[2] / 3600)
    }

    /// `53°07′48″`: minutes and seconds always two digits, rounded to the nearest second.
    public static func text(_ degrees: Double) -> String {
        guard degrees.isFinite else { return "—" }
        let sign = degrees < 0 ? "\u{2212}" : ""
        let total = Int((abs(degrees) * 3600).rounded())
        return "\(sign)\(total / 3600)°\(padded((total % 3600) / 60))′\(padded(total % 60))″"
    }

    static func padded(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    /// Typographic marks become ASCII, the `DMS` prefix of a pasted display line drops, two apostrophes are
    /// seconds.
    static func normalised(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "dms", with: "")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "″", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "''", with: "\"")
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .trimmingCharacters(in: .whitespaces)
    }

    static let marks: [Character] = ["°", "'", "\""]

    /// The pieces in degree, minute, second order: by mark when any mark is present, else by spaces,
    /// else the UG's dotted `23.42.39`; a single piece is decimal degrees.
    static func components(_ text: String) -> [String]? {
        if text.contains(where: { marks.contains($0) }) {
            return markedComponents(text)
        }
        let spaced = text.split(separator: " ").map(String.init)
        if spaced.count > 1 {
            return spaced
        }
        let dotted = text.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        return dotted.count == 3 ? dotted : [text]
    }

    /// Each number takes the slot of the mark after it (`42'` is minutes); a trailing number with no mark
    /// takes the next slot (`23°42` is 23°42′). Marks out of order or without a number read as nothing.
    static func markedComponents(_ text: String) -> [String]? {
        var slots = ["0", "0", "0"]
        var next = 0
        var number = ""
        for character in text {
            guard let slot = marks.firstIndex(of: character) else {
                number.append(character)
                continue
            }
            let trimmed = number.trimmingCharacters(in: .whitespaces)
            guard slot >= next, !trimmed.isEmpty else { return nil }
            slots[slot] = trimmed
            next = slot + 1
            number = ""
        }
        let tail = number.trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty {
            guard next < slots.count else { return nil }
            slots[next] = tail
        }
        return slots
    }
}
