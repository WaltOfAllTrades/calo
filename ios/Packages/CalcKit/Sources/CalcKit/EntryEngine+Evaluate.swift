import Foundation

/// Evaluation (formulas.md §1): shunting-yard with the percent rules and E-K04's implied units.
extension EntryEngine {
    struct Evaluation {
        var value: Measure
        var tokens: [Token]
    }

    /// An operand on the value stack, with the token it came from when it is a single typed number,
    /// so a scalar coerced to a length (E-K04) can be marked on the expression line.
    private struct Operand {
        var value: Measure
        var origin: Int?
    }

    private struct Coerced {
        var left: Measure
        var right: Measure
        var marks: [Int]
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    /// Returns the value and the tokens, rewritten where a bare number was read as a length.
    func evaluate(_ input: [Token], precision: Precision, system: UnitSystem) throws -> Evaluation {
        var tokens = input
        let opens = tokens.filter { $0 == .open }.count
        let closes = tokens.filter { $0 == .close }.count
        if opens > closes {
            tokens += Array(repeating: .close, count: opens - closes)
        } // E-K08
        if case .op = tokens.last {
            throw CalcError.incomplete
        }

        var values: [Operand] = []
        var ops: [Token] = []
        var coerced: Set<Int> = []

        func apply(_ op: Token) throws {
            guard values.count >= 2, case let .op(operation) = op else { throw CalcError.incomplete }
            let right = values.removeLast()
            let left = values.removeLast()
            let pair = try coerce(left, right, operation, system: system)
            coerced.formUnion(pair.marks)
            try values.append(Operand(value: combine(pair.left, operation, pair.right), origin: nil))
        }
        func precedence(_ token: Token) -> Int {
            if case let .op(o) = token {
                return (o == .multiply || o == .divide) ? 2 : 1
            }
            return 0
        }

        for (index, token) in tokens.enumerated() {
            switch token {
            case let .number(n):
                let value = try n.dimension(entryDenominator: precision.entryDenominator)
                values.append(Operand(value: value, origin: n.isPlainDigits ? index : nil))
            case let .value(d):
                values.append(Operand(value: d, origin: nil))
            case .pi:
                // π as a scalar at a million parts: exact enough for any tape, small enough to multiply.
                values.append(Operand(value: .scalar(Fraction(3_141_593, 1_000_000)), origin: nil))
            case .percent:
                // `left op p %` folds into the pending operator; a bare `p %` is p/100.
                guard let p = values.popLast(), p.value.kind == .scalar else { throw CalcError.incomplete }
                if let op = ops.last, case let .op(operation) = op, let left = values.popLast() {
                    ops.removeLast()
                    let folded = try left.value.applyingPercent(p.value.value, operation: operation)
                    values.append(Operand(value: folded, origin: nil))
                } else {
                    values.append(Operand(value: .scalar(p.value.value * Fraction(1, 100)), origin: nil))
                }
            case .open:
                ops.append(.open)
            case .close:
                while let top = ops.last, top != .open {
                    try apply(ops.removeLast())
                }
                guard ops.last == .open else { throw CalcError.incomplete }
                ops.removeLast()
            case .op:
                while let top = ops.last, top != .open, precedence(top) >= precedence(token) {
                    try apply(ops.removeLast())
                }
                ops.append(token)
            }
        }
        while let top = ops.popLast() {
            guard top != .open else { continue }
            try apply(top)
        }
        guard values.count == 1, let result = values.first?.value else { throw CalcError.incomplete }
        try checkMagnitude(result)
        for index in coerced {
            if case var .number(n) = tokens[index] {
                n.impliedUnit = system.bareLengthUnit
                tokens[index] = .number(n)
            }
        }
        return Evaluation(value: result, tokens: tokens)
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    /// E-K04: a scalar added to or subtracted from a length is a length in the base unit. Returns
    /// which operands were coerced so the line can show it.
    private func coerce(
        _ left: Operand, _ right: Operand, _ operation: Measure.Operation, system: UnitSystem
    ) throws -> Coerced {
        guard operation == .add || operation == .subtract, let factor = system.bareLengthUnit.factor else {
            return Coerced(left: left.value, right: right.value, marks: [])
        }
        switch (left.value.kind, right.value.kind) {
        case (.length, .scalar):
            let r = try Measure(right.value.scaled(by: factor).value, .length)
            return Coerced(left: left.value, right: r, marks: right.origin.map { [$0] } ?? [])
        case (.scalar, .length):
            let l = try Measure(left.value.scaled(by: factor).value, .length)
            return Coerced(left: l, right: right.value, marks: left.origin.map { [$0] } ?? [])
        default:
            return Coerced(left: left.value, right: right.value, marks: [])
        }
    }

    private func combine(_ left: Measure, _ operation: Measure.Operation, _ right: Measure) throws -> Measure {
        switch operation {
        case .add: try left.adding(right)
        case .subtract: try left.subtracting(right)
        case .multiply: try left.multiplied(by: right)
        case .divide: try left.divided(by: right)
        }
    }

    /// E-K10: beyond a million feet (or 10¹² of anything) the display cannot show it honestly.
    private func checkMagnitude(_ value: Measure) throws {
        let limit = value.kind == .length ? Fraction(12_000_000) : Fraction(1_000_000_000_000)
        if value.value.magnitude > limit {
            throw CalcError.tooLarge
        }
    }
}
