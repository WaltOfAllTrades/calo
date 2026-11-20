import SwiftUI

/// Calo's content layer (spec/design/liquid-glass.md → Backgrounds): the web app's night in dark
/// mode, a cool off-white in light, with a soft accent wash at the top for the glass to refract.
public struct CaloBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            colorScheme == .dark ? Tokens.color.night : Tokens.color.day
            RadialGradient(
                colors: [Tokens.color.accent.opacity(Tokens.color.washOpacity), .clear],
                center: .top, startRadius: 0, endRadius: 420
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The calculator's content layer: graphite or paper with a faint grid, so glass keys have texture.
public struct CalcBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    let showsGrid: Bool

    public init(showsGrid: Bool = true) {
        self.showsGrid = showsGrid
    }

    public var body: some View {
        ZStack {
            colorScheme == .dark ? Tokens.color.graphite : Tokens.color.paper
            if showsGrid {
                Canvas { context, size in
                    let cell = Tokens.size.gridCell
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += cell
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += cell
                    }
                    context.stroke(path, with: .color(.primary.opacity(Tokens.color.gridOpacity)), lineWidth: 1)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
