import CaloKit
import DesignSystem
import SwiftUI

/// The 4×5 keypad (calo/screens.md → Main). Default: the web app's keys, faithfully (keyButton.css):
/// charcoal number keys, lighter bonus keys, dark-orange intent keys with the active one lit orange
/// inside a white outline, orange action keys, a soft gradient ring, a 90 ms press. Experiments →
/// Calo keys → Glass swaps in system glass keys. Keys are squares sized from the space given.
struct KeypadView: View {
    let keypad: KeypadModel
    @Environment(\.experiments) private var experiments
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let columns = 4
    private static let rows = 5

    var body: some View {
        GeometryReader { geo in
            let side = KeypadLayout.keySide(in: geo.size, rows: Self.rows, columns: Self.columns)
            grid(side: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .motion(Motion.intentSwitch, reduceMotion: reduceMotion, value: keypad.intent)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calo.keypad")
    }

    @ViewBuilder
    private func grid(side: CGFloat) -> some View {
        if experiments.current.caloKeys == .glass {
            GlassEffectContainer(spacing: Tokens.spacing.glassBlend) { rows(side: side) }
        } else {
            rows(side: side)
        }
    }

    private func rows(side: CGFloat) -> some View {
        VStack(spacing: Tokens.spacing.keyGap) {
            ForEach(0 ..< Self.rows, id: \.self) { row in
                HStack(spacing: Tokens.spacing.keyGap) {
                    ForEach(0 ..< Self.columns, id: \.self) { column in
                        let key = KeypadModel.Key.layout[row * Self.columns + column]
                        keyView(key)
                            .frame(width: side, height: side)
                            .accessibilityLabel(a11y(for: key))
                            .accessibilityIdentifier(identifier(for: key))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyView(_ key: KeypadModel.Key) -> some View {
        if experiments.current.caloKeys == .glass {
            GlassKey(label: label(for: key), symbol: symbol(for: key), role: glassRole(for: key)) { keypad.press(key) }
        } else {
            BevelKey(
                label: label(for: key),
                symbol: symbol(for: key),
                palette: palette(for: key),
                font: font(for: key)
            ) {
                keypad.press(key)
            }
        }
    }

    /// keyButton.css, variant by variant.
    private func palette(for key: KeypadModel.Key) -> BevelKey.Palette {
        switch key {
        case .digit: BevelKey.Palette(face: Tokens.color.caloKeyNumber, ring: true)
        case .bonus: BevelKey.Palette(face: Tokens.color.caloKeyBonus, ring: true)
        case .clear, .backspace, .enter: BevelKey.Palette(face: Tokens.color.accent, ring: true)
        case .add: intentPalette(active: keypad.intent == .add)
        case .subtract: intentPalette(active: keypad.intent == .subtract)
        }
    }

    /// The active intent key is lit orange inside a white outline; the other is the dark orange.
    private func intentPalette(active: Bool) -> BevelKey.Palette {
        if active {
            return BevelKey.Palette(face: Tokens.color.accent, outline: true)
        }
        return BevelKey.Palette(face: Tokens.color.caloKeyIntent, ring: true)
    }

    private func font(for key: KeypadModel.Key) -> Font {
        switch key {
        case .bonus: Tokens.font.keySecondary
        case .add, .subtract, .backspace, .enter: Tokens.font.key.weight(.semibold)
        default: Tokens.font.key
        }
    }

    private func label(for key: KeypadModel.Key) -> String? {
        switch key {
        case let .digit(text), let .bonus(text): text
        case .clear: String(localized: L10n.calo.keyClear)
        default: nil
        }
    }

    private func symbol(for key: KeypadModel.Key) -> String? {
        switch key {
        case .add: Symbols.plus
        case .subtract: Symbols.minus
        case .backspace: Symbols.backspace
        case .enter: Symbols.enter
        default: nil
        }
    }

    private func glassRole(for key: KeypadModel.Key) -> GlassKey.Role {
        switch key {
        case .digit: .plain
        case .bonus: .secondary
        case .clear, .backspace: .accent
        case .enter: .prominent
        case .add: keypad.intent == .add ? .prominent : .plain
        case .subtract: keypad.intent == .subtract ? .prominent : .plain
        }
    }

    private func a11y(for key: KeypadModel.Key) -> String {
        switch key {
        case let .digit(text), let .bonus(text): text
        case .add: String(localized: L10n.calo.a11yKeyAdd)
        case .subtract: String(localized: L10n.calo.a11yKeySubtract)
        case .clear: String(localized: L10n.calo.a11yKeyClear)
        case .backspace: String(localized: L10n.calo.a11yKeyBackspace)
        case .enter: String(localized: L10n.calo.a11yKeyEnter)
        }
    }

    private func identifier(for key: KeypadModel.Key) -> String {
        switch key {
        case let .digit(text), let .bonus(text): "calo.key.\(text)"
        case .add: "calo.key.plus"
        case .subtract: "calo.key.minus"
        case .clear: "calo.key.clear"
        case .backspace: "calo.key.backspace"
        case .enter: "calo.key.enter"
        }
    }
}
