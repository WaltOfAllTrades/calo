import CalcKit
import DesignSystem
import SwiftUI

/// How a `Look` (SPEC choice 6, screens.md → Looks) maps to the backdrop, the key style and the
/// palettes. One value, read by the views; no look-specific view trees (SPEC door-keeping 7).
/// `classic` (default): keys that look and press like a real calculator. `glass`: system glass keys.
struct LookStyle {
    let look: Look

    /// Which key control the keypad uses.
    var usesGlassKeys: Bool {
        look == .glass
    }

    var keyShape: GlassKey.Shape {
        switch look {
        case .glass, .blueprint: .circle
        case .classic, .tape, .daylight: .roundedSquare
        }
    }

    var bevelShape: BevelKey.Shape {
        look == .blueprint ? .circle : .roundedSquare
    }

    var keyMinSize: CGFloat {
        look == .daylight ? Tokens.size.keyMin + 8 : Tokens.size.keyMin
    }

    var keyFont: Font {
        look == .daylight ? Tokens.font.key.weight(.bold) : Tokens.font.key.weight(.medium)
    }

    /// The accent used by the glass look's tinted keys.
    var accent: Color {
        switch look {
        case .classic, .glass: Tokens.color.calcAccent
        case .tape: Tokens.color.accent
        case .daylight: Color.primary
        case .blueprint: Color.white
        }
    }

    /// A key's role on the calculator keypad, for the palettes below.
    enum KeyRole {
        case digit, utility, operation, unit, equals
    }

    /// Palettes per look and role (BevelKey only).
    func palette(_ role: KeyRole, colorScheme: ColorScheme) -> BevelKey.Palette {
        switch look {
        case .daylight: daylightPalette(role, colorScheme: colorScheme)
        case .tape: tapePalette(role)
        case .blueprint: blueprintPalette(role)
        case .classic, .glass: classicPalette(role)
        }
    }

    /// Maximum contrast: ink on paper (or the reverse), heavy bases, colour only on equals.
    private func daylightPalette(_ role: KeyRole, colorScheme: ColorScheme) -> BevelKey.Palette {
        let ink: Color = colorScheme == .dark ? .white : .black
        let paper: Color = colorScheme == .dark ? .black : .white
        switch role {
        case .equals:
            return BevelKey.Palette(
                face: Tokens.color.calcKeyEquals,
                label: Tokens.color.calcKeyDarkLabel,
                base: Tokens.color.calcKeyEqualsBase
            )
        case .digit: return BevelKey.Palette(face: paper, label: ink, base: ink.opacity(0.6))
        default: return BevelKey.Palette(face: ink.opacity(0.1), label: ink, base: ink.opacity(0.6))
        }
    }

    private func tapePalette(_ role: KeyRole) -> BevelKey.Palette {
        switch role {
        case .digit: BevelKey.Palette(face: .white, label: Tokens.color.calcKeyDigitBase, base: Color(white: 0.75))
        case .utility: BevelKey.Palette(
                face: Color(white: 0.9),
                label: Tokens.color.calcKeyDigitBase,
                base: Color(white: 0.7)
            )
        case .operation, .equals: BevelKey.Palette(face: Tokens.color.accent, base: Tokens.color.calcKeyOperatorBase)
        case .unit: BevelKey.Palette(face: Tokens.color.calcKeyUnit, base: Tokens.color.calcKeyUnitBase)
        }
    }

    private func blueprintPalette(_ role: KeyRole) -> BevelKey.Palette {
        switch role {
        case .equals: BevelKey.Palette(face: .white, label: Tokens.color.calcKeyUnitBase, base: Color(white: 0.7))
        case .unit:
            BevelKey.Palette(
                face: Tokens.color.calcKeyEquals,
                label: Tokens.color.calcKeyDarkLabel,
                base: Tokens.color.calcKeyEqualsBase
            )
        default: BevelKey.Palette(face: Color.white.opacity(0.14), base: Color.black.opacity(0.35))
        }
    }

    private func classicPalette(_ role: KeyRole) -> BevelKey.Palette {
        switch role {
        case .digit: BevelKey.Palette(face: Tokens.color.calcKeyDigit, base: Tokens.color.calcKeyDigitBase)
        case .utility: BevelKey.Palette(face: Tokens.color.calcKeyUtility, base: Tokens.color.calcKeyUtilityBase)
        case .operation:
            BevelKey.Palette(
                face: Tokens.color.calcKeyOperator,
                label: Tokens.color.calcKeyDarkLabel,
                base: Tokens.color.calcKeyOperatorBase
            )
        case .unit: BevelKey.Palette(face: Tokens.color.calcKeyUnit, base: Tokens.color.calcKeyUnitBase)
        case .equals:
            BevelKey.Palette(
                face: Tokens.color.calcKeyEquals,
                label: Tokens.color.calcKeyDarkLabel,
                base: Tokens.color.calcKeyEqualsBase
            )
        }
    }

    @ViewBuilder
    var backdrop: some View {
        switch look {
        case .classic:
            CalcBackdrop(showsGrid: false)
        case .glass:
            CalcBackdrop(showsGrid: true)
        case .tape:
            Tokens.color.paper.opacity(0.95).ignoresSafeArea().accessibilityHidden(true)
        case .daylight:
            Color(uiColor: .systemBackground).ignoresSafeArea().accessibilityHidden(true)
        case .blueprint:
            ZStack {
                Color(red: 0x0B / 255, green: 0x3D / 255, blue: 0x91 / 255)
                CalcBackdrop(showsGrid: true).opacity(0.35)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }

    /// Tape and blueprint looks force their own scheme so text stays legible on paper and blue.
    var colorScheme: ColorScheme? {
        switch look {
        case .tape: .light
        case .blueprint: .dark
        case .classic, .glass, .daylight: nil
        }
    }
}
