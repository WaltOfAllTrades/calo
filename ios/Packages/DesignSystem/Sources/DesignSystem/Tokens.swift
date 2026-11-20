import SwiftUI

/// Design tokens (spec/design/liquid-glass.md → Tokens). Views reference these, never raw values
/// (code-standards 13). Lower-case namespaces are the spec's spelling: `Tokens.color.accent`.
public enum Tokens {
    public enum color {
        /// Calo's orange, from the web app (`--intent-active: #ff8a14`). Same in both appearances.
        public static let accent = Color(red: 1.0, green: 0x8A / 255, blue: 0x14 / 255)
        /// The calculator's tape yellow. Visual options may override it per screen.
        public static let calcAccent = Color.yellow
        public static let negative = Color.red
        public static let text = Color.primary
        public static let textFaint = Color.secondary
        /// The web app's night (`#020617`): Calo's dark background.
        public static let night = Color(red: 0x02 / 255, green: 0x06 / 255, blue: 0x17 / 255)
        /// Calo's light background: a cool off-white.
        public static let day = Color(red: 0xF4 / 255, green: 0xF5 / 255, blue: 0xF9 / 255)
        /// Calculator backdrop: graphite (dark) and warm paper (light).
        public static let graphite = Color(red: 0x1C / 255, green: 0x1D / 255, blue: 0x21 / 255)
        public static let paper = Color(red: 0xF6 / 255, green: 0xF1 / 255, blue: 0xE7 / 255)
        /// Opacity of the accent wash at the top of `CaloBackdrop`. Tuning value.
        public static let washOpacity = 0.12
        /// Opacity of the faint grid on `CalcBackdrop`. Tuning value.
        public static let gridOpacity = 0.04
    }

    public enum radius {
        public static let card: CGFloat = 20
        public static let field: CGFloat = 14
    }

    public enum size {
        /// Minimum tap target.
        public static let control: CGFloat = 44
        /// Keypad key diameter floor (P-07: gloves).
        public static let keyMin: CGFloat = 56
        public static let pillHeight: CGFloat = 44
        /// One inch of the calculator backdrop grid, in points. Tuning value.
        public static let gridCell: CGFloat = 24
    }

    public enum spacing {
        public static let screen: CGFloat = 16
        /// Gap between keypad keys. Tuning value.
        public static let keyGap: CGFloat = 10
        /// `GlassEffectContainer` spacing: how close two glass shapes must be to blend.
        public static let glassBlend: CGFloat = 4
        public static let stack: CGFloat = 12
    }

    public enum font {
        /// Dash numbers and the calculator display: rounded, monospaced digits.
        public static let display = Font.system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit()
        /// The dash when the details fields are visible (web `has-details`).
        public static let displayCompact = Font.system(.title, design: .rounded).weight(.semibold).monospacedDigit()
        /// Keypad labels. Capped at `.accessibility1` by `GlassKey` so the grid never scrolls (E-C15).
        public static let key = Font.system(.title2, design: .rounded).weight(.medium)
        public static let keySecondary = Font.system(.title3, design: .rounded).weight(.medium)
        public static let label = Font.footnote.weight(.medium)
        public static let intent = Font.callout.weight(.semibold)
        public static let buffer = Font.system(.title, design: .rounded).weight(.medium).monospacedDigit()
    }
}
