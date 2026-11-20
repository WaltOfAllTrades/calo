import SwiftUI

/// Every animation in both products (spec/design/liquid-glass.md → Motion). Views never hard-code
/// durations or curves; each entry has a Reduce Motion branch, resolved through `animation(reduceMotion:)`.
public enum Motion {
    /// One named motion: its animation, and what it becomes under Reduce Motion (nil = no animation).
    public struct Entry: Sendable {
        public let animation: Animation
        public let reduced: Animation?

        public init(_ animation: Animation, reduced: Animation?) {
            self.animation = animation
            self.reduced = reduced
        }

        /// The animation to use for the given accessibility setting.
        public func animation(reduceMotion: Bool) -> Animation? {
            reduceMotion ? reduced : animation
        }
    }

    /// Dash numbers and the calculator display rolling to a new value. Tuning value (web was 0.9 s).
    public static let digitRoll = Entry(.easeOut(duration: 0.6), reduced: nil)
    /// The active intent key gaining prominence.
    public static let intentSwitch = Entry(.easeOut(duration: 0.15), reduced: nil)
    /// The error line appearing and leaving. Under Reduce Motion the timing holds, the fade goes.
    public static let errorFade = Entry(.easeInOut(duration: 0.2), reduced: nil)
    /// How long the error line stays before it clears.
    public static let errorHold: Duration = .seconds(3)
    /// A two-tap button disarms after this without a second tap.
    public static let armTimeout: Duration = .seconds(4)
    /// How long "Daily log cleared" stays before the button goes (web: 1.2 s).
    public static let clearedLinger: Duration = .milliseconds(1200)
    /// The calculator result settling after `=`.
    public static let resultSettle = Entry(.easeOut(duration: 0.2), reduced: nil)
}

public extension View {
    /// Applies a named motion to changes of `value`, honouring Reduce Motion.
    func motion(_ entry: Motion.Entry, reduceMotion: Bool, value: some Equatable) -> some View {
        animation(entry.animation(reduceMotion: reduceMotion), value: value)
    }
}
