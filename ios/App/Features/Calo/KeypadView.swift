import CaloKit
import DesignSystem
import SwiftUI

/// The 4×5 keypad (calo/screens.md → Main). One `GlassEffectContainer` so neighbouring keys blend;
/// roles per the spec: digits plain, bonus secondary, C and ⌫ accent, Enter and the active intent
/// prominent. Keys are squares sized from the space the screen gives the keypad (`KeypadLayout`).
struct KeypadView: View {
    let keypad: KeypadModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let columns = 4
    private static let rows = 5

    var body: some View {
        GeometryReader { geo in
            let side = KeypadLayout.keySide(in: geo.size, rows: Self.rows, columns: Self.columns)
            GlassEffectContainer(spacing: Tokens.spacing.glassBlend) {
                VStack(spacing: Tokens.spacing.keyGap) {
                    ForEach(0 ..< Self.rows, id: \.self) { row in
                        HStack(spacing: Tokens.spacing.keyGap) {
                            ForEach(0 ..< Self.columns, id: \.self) { column in
                                let key = KeypadModel.Key.layout[row * Self.columns + column]
                                GlassKey(
                                    label: label(for: key), symbol: symbol(for: key), role: role(for: key),
                                    action: { keypad.press(key) }
                                )
                                .frame(width: side, height: side)
                                .accessibilityLabel(a11y(for: key))
                                .accessibilityIdentifier(identifier(for: key))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .motion(Motion.intentSwitch, reduceMotion: reduceMotion, value: keypad.intent)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calo.keypad")
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

    private func role(for key: KeypadModel.Key) -> GlassKey.Role {
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
