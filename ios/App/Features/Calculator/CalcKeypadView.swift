import CalcKit
import DesignSystem
import SwiftUI

/// The 5×5 keypad (calculator/screens.md → Main) with hold-to-see help on every key (K-021, P-03).
struct CalcKeypadView: View {
    let model: CalculatorModel
    let style: LookStyle
    @State private var helpKey: KeyLayout?

    /// Keys in grid order with their identifiers and help keys.
    struct KeyLayout: Identifiable, Hashable {
        let key: Key
        let id: String
        let label: String?
        let symbol: String?
        let role: GlassKey.Role
        let help: LocalizedStringResource

        /// The help resource is not Hashable; identity is the id.
        static func == (lhs: KeyLayout, rhs: KeyLayout) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private static let digitHelp = L10n.calc.helpKeyDigit

    static let layout: [KeyLayout] = [
        KeyLayout(
            key: .allClear,
            id: "allClear",
            label: "AC",
            symbol: nil,
            role: .secondary,
            help: L10n.calc.helpKeyAllClear
        ),
        KeyLayout(
            key: .backspace,
            id: "backspace",
            label: nil,
            symbol: Symbols.backspace,
            role: .secondary,
            help: L10n.calc.helpKeyBackspace
        ),
        KeyLayout(key: .open, id: "open", label: "(", symbol: nil, role: .secondary, help: L10n.calc.helpKeyOpen),
        KeyLayout(key: .close, id: "close", label: ")", symbol: nil, role: .secondary, help: L10n.calc.helpKeyClose),
        KeyLayout(key: .divide, id: "divide", label: "÷", symbol: nil, role: .secondary, help: L10n.calc.helpKeyDivide),
        KeyLayout(key: .digit(7), id: "7", label: "7", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .digit(8), id: "8", label: "8", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .digit(9), id: "9", label: "9", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .times, id: "times", label: "×", symbol: nil, role: .secondary, help: L10n.calc.helpKeyTimes),
        KeyLayout(key: .feet, id: "feet", label: "′", symbol: nil, role: .accent, help: L10n.calc.helpKeyFeet),
        KeyLayout(key: .digit(4), id: "4", label: "4", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .digit(5), id: "5", label: "5", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .digit(6), id: "6", label: "6", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .minus, id: "minus", label: "−", symbol: nil, role: .secondary, help: L10n.calc.helpKeyMinus),
        KeyLayout(key: .inches, id: "inches", label: "″", symbol: nil, role: .accent, help: L10n.calc.helpKeyInches),
        KeyLayout(key: .digit(1), id: "1", label: "1", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .digit(2), id: "2", label: "2", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .digit(3), id: "3", label: "3", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .plus, id: "plus", label: "+", symbol: nil, role: .secondary, help: L10n.calc.helpKeyPlus),
        KeyLayout(
            key: .fractionBar,
            id: "fraction",
            label: "⁄",
            symbol: nil,
            role: .accent,
            help: L10n.calc.helpKeyFraction
        ),
        KeyLayout(
            key: .percent,
            id: "percent",
            label: "%",
            symbol: nil,
            role: .secondary,
            help: L10n.calc.helpKeyPercent
        ),
        KeyLayout(key: .digit(0), id: "0", label: "0", symbol: nil, role: .plain, help: digitHelp),
        KeyLayout(key: .point, id: "point", label: ".", symbol: nil, role: .plain, help: L10n.calc.helpKeyPoint),
        KeyLayout(key: .negate, id: "negate", label: "±", symbol: nil, role: .secondary, help: L10n.calc.helpKeyNegate),
        KeyLayout(key: .equals, id: "equals", label: "=", symbol: nil, role: .prominent, help: L10n.calc.helpKeyEquals),
    ]

    private static let columns = 5
    private static let rows = 5

    var body: some View {
        GeometryReader { geo in
            let side = KeypadLayout.keySide(in: geo.size, rows: Self.rows, columns: Self.columns)
            GlassEffectContainer(spacing: Tokens.spacing.glassBlend) {
                VStack(spacing: Tokens.spacing.keyGap) {
                    ForEach(0 ..< Self.rows, id: \.self) { row in
                        HStack(spacing: Tokens.spacing.keyGap) {
                            ForEach(0 ..< Self.columns, id: \.self) { column in
                                key(Self.layout[row * Self.columns + column], side: side)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calc.keypad")
    }

    private func key(_ item: KeyLayout, side: CGFloat) -> some View {
        GlassKey(
            label: item.label, symbol: item.symbol, role: item.role, shape: style.keyShape, tint: style.accent,
            action: { model.press(item.key) }
        )
        .frame(width: side, height: side)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in helpKey = item })
        .popover(isPresented: Binding(get: { helpKey == item }, set: {
            if !$0 {
                helpKey = nil
            }
        })) {
            HelpPopover(text: item.help)
        }
        .accessibilityLabel(a11y(item))
        .accessibilityHint(Text(item.help))
        .accessibilityIdentifier("calc.key.\(item.id)")
    }

    private func a11y(_ item: KeyLayout) -> String {
        switch item.key {
        case .allClear: String(localized: L10n.calc.keyAllClear)
        case .backspace: String(localized: L10n.calo.a11yKeyBackspace)
        case .feet: String(localized: L10n.calc.unitDecimalFeet)
        case .inches: String(localized: L10n.calc.unitDecimalInches)
        case .fractionBar: String(localized: L10n.calc.keyFraction)
        case .equals: String(localized: L10n.calc.keyEquals)
        default: item.label ?? item.id
        }
    }
}

/// Hold-to-see help (P-03): what the key does and one worked example.
struct HelpPopover: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .font(.callout)
            .padding(Tokens.spacing.screen)
            .frame(maxWidth: 300)
            .presentationCompactAdaptation(.popover)
            .accessibilityIdentifier("calc.help")
    }
}
