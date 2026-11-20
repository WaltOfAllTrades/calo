import SwiftUI

/// A number whose digits roll when it changes: the iOS answer to the web app's digit reels
/// (spec/design/liquid-glass.md → Components). Negative values use a real minus sign (U+2212) so
/// the glyph has the same width as a digit and reads as a sign, not a hyphen.
public struct RollingNumber: View {
    let value: Int
    let font: Font
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ value: Int, font: Font = Tokens.font.display) {
        self.value = value
        self.font = font
    }

    public var body: some View {
        Text(Self.text(for: value))
            .font(font)
            .contentTransition(.numericText(value: Double(value)))
            .motion(Motion.digitRoll, reduceMotion: reduceMotion, value: value)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }

    /// Grouped digits with a U+2212 sign when negative. Pure, so it is unit-tested.
    public nonisolated static func text(for value: Int, locale: Locale = .current) -> String {
        let magnitude = value.magnitude.formatted(.number.grouping(.automatic).locale(locale))
        return value < 0 ? "\u{2212}" + magnitude : magnitude
    }
}
