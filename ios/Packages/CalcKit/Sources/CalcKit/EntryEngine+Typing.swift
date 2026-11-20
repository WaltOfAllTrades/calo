import Foundation

/// Typing and structure keys (formulas.md §2). Split from the core for file length; same type.
extension EntryEngine {
    // MARK: Typing

    /// The number under edit. Digits replace a reused value (E-K13); marks and `±` leave it alone.
    mutating func editableNumber(replacingValue: Bool = true) -> NumberToken? {
        startExpressionIfCommitted(keepResult: false)
        if case let .number(n) = tokens.last {
            tokens.removeLast()
            return n
        }
        if case .value = tokens.last {
            guard replacingValue else { return nil }
            tokens.removeLast()
        }
        return NumberToken()
    }

    mutating func typeDigit(_ digit: String) {
        guard var n = editableNumber() else { return }
        if n.fractionClosed || (n.power > 1 && n.current.isEmpty) {
            // `5′ 3″ 1⁄2″` or `100′′` is complete: more digits start a new number.
            tokens.append(.number(n))
            n = NumberToken()
        } else if n.slot == .whole, n.inchMark {
            n.slot = .numerator // digits after the inch mark are a fraction's top
        }
        n.current += digit
        tokens.append(.number(n))
    }

    mutating func typePoint() {
        guard var n = editableNumber() else { return }
        guard n.slot == .whole, !n.inchMark, !n.fractionClosed, n.power == 1, !n.current.contains(".") else {
            tokens.append(.number(n))
            return
        }
        n.current += n.current.isEmpty ? "0." : "."
        tokens.append(.number(n))
    }

    mutating func markFeet() {
        guard var n = editableNumber(replacingValue: false) else { return }
        if n.current.isEmpty, n.feet != nil, n.inches == nil, !n.inchMark, n.numerator == nil, n.power < 3 {
            n.power += 1 // `′′` square, `′′′` cubic
        } else if !n.current.isEmpty, n.feet == nil, n.slot == .whole {
            n.feet = n.current
            n.current = ""
        } else if n.isEmpty {
            return // E-K06: a mark with no number
        }
        tokens.append(.number(n))
    }

    mutating func markInches() {
        guard var n = editableNumber(replacingValue: false) else { return }
        switch n.slot {
        case .whole where !n.current.isEmpty && !n.inchMark:
            n.inches = n.current
            n.current = ""
            n.inchMark = true
        case .whole where n.current.isEmpty && n.inchMark && n.numerator == nil && n.power < 3:
            n.power += 1 // `″″` square inches
        case .denominator where !n.current.isEmpty:
            n.denominator = n.current
            n.current = ""
            n.slot = .whole
            n.fractionClosed = true
        case .whole where n.numerator != nil && n.denominator != nil:
            n.fractionClosed = true
        default:
            if n.isEmpty {
                return
            } // E-K06
        }
        tokens.append(.number(n))
    }

    mutating func markFraction(precision _: Precision) {
        guard var n = editableNumber(replacingValue: false) else { return }
        guard !n.current.isEmpty, n.numerator == nil, !n.hasDecimal, n.slot != .denominator, n.power == 1 else {
            tokens.append(.number(n)) // E-K02 and a bar with nothing before it: refused
            return
        }
        n.numeratorFromWhole = n.slot == .whole
        n.numerator = n.current
        n.current = ""
        n.slot = .denominator
        tokens.append(.number(n))
    }

    mutating func negate() {
        if let committed {
            self.committed = committed.negated()
            return
        }
        if case let .value(d) = tokens.last {
            tokens[tokens.count - 1] = .value(d.negated())
            return
        }
        guard var n = editableNumber() else { return }
        n.negative.toggle()
        tokens.append(.number(n))
    }

    // MARK: Structure

    mutating func pushOperator(_ operation: Measure.Operation) {
        startExpressionIfCommitted(keepResult: true)
        finalizeTrailingNumber()
        if case .op = tokens.last {
            tokens.removeLast() // E-K07: the second operator replaces the first
        }
        guard !tokens.isEmpty, tokens.last != .open else { return }
        tokens.append(.op(operation))
    }

    mutating func pushSimple(_ token: Token) {
        startExpressionIfCommitted(keepResult: true)
        finalizeTrailingNumber()
        switch tokens.last {
        case .number, .value, .close: tokens.append(token)
        default: return
        }
    }

    mutating func pushOpen() {
        startExpressionIfCommitted(keepResult: false)
        finalizeTrailingNumber()
        switch tokens.last {
        case .number, .value, .close, .percent, .pi: return
        default: tokens.append(.open)
        }
    }

    mutating func pushClose() {
        startExpressionIfCommitted(keepResult: true)
        finalizeTrailingNumber()
        let opens = tokens.filter { $0 == .open }.count
        let closes = tokens.filter { $0 == .close }.count
        guard opens > closes else { return } // E-K08: unmatched close ignored
        switch tokens.last {
        case .number, .value, .close, .percent, .pi: tokens.append(.close)
        default: return
        }
    }

