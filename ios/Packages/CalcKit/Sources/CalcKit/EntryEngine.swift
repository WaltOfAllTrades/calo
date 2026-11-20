import Foundation

/// The state machine (ontology #engine; SPEC door-keeping 4). A value type: the app wraps it in an
/// observable model and persists it whole (E-K16). Preferences (precision, unit system) are passed in.
public struct EntryEngine: Hashable, Codable, Sendable {
    public internal(set) var tokens: [Token] = []
    /// The last `=` result, while no new expression has started.
    public internal(set) var committed: Measure?
    public internal(set) var error: CalcError?
    public internal(set) var memory: Measure?
    /// The unit the chip shows for the current result kind; nil means the system default.
    public internal(set) var displayUnit: DisplayUnit?
    var undoSnapshot: UndoSnapshot?

    struct UndoSnapshot: Hashable, Codable, Sendable {
        var tokens: [Token]
        var committed: Measure?
    }

    public init() {}

    public var isCommitted: Bool {
        committed != nil
    }

    public var isEmpty: Bool {
        tokens.isEmpty && committed == nil
    }

    public var canUndo: Bool {
        undoSnapshot != nil
    }

    public var expressionText: String {
        expressionText(system: .imperial)
    }

    public func expressionText(system: UnitSystem, precision: Precision = .sixtyFourth) -> String {
        tokens.map { $0.text(system: system, precision: precision) }.joined(separator: " ")
    }

    /// The live value: the committed result, or the expression so far when it already evaluates.
    public func result(precision: Precision, system: UnitSystem) -> Measure? {
        if let committed {
            return committed
        }
        return try? evaluate(tokens, precision: precision, system: system).value
    }

    // MARK: Keys

    /// Applies a key. Returns the tape line when `=` committed a result.
    /// One case per key: the dispatch is the complexity, not the logic.
    @discardableResult
    // swiftlint:disable:next cyclomatic_complexity
    public mutating func press(_ key: Key, precision: Precision, system: UnitSystem, now: Date = Date()) -> TapeLine? {
        error = nil
        switch key {
        case let .digit(d): typeDigit(String(d))
        case .point: typePoint()
        case .feet: markFeet()
        case .inches: markInches()
        case .fractionBar: markFraction(precision: precision)
        case .plus, .minus, .times, .divide: pushOperator(key.operation ?? .add)
        case .percent: pushSimple(.percent)
        case .open: pushOpen()
        case .close: pushClose()
        case .pi: pushPi()
        case .negate: negate()
        case .equals: return equals(precision: precision, system: system, now: now)
        case .backspace: backspace()
        case .allClear: allClear()
        case .memoryAdd: memoryAdd(sign: .one, precision: precision, system: system)
        case .memorySubtract: memoryAdd(sign: Fraction(-1), precision: precision, system: system)
        case .memoryRecall: recallMemory()
        case .memoryClear: memory = nil
        case .undo: undo()
        }
        return nil
    }

    /// A value from the tape, a function result or MR becomes the next operand (E-K13).
    public mutating func insert(_ value: Measure) {
        startExpressionIfCommitted(keepResult: false)
        if case .number = tokens.last {
            tokens.removeLast()
        }
        if case .value = tokens.last {
            tokens.removeLast()
        }
        tokens.append(.value(value))
        displayUnit = nil
        error = nil
    }

    public mutating func cycleUnit(system: UnitSystem, kind: Measure.Kind) {
        let current = displayUnit ?? DisplayUnit.defaultUnit(for: kind, system: system)
        guard let current else { return }
        displayUnit = DisplayUnit.next(after: current, system: system)
    }

    public mutating func setDisplayUnit(_ unit: DisplayUnit?) {
        displayUnit = unit
    }
}
