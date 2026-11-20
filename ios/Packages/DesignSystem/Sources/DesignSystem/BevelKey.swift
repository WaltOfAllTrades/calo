import SwiftUI

/// A physical-feeling key: a flat face on a darker base that it sinks into when pressed, an optional
/// bevel ring (Calo's web design) or an outline (the lit intent key). Used for Calo's keypad, which
/// keeps the web app's design, and for the calculator's "real calculator" looks. Glass keys
/// (`GlassKey`) remain an Experiments option.
public struct BevelKey: View {
    /// Colours of one key. Calo and the calculator each define their palettes from these.
    public struct Palette: Sendable, Equatable {
        public var face: Color
        public var label: Color
        /// The darker edge the face sinks into. Nil means flat (ring style instead of depth).
        public var base: Color?
        /// Calo's gradient ring around the face.
        public var ring: Bool
        /// The lit intent key's white outline.
        public var outline: Bool

        public init(face: Color, label: Color = .white, base: Color? = nil, ring: Bool = false, outline: Bool = false) {
            self.face = face
            self.label = label
            self.base = base
            self.ring = ring
            self.outline = outline
        }
    }

    public enum Shape: Sendable, Equatable {
        case circle, roundedSquare
    }

    let label: String?
    let symbol: String?
    let palette: Palette
    let shape: Shape
    let font: Font
    let action: () -> Void
    @State private var pressCount = 0

    public init(
        label: String? = nil, symbol: String? = nil, palette: Palette, shape: Shape = .circle,
        font: Font = Tokens.font.key, action: @escaping () -> Void
    ) {
        self.label = label
        self.symbol = symbol
        self.palette = palette
        self.shape = shape
        self.font = font
        self.action = action
    }

    public var body: some View {
        Button {
            pressCount += 1
            action()
        } label: {
            face
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(BevelStyle(palette: palette, shape: shape))
        .frame(minWidth: Tokens.size.control, minHeight: Tokens.size.control)
        .sensoryFeedback(Haptics.key, trigger: pressCount)
    }

    @ViewBuilder
    private var face: some View {
        if let symbol {
            Image(systemName: symbol)
                .font(font)
                .foregroundStyle(palette.label)
        } else {
            Text(label ?? "")
                .font(font)
                .foregroundStyle(palette.label)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}

/// The press: the face drops onto its base (depth style) or scales and brightens (ring style),
/// 90 ms like the web app's key transition.
struct BevelStyle: ButtonStyle {
    let palette: BevelKey.Palette
    let shape: BevelKey.Shape
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var depth: CGFloat {
        palette.base == nil ? 0 : 4
    }

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        ZStack {
            if let base = palette.base {
                keyShape.fill(base)
            }
            keyShape
                .fill(palette.face)
                .overlay(ring)
                .overlay(outline)
                .overlay(configuration.label)
                .brightness(pressed ? (palette.base == nil ? 0.12 : -0.04) : 0)
                .scaleEffect(pressed && palette.base == nil ? 0.96 : 1)
                .offset(y: pressed ? depth - 1 : 0)
                .padding(.bottom, depth)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.09), value: pressed)
    }

    private var keyShape: AnyShape {
        shape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(
            cornerRadius: Tokens.radius.key,
            style: .continuous
        ))
    }

    @ViewBuilder
    private var ring: some View {
        if palette.ring {
            keyShape.stroke(
                LinearGradient(
                    colors: [Tokens.color.keyRingLight, Tokens.color.keyRingDark, Tokens.color.keyRingLight],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .clipShape(keyShape)
        }
    }

    @ViewBuilder
    private var outline: some View {
        if palette.outline {
            keyShape.stroke(Color.white, lineWidth: 2).padding(-2)
        }
    }
}