    mutating func pushPi() {
        startExpressionIfCommitted(keepResult: false)
        finalizeTrailingNumber()
        switch tokens.last {
        case .number, .value, .close, .pi: return
        default: tokens.append(.pi)
        }
    }

    /// A finished number keeps its typed digits; `current` moves into the open slot, and a complete
    /// fraction after an inch mark closes. Digits typed after an inch mark without a bar stay pending,
    /// so `=` reports the expression as incomplete.
    mutating func finalizeTrailingNumber() {
        guard case var .number(n) = tokens.last else { return }
        tokens.removeLast()
        if !n.current.isEmpty {
            switch n.slot {
            case .whole:
                n.inches = n.current
                n.current = ""
            case .numerator:
                break
            case .denominator:
                n.denominator = n.current
                n.current = ""
                n.slot = .whole
            }
        }
        if n.inchMark, n.numerator != nil, n.denominator != nil {
            n.fractionClosed = true
        }
        if n.isEmpty {
            return
        }
        tokens.append(.number(n))
    }

    /// After `=`, an operator continues from the result; anything else starts fresh.
    mutating func startExpressionIfCommitted(keepResult: Bool) {
        guard let committed else { return }
        tokens = keepResult ? [.value(committed)] : []
        self.committed = nil
    }

    // swiftlint:disable cyclomatic_complexity
    /// One visible character back per press, through a fraction and a mark, in the reverse order of
    /// typing. A mark counts as one character; its digits come back as the number under edit.
    mutating func backspace() {
        if let committed {
            // E-K25: the result becomes an editable value; another backspace removes it.
            tokens = [.value(committed)]
            self.committed = nil
            return
        }
        guard case var .number(n)? = tokens.last else {
            if !tokens.isEmpty {
                tokens.removeLast()
            }
            return
        }
        tokens.removeLast()
        if !n.current.isEmpty {
            n.current.removeLast()
            if n.current.isEmpty, n.slot == .numerator {
                n.slot = .whole
            }
        } else if n.fractionClosed {
            n.fractionClosed = false
        } else if let denominator = n.denominator {
            n.current = String(denominator.dropLast())
            n.denominator = nil
            n.slot = .denominator
        } else if n.slot == .denominator, let numerator = n.numerator {
            n.current = numerator // the bar goes; its digits stay
            n.numerator = nil
            n.slot = n.numeratorFromWhole ? .whole : .numerator
        } else if n.slot == .numerator {
            n.slot = .whole
        } else if n.inchMark, n.power > 1 {
            n.power -= 1
        } else if n.inchMark {
            n.inchMark = false // the mark goes; its digits stay
            n.current = n.inches ?? ""
            n.inches = nil
        } else if let inches = n.inches {
            n.current = String(inches.dropLast())
            n.inches = nil
        } else if n.feet != nil, n.power > 1 {
            n.power -= 1
        } else if let feet = n.feet {
            n.current = feet // the mark goes; its digits stay
            n.feet = nil
        } else if n.negative {
            n.negative = false
        }
        if !n.isEmpty || n.negative {
            tokens.append(.number(n))
        }
    }

    // swiftlint:enable cyclomatic_complexity

    mutating func allClear() {
        undoSnapshot = UndoSnapshot(tokens: tokens, committed: committed)
        tokens = []
        committed = nil
        error = nil
    }

    mutating func undo() {
        guard let snapshot = undoSnapshot else { return }
        tokens = snapshot.tokens
        committed = snapshot.committed
        undoSnapshot = nil
        error = nil
    }

    mutating func equals(precision: Precision, system: UnitSystem, now: Date) -> TapeLine? {
        if committed != nil {
            return nil
        }
        finalizeTrailingNumber()
        if case .op = tokens.last {
            tokens.removeLast()
        } // E-K09
        guard !tokens.isEmpty else { return nil }
        let snapshot = UndoSnapshot(tokens: tokens, committed: nil)
        do {
            let evaluation = try evaluate(tokens, precision: precision, system: system)
            tokens = evaluation.tokens
            undoSnapshot = snapshot
            committed = evaluation.value
            if displayUnit?.kind != evaluation.value.kind {
                displayUnit = nil
            }
            return TapeLine(expression: expressionText(system: system), result: evaluation.value, date: now)
        } catch let calcError as CalcError {
            error = calcError
        } catch {
            self.error = .incomplete
        }
        return nil
    }

    mutating func memoryAdd(sign: Fraction, precision: Precision, system: UnitSystem) {
        guard let value = result(precision: precision, system: system) else { return }
        guard let memory else {
            memory = try? value.scaled(by: sign)
            return
        }
        do {
            self.memory = try memory.adding(value.scaled(by: sign))
        } catch let calcError as CalcError {
            error = calcError // E-K15
        } catch {
            self.error = .tooLarge
        }
    }

    mutating func recallMemory() {
        guard let memory else { return }
        insert(memory)
    }
}
