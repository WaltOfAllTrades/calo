import CalcKit
import DesignSystem
import SwiftUI

/// The calculator's main screen (calculator/screens.md → Main): toolbar pill, expression line,
/// result with its two chips, the 5×5 keypad. Sheets: formats, tape, functions, settings.
struct CalculatorScreen: View {
    @Environment(\.calc) private var env
    @Environment(\.experiments) private var experiments
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: CalculatorModel?
    @State private var sheet: Sheet?

    enum Sheet: String, Identifiable {
        case formats, tape, functions, settings
        var id: String {
            rawValue
        }
    }

    var body: some View {
        ZStack {
            if let model {
                let style = LookStyle(look: model.preferences.look)
                style.backdrop
                GeometryReader { geo in
                    content(model, style: style, height: geo.size.height)
                }
                .preferredColorScheme(style.colorScheme)
            }
        }
        .task {
            let m = model ?? CalculatorModel(env: env)
            model = m
            await m.restore()
        }
        .sheet(item: $sheet, onDismiss: { experiments.activate() }, content: { sheet in
            if let model {
                switch sheet {
                case .formats: FormatsSheet(model: model)
                case .tape: TapeSheet(model: model)
                case .functions: FunctionsSheet(model: model)
                case .settings: CalcSettingsSheet(model: model)
                }
            }
        })
    }

    private func content(_ model: CalculatorModel, style: LookStyle, height: CGFloat) -> some View {
        VStack(spacing: Tokens.spacing.stack) {
            toolbar(model)
            Spacer(minLength: 0)
            CalcDisplay(model: model, onTapResult: { sheet = .formats })
            CalcKeypadView(model: model, style: style)
                .frame(height: KeypadLayout.height(available: height, rows: 5, columns: 5))
        }
        .padding(.horizontal, Tokens.spacing.screen)
        .padding(.bottom, Tokens.spacing.stack)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toolbar(_ model: CalculatorModel) -> some View {
        HStack {
            GlassPill(items: [
                .init(id: "calc.pill.undo", symbol: Symbols.undo, label: String(localized: L10n.calc.pillUndo),
                      isEnabled: model.canUndo, action: { model.press(.undo) }),
                .init(id: "calc.pill.tape", symbol: Symbols.tape, label: String(localized: L10n.calc.pillTape),
                      action: { sheet = .tape }),
                .init(
                    id: "calc.pill.functions",
                    symbol: Symbols.function,
                    label: String(localized: L10n.calc.pillFunctions),
                    action: { sheet = .functions }
                ),
            ])
            Spacer()
            MemoryMenu(model: model)
            GlassCircleButton(symbol: Symbols.settings, label: String(localized: L10n.calc.pillSettings)) {
                sheet = .settings
            }
            .accessibilityIdentifier("calc.pill.settings")
        }
        .frame(minHeight: Tokens.size.control)
    }
}

/// M+, M−, MR, MC with the stored value (screens.md → Main).
struct MemoryMenu: View {
    let model: CalculatorModel

    var body: some View {
        Menu {
            if let memory = model.memory {
                Text(memoryText(memory))
            } else {
                Text(L10n.calc.memoryEmpty)
            }
            Button { model.press(.memoryAdd) } label: { Text(L10n.calc.memoryAdd) }
            Button { model.press(.memorySubtract) } label: { Text(L10n.calc.memorySubtract) }
            Button { model.press(.memoryRecall) } label: { Text(L10n.calc.memoryRecall) }
                .disabled(model.memory == nil)
            Button(role: .destructive) { model.press(.memoryClear) } label: { Text(L10n.calc.memoryClear) }
                .disabled(model.memory == nil)
        } label: {
            Image(systemName: Symbols.memory)
                .font(.body.weight(.medium))
                .frame(width: Tokens.size.control, height: Tokens.size.control)
                .contentShape(.circle)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(Text(L10n.calc.pillMemory))
        .accessibilityIdentifier("calc.pill.memory")
    }

    private func memoryText(_ memory: Measure) -> String {
        if memory.kind == .scalar {
            return Format.scalar(memory.value).text
        }
        let unit = DisplayUnit.defaultUnit(for: memory.kind, system: model.preferences.unitSystem) ?? .decimalInches
        return Format.dimension(memory, unit: unit, precision: model.preferences.precision).text
    }
}

/// Expression line, result, unit chip and precision chip (screens.md → Main).
struct CalcDisplay: View {
    let model: CalculatorModel
    let onTapResult: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(model.expressionText.isEmpty ? " " : model.expressionText)
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(Tokens.color.textFaint)
                        .lineLimit(1)
                        .id("end")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .onChange(of: model.expressionText) { _, _ in proxy.scrollTo("end", anchor: .trailing) }
            }
            .frame(minHeight: 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.calc.a11yExpression(model.expressionText))
            .accessibilityIdentifier("calc.expression")

            resultText
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(minHeight: 52)
                .contentShape(.rect)
                .onTapGesture {
                    if model.formats().isEmpty == false {
                        onTapResult()
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.calc.a11yResult(model.formatted?.text ?? ""))
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("calc.result")

            HStack(spacing: Tokens.spacing.stack) {
                Spacer()
                if let unit = model.displayUnit {
                    chip(Format.suffix(unit), id: "calc.chip.unit", a11y: L10n.calc.a11yChipUnit(Format.suffix(unit))) {
                        model.cycleUnit()
                    }
                }
                let precision = model.preferences.precision
                let label = (precision.label ?? String(localized: L10n.calc.chipExact))
                    + ((model.formatted?.isRounded ?? false) ? " " + String(localized: L10n.calc.chipApprox) : "")
                chip(label, id: "calc.chip.precision", a11y: L10n.calc.a11yChipPrecision(label)) {
                    model.cyclePrecision()
                }
            }
        }
    }

    @ViewBuilder
    private var resultText: some View {
        if let error = model.error {
            Text(errorText(error))
                .font(.title3)
                .foregroundStyle(error == .divideByZero ? Tokens.color.negative : Tokens.color.textFaint)
        } else {
            Text(model.formatted?.text ?? " ")
                .font(Tokens.font.display)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .contentTransition(.numericText())
                .motion(Motion.resultSettle, reduceMotion: reduceMotion, value: model.formatted?.text ?? "")
        }
    }

    private func chip(_ text: String, id: String, a11y: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .accessibilityLabel(a11y)
        .accessibilityIdentifier(id)
    }

    private func errorText(_ error: CalcError) -> String {
        switch error {
        case .divideByZero: String(localized: L10n.calc.errorDivideByZero)
        case let .dimensionMismatch(a, b): L10n.calc.errorDimensionMismatch(kindName(a), kindName(b))
        case .incomplete: String(localized: L10n.calc.errorIncomplete)
        case .tooLarge: String(localized: L10n.calc.errorTooLarge)
        }
    }

    private func kindName(_ kind: Measure.Kind) -> String {
        switch kind {
        case .scalar: String(localized: L10n.calc.kindScalar)
        case .length: String(localized: L10n.calc.kindLength)
        case .area: String(localized: L10n.calc.kindArea)
        case .volume: String(localized: L10n.calc.kindVolume)
        case .angle: String(localized: L10n.calc.kindAngle)
        }
    }
}
