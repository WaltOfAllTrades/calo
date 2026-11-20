import SwiftUI

/// A text field inside a glass capsule (Calo's Item and Log details fields).
public struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    let lines: Int

    /// - Parameter lines: 1 for a single line; more lets the field grow vertically up to that many.
    public init(_ placeholder: String, text: Binding<String>, lines: Int = 1) {
        self.placeholder = placeholder
        _text = text
        self.lines = lines
    }

    public var body: some View {
        TextField(placeholder, text: $text, axis: lines > 1 ? .vertical : .horizontal)
            .lineLimit(1 ... max(1, lines))
            .textFieldStyle(.plain)
            .padding(.horizontal, Tokens.spacing.screen)
            .padding(.vertical, Tokens.spacing.stack)
            .frame(minHeight: Tokens.size.control)
            .glassEffect(.regular, in: .capsule)
    }
}

/// The "Clear daily log" pattern: the first tap arms, the second acts, then the done label shows.
/// The state machine is a plain value (`TwoTapState`) so it is unit-tested without a view.
public struct TwoTapButton: View {
    let title: String
    let confirmTitle: String
    let doneTitle: String
    let role: ButtonRole?
    /// Glass on the keypad; bordered inside sheets and lists (no glass on glass, principle 4).
    let glass: Bool
    let action: () async -> Void
    @State private var state = TwoTapState.idle
    @State private var armedAt = Date.distantPast

    public init(
        _ title: String, confirmTitle: String, doneTitle: String, role: ButtonRole? = .destructive,
        glass: Bool = true, action: @escaping () async -> Void
    ) {
        self.title = title
        self.confirmTitle = confirmTitle
        self.doneTitle = doneTitle
        self.role = role
        self.glass = glass
        self.action = action
    }

    /// Exposed for the owner (Calo disarms on sheet close, E-C12).
    public var isDone: Bool {
        state == .done
    }

    public var body: some View {
        styled(
            Button(role: state == .armed ? role : nil) {
                Task { await tap() }
            } label: {
                Text(label)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Tokens.size.control)
            }
        )
        .disabled(state == .done)
        .sensoryFeedback(Haptics.arm, trigger: state == .armed)
        .sensoryFeedback(Haptics.cleared, trigger: state == .done)
        .task(id: armedAt) {
            // A tap that never gets its second tap disarms after Motion.armTimeout.
            guard state == .armed else { return }
            try? await Task.sleep(for: Motion.armTimeout)
            if state == .armed {
                state = state.timedOut()
            }
        }
    }

    /// The two glass styles are different types, so the branch is a view builder, not a ternary.
    @ViewBuilder
    private func styled(_ button: Button<some View>) -> some View {
        if glass {
            if state == .armed {
                button.buttonStyle(.glassProminent)
            } else {
                button.buttonStyle(.glass)
            }
        } else {
            if state == .armed {
                button.buttonStyle(.borderedProminent)
            } else {
                button.buttonStyle(.bordered)
            }
        }
    }

    private var label: String {
        switch state {
        case .idle: title
        case .armed: confirmTitle
        case .done: doneTitle
        }
    }

    private func tap() async {
        let next = state.tapped()
        state = next
        if next == .armed {
            armedAt = Date()
        }
        if next == .done {
            await action()
        }
    }
}

/// idle → (tap) armed → (tap) done; armed → (timeout) idle. Pure and `Sendable`.
public enum TwoTapState: Sendable, Equatable {
    case idle, armed, done

    public func tapped() -> TwoTapState {
        switch self {
        case .idle: .armed
        case .armed: .done
        case .done: .done
        }
    }

    public func timedOut() -> TwoTapState {
        self == .armed ? .idle : self
    }
}
