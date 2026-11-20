import CalcKit
import DesignSystem
import SwiftUI

/// How a `Look` (SPEC choice 6, screens.md → Looks) maps to the backdrop, key shape and sizes.
/// One value, read by the views; no look-specific view trees (SPEC door-keeping 7).
struct LookStyle {
    let look: Look

    var keyShape: GlassKey.Shape {
        switch look {
        case .glass, .blueprint: .circle
        case .tape, .daylight: .roundedSquare
        }
    }

    var keyMinSize: CGFloat {
        look == .daylight ? Tokens.size.keyMin + 8 : Tokens.size.keyMin
    }

    var showsGrid: Bool {
        look == .glass || look == .blueprint
    }

    var keyFont: Font {
        look == .daylight ? Tokens.font.key.weight(.bold) : Tokens.font.key
    }

    /// The accent used by the tinted keys (′ ″ ⁄ and =).
    var accent: Color {
        switch look {
        case .glass: Tokens.color.calcAccent
        case .tape: Tokens.color.accent
        case .daylight: Color.primary
        case .blueprint: Color.white
        }
    }

    @ViewBuilder
    var backdrop: some View {
        switch look {
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
        case .glass, .daylight: nil
        }
    }
}
