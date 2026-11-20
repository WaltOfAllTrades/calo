import SwiftUI

/// One keypad key (spec/design/liquid-glass.md → Components). A system glass button: the system draws
/// the material, highlight and press; this view only decides the role, the shape and the label.
/// Sits inside the keypad's single `GlassEffectContainer` so neighbours blend.
public struct GlassKey: View {
    /// How the key reads on the keypad. `prominent` is the one tinted action per region; `accent`
    /// colours the label only; `secondary` dims the label (bonus keys).
    public enum Role: Sendable, Equatable {
        case plain, secondary, accent, prominent
    }

    /// Circles are the default; rounded squares are a calculator visual option.
    public enum Shape: Sendable, Equatable {
        case circle, roundedSquare
    }

    let label: String?
    let symbol: String?
    let role: Role
    let shape: Shape
    let tint: Color
    let action: () -> Void

    /// - Parameters:
    ///   - label: text on the key, or nil when `symbol` is given.
    ///   - symbol: an SF Symbol name, or nil.
    ///   - role: see `Role`.
    ///   - tint: the colour used by `accent` and `prominent`. Defaults to Calo's accent.
    public init(
        label: String? = nil, symbol: String? = nil, role: Role = .plain, shape: Shape = .circle,
        tint: Color = Tokens.color.accent, action: @escaping () -> Void
    ) {
        self.label = label
        self.symbol = symbol
        self.role = role
        self.shape = shape
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        styled(
            Button {
                pressCount += 1
                action()
            } label: {
                face
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
            }
        )
        .buttonBorderShape(shape == .circle ? .circle : .roundedRectangle(radius: Tokens.radius.field))
        .frame(minWidth: Tokens.size.control, minHeight: Tokens.size.control)
        .sensoryFeedback(Haptics.key, trigger: pressCount)
    }

    /// The caller's action runs first; the count drives the selection haptic.
    @State private var pressCount = 0

    @ViewBuilder
    private var face: some View {
        if let symbol {
            Image(systemName: symbol)
                .font(Tokens.font.key)
                .foregroundStyle(role == .accent ? tint : Tokens.color.text)
        } else {
            Text(label ?? "")
                .font(role == .secondary ? Tokens.font.keySecondary : Tokens.font.key)
                .foregroundStyle(role == .secondary ? Tokens.color.textFaint : Tokens.color.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    /// The glass style per role. Capped Dynamic Type so the grid never scrolls (E-C15).
    @ViewBuilder
    private func styled(_ button: Button<some View>) -> some View {
        if role == .prominent {
            button
                .buttonStyle(.glassProminent)
                .tint(tint)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        } else {
            button
                .buttonStyle(.glass)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}

/// A 44-pt icon button in glass (settings gear, back).
public struct GlassCircleButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    public init(symbol: String, label: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.medium))
                .frame(width: Tokens.size.control, height: Tokens.size.control)
                .contentShape(.circle)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

/// A horizontal glass capsule of symbol buttons (calculator: undo, tape, memory). Items are ≥ 44 pt.
public struct GlassPill: View {
    public struct Item: Identifiable {
        public let id: String
        public let symbol: String
        public let label: String
        public let isEnabled: Bool
        public let action: () -> Void

        public init(id: String, symbol: String, label: String, isEnabled: Bool = true, action: @escaping () -> Void) {
            self.id = id
            self.symbol = symbol
            self.label = label
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    let items: [Item]

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button(action: item.action) {
                    Image(systemName: item.symbol)
                        .font(.body.weight(.medium))
                        .frame(minWidth: Tokens.size.control, minHeight: Tokens.size.pillHeight)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(!item.isEnabled)
                .opacity(item.isEnabled ? 1 : 0.35)
                .accessibilityLabel(item.label)
                .accessibilityIdentifier(item.id)
            }
        }
        .padding(.horizontal, Tokens.spacing.glassBlend)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
