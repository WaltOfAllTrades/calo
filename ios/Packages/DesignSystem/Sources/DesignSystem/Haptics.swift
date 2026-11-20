import SwiftUI

/// Haptics (spec/design/liquid-glass.md → Haptics), expressed as SwiftUI sensory feedback so views
/// attach them with `.sensoryFeedback(Haptics.key, trigger:)` and no UIKit generator objects are kept.
public enum Haptics {
    /// Every key press (selection changed).
    public static let key: SensoryFeedback = .selection
    /// Enter on the keypad.
    public static let enter: SensoryFeedback = .impact(weight: .light)
    /// A refused action, or a failed write.
    public static let error: SensoryFeedback = .error
    /// A two-tap button arming.
    public static let arm: SensoryFeedback = .impact(weight: .medium)
    /// The daily log cleared.
    public static let cleared: SensoryFeedback = .success
    /// The calculator producing a result.
    public static let result: SensoryFeedback = .impact(weight: .light)
}

/// SF Symbol names used by both products (icon maps in each `screens.md`). One list, so a renamed
/// symbol changes in one place.
public enum Symbols {
    public static let settings = "gearshape"
    public static let plus = "plus"
    public static let minus = "minus"
    public static let backspace = "delete.left"
    public static let enter = "return"
    public static let chevron = "chevron.right"
    public static let trash = "trash"
    public static let experiments = "flask"
    public static let back = "chevron.left"
    public static let undo = "arrow.uturn.backward"
    public static let tape = "list.bullet.rectangle"
    public static let memory = "m.square"
    public static let swap = "arrow.left.arrow.right"
    public static let convert = "arrow.triangle.2.circlepath"
    public static let ruler = "ruler"
    public static let stairs = "stairs"
    public static let roof = "house"
    public static let concrete = "cube"
    public static let board = "rectangle.split.3x1"
    public static let diagonal = "square.split.diagonal"
    public static let circle = "circle"
    public static let percent = "percent"
    public static let history = "clock.arrow.circlepath"
    public static let share = "square.and.arrow.up"
    public static let function = "function"
}
