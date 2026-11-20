import Foundation

/// A keypad press (ontology #engine.key).
public enum Key: Hashable, Codable, Sendable {
    case digit(Int), point, feet, inches, fractionBar
    case plus, minus, times, divide, percent, negate, open, close, pi
    case equals, backspace, allClear
    case memoryAdd, memorySubtract, memoryRecall, memoryClear, undo

    var operation: Measure.Operation? {
        switch self {
        case .plus: .add
        case .minus: .subtract
        case .times: .multiply
        case .divide: .divide
        default: nil
        }
    }
}

/// One item of the expression (ontology #token).
public enum Token: Hashable, Codable, Sendable {
    case number(NumberToken)
    case value(Measure) // a reused result (tape, MR, Use)
    case op(Measure.Operation)
    case percent
    case open, close
    case pi

    public var text: String {
        text(system: .imperial, precision: .sixtyFourth)
    }

    // swiftlint:disable cyclomatic_complexity
    /// A reused value shows in its kind's default unit for the system, at the precision in force.
    public func text(system: UnitSystem, precision: Precision) -> String {
        switch self {
        case let .number(n): n.text
        case let .value(d):
            if d.kind == .scalar {
                Format.scalar(d.value).text
            } else {
                "[" + Format.dimension(
                    d, unit: DisplayUnit.defaultUnit(for: d.kind, system: system) ?? .decimalInches,
                    precision: precision
                ).text + "]"
            }
        case let .op(o):
            switch o {
            case .add: "+"
            case .subtract: "−"
            case .multiply: "×"
            case .divide: "÷"
            }
        case .percent: "%"
        case .open: "("
        case .close: ")"
        case .pi: "π"
        }
    }
    // swiftlint:enable cyclomatic_complexity
}

/// A line on the tape (ontology #tape).
public struct TapeLine: Hashable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var expression: String
    public var result: Measure
    public var date: Date

    public init(id: UUID = UUID(), expression: String, result: Measure, date: Date) {
        self.id = id
        self.expression = expression
        self.result = result
        self.date = date
    }
}
