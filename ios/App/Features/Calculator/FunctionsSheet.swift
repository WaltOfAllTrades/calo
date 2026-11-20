import CalcKit
import DesignSystem
import SwiftUI

/// The Functions grid (screens.md → Functions sheet): one card per registry entry.
struct FunctionsSheet: View {
    let model: CalculatorModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: Tokens.spacing.stack),
        GridItem(.flexible(), spacing: Tokens.spacing.stack),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Tokens.spacing.stack) {
                    ForEach(FunctionSpec.registry) { spec in
                        NavigationLink(value: spec.id) {
                            VStack(spacing: 8) {
                                Image(systemName: FunctionText.symbol(spec.id)).font(.title2)
                                Text(FunctionText.title(spec.id)).font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 88)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.roundedRectangle(radius: Tokens.radius.card))
                        .accessibilityIdentifier("calc.fn.\(spec.id)")
                    }
                }
                .padding(Tokens.spacing.screen)
            }
            .navigationTitle(Text(L10n.calc.functionsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { id in
                if let spec = FunctionSpec.named(id) {
                    FunctionDetailScreen(spec: spec, model: model, onUse: { dismiss() })
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// Fields in, results out (screens.md → Function detail). Results update live when every required
/// field parses; Use sends a result to the keypad; warnings show code limits without blocking.
struct FunctionDetailScreen: View {
    let spec: FunctionSpec
    let model: CalculatorModel
    let onUse: () -> Void
    @State private var texts: [String: String] = [:]
    @State private var toggles: [String: Bool] = [:]
    @State private var bag = 80
    @State private var results: [FunctionResult] = []

    var body: some View {
        List {
            Section {
                ForEach(spec.fields) { field in
                    fieldRow(field)
                }
            }
            Section {
                if results.isEmpty {
                    Text(spec.id == "stairs" ? L10n.calc.fnEmptyStairs : L10n.calc.fnEmptyGeneric)
                        .foregroundStyle(Tokens.color.textFaint)
                        .accessibilityIdentifier("calc.fn.\(spec.id).empty")
                } else {
                    ForEach(results) { result in
                        resultRow(result)
                    }
                }
            }
        }
        .navigationTitle(Text(FunctionText.title(spec.id)))
        .navigationBarTitleDisplayMode(.inline)
        .task { seedDefaults(); solve() }
        .onChange(of: texts) { _, _ in solve() }
        .onChange(of: toggles) { _, _ in solve() }
        .onChange(of: bag) { _, _ in solve() }
    }

    @ViewBuilder
    private func fieldRow(_ field: FunctionField) -> some View {
        switch field.kind {
        case .toggle:
            Toggle(isOn: Binding(get: { toggles[field.id] ?? false }, set: { toggles[field.id] = $0 })) {
                Text(FunctionText.field(field.id))
            }
            .accessibilityIdentifier("calc.fn.\(spec.id).field.\(field.id)")
        case .bagSize:
            Picker(selection: $bag) {
                ForEach(CalcPreferences.bagSizes, id: \.self) { size in Text("\(size) lb").tag(size) }
            } label: { Text(FunctionText.field(field.id)) }
                .accessibilityIdentifier("calc.fn.\(spec.id).field.\(field.id)")
        default:
            HStack {
                Text(FunctionText.field(field.id))
                Spacer()
                TextField("", text: Binding(get: { texts[field.id] ?? "" }, set: { texts[field.id] = $0 }))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(field.kind == .count ? .numberPad : .numbersAndPunctuation)
                    .frame(maxWidth: 160)
                    .accessibilityIdentifier("calc.fn.\(spec.id).field.\(field.id)")
            }
            .contextMenu { Text(FunctionText.help(field.id)) }
        }
    }

    private func resultRow(_ result: FunctionResult) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(FunctionText.result(result.id))
                if let warning = result.warning {
                    Text(FunctionText.warning(warning)).font(.caption).foregroundStyle(Tokens.color.negative)
                }
            }
            Spacer()
            Text(text(for: result)).monospacedDigit().accessibilityIdentifier("calc.fn.\(spec.id).result.\(result.id)")
            Button {
                model.insert(result.value)
                onUse()
            } label: {
                Image(systemName: "arrow.down.to.line")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(L10n.calc.fnUse))
            .accessibilityIdentifier("calc.fn.\(spec.id).use.\(result.id)")
        }
        .accessibilityElement(children: .contain)
    }

    private func text(for result: FunctionResult) -> String {
        let prefs = model.preferences
        switch result.style {
        case .count: return Format.scalar(result.value.value).text
        case .money: return result.value.value.doubleValue.formatted(.currency(code: "USD"))
        case .dimension:
            if result.value.kind == .scalar {
                return Format.scalar(result.value.value).text
            }
            let unit = result.displayUnit
                ?? DisplayUnit.defaultUnit(for: result.value.kind, system: prefs.unitSystem) ?? .decimalInches
            return Format.dimension(result.value, unit: unit, precision: prefs.precision).text
        }
    }

    /// Defaults from preferences become the fields' initial text, so the user sees and can change them.
    private func seedDefaults() {
        let defaults = spec.defaults(model.preferences)
        for field in spec.fields {
            guard let value = defaults[field.id] else { continue }
            switch value {
            case let .toggle(b): toggles[field.id] = b
            case let .int(i): if field.kind == .bagSize {
                    bag = i
                } else {
                    texts[field.id] = String(i)
                }
            case let .number(f): texts[field.id] = f.description
            case let .dimension(d):
                if d.kind == .angle {
                    texts[field.id] = Format.dimension(d, unit: .degrees, precision: .exact).text
                } else {
                    texts[field.id] = Format.feetInches(d.value, precision: .sixtyFourth).text
                }
            }
        }
    }

    private func solve() {
        var input = FunctionInput()
        for field in spec.fields {
            switch field.kind {
            case .toggle: input[field.id] = .toggle(toggles[field.id] ?? false)
            case .bagSize: input[field.id] = .int(bag)
            default:
                guard let text = texts[field.id], !text.isEmpty else { continue }
                if let value = NaturalEntry.parse(text, expecting: Self.expecting(for: field)) {
                    input[field.id] = value
                }
            }
        }
        results = spec.isComplete(input) ? spec.solve(input, model.preferences) : []
    }

    /// The pitch field takes `7/12` or a bare 7; other angle fields take degrees.
    private static func expecting(for field: FunctionField) -> NaturalEntry.Expecting {
        switch field.kind {
        case .length, .toggle, .bagSize: .length
        case .angle: field.id == "pitch" ? .pitch : .angle
        case .count: .count
        case .percent: .percent
        case .money: .money
        }
    }
}

/// Titles, symbols, field and result labels, help, by id (copy.md). One place maps ids to strings.
enum FunctionText {
    static func title(_ id: String) -> LocalizedStringResource {
        switch id {
        case "stairs": L10n.calc.fnStairs
        case "roof": L10n.calc.fnRoof
        case "concrete": L10n.calc.fnConcrete
        case "boardFeet": L10n.calc.fnBoardFeet
        case "squareUp": L10n.calc.fnSquareUp
        case "circle": L10n.calc.fnCircle
        case "miter": L10n.calc.fnMiter
        case "polygon": L10n.calc.fnPolygon
        default: L10n.calc.fnStuds
        }
    }

    static func symbol(_ id: String) -> String {
        switch id {
        case "stairs": Symbols.stairs
        case "roof": Symbols.roof
        case "concrete": Symbols.concrete
        case "boardFeet": Symbols.board
        case "squareUp": Symbols.diagonal
        case "circle": Symbols.circle
        case "miter": "angle"
        case "polygon": "hexagon"
        default: Symbols.ruler
        }
    }

    static func field(_ id: String) -> LocalizedStringResource {
        LocalizedStringResource("calc.field.\(id)")
    }

    static func help(_ id: String) -> LocalizedStringResource {
        let known = [
            "rise",
            "run",
            "riser",
            "tread",
            "headroom",
            "floorThickness",
            "riserLimited",
            "pitch",
            "span",
            "spacing",
            "waste",
            "bag",
            "pricePerMbm",
        ]
        return LocalizedStringResource(known.contains(id) ? "calc.help.field.\(id)" : "calc.help.field.generic")
    }

    static func result(_ id: String) -> String {
        if id.hasPrefix("jack"), let n = Int(id.dropFirst(4)) {
            return L10n.calc.resultJack(n)
        }
        let mapped: [String: String] = [
            "hipPlumb": "plumb", "hipLevel": "level", "pitchDegrees": "angle", "planArea": "area",
        ]
        return String(localized: LocalizedStringResource("calc.result.\(mapped[id] ?? id)"))
    }

    static func warning(_ warning: FunctionResult.Warning) -> LocalizedStringResource {
        switch warning {
        case .riserOverLimit: L10n.calc.warnRiser
        case .treadUnderMinimum: L10n.calc.warnTread
        case .headroomUnderMinimum: L10n.calc.warnHeadroom
        }
    }
}
