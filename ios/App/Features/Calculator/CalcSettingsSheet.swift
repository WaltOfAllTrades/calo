import CalcKit
import DesignSystem
import SwiftUI

/// Settings (screens.md → Settings sheet): units, rounding, Look, stairs defaults, concrete, spacing,
/// About, Experiments. Every row writes `CalcPreferences` through the model.
struct CalcSettingsSheet: View {
    let model: CalculatorModel
    @Environment(\.dismiss) private var dismiss
    @State private var prefs = CalcPreferences.defaults
    @State private var riserText = ""
    @State private var treadText = ""
    @State private var headroomText = ""
    @State private var floorText = ""
    @State private var spacingText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section {
                        Picker(selection: $prefs.unitSystem) {
                            Text(L10n.calc.settingsImperial).tag(UnitSystem.imperial)
                            Text(L10n.calc.settingsMetric).tag(UnitSystem.metric)
                        } label: { Text(L10n.calc.settingsUnitSystem) }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("calc.settings.unitSystem")
                        Picker(selection: $prefs.precision) {
                            ForEach(Precision.allCases) { p in
                                Text(p.label ?? String(localized: L10n.calc.chipExact)).tag(p)
                            }
                        } label: { Text(L10n.calc.settingsPrecision) }
                            .accessibilityIdentifier("calc.settings.precision")
                        Picker(selection: $prefs.look) {
                            ForEach(Look.allCases) { look in Text(lookName(look)).tag(look) }
                        } label: { Text(L10n.calc.settingsLook) }
                            .accessibilityIdentifier("calc.settings.look")
                    }
                    Section {
                        lengthRow(L10n.calc.fieldRiser, text: $riserText, id: "riser")
                        lengthRow(L10n.calc.fieldTread, text: $treadText, id: "tread")
                        lengthRow(L10n.calc.fieldHeadroom, text: $headroomText, id: "headroom")
                        lengthRow(L10n.calc.fieldFloorThickness, text: $floorText, id: "floorThickness")
                        Toggle(isOn: $prefs.riserLimited) { Text(L10n.calc.fieldRiserLimited) }
                            .accessibilityIdentifier("calc.settings.riserLimited")
                    } header: { Text(L10n.calc.settingsStairs) }
                    Section {
                        Stepper(value: $prefs.wastePercent, in: 0 ... 50) {
                            LabeledContent { Text("\(prefs.wastePercent) %") } label: { Text(L10n.calc.fieldWaste) }
                        }
                        .accessibilityIdentifier("calc.settings.waste")
                        Picker(selection: $prefs.bagPounds) {
                            ForEach(CalcPreferences.bagSizes, id: \.self) { size in Text("\(size) lb").tag(size) }
                        } label: { Text(L10n.calc.fieldBag) }
                            .accessibilityIdentifier("calc.settings.bag")
                    } header: { Text(L10n.calc.settingsConcrete) }
                    Section {
                        lengthRow(L10n.calc.fieldSpacing, text: $spacingText, id: "spacing")
                    } header: { Text(L10n.calc.settingsSpacing) }
                    Section {
                        NavigationLink { CalcAboutScreen() } label: { Text(L10n.calc.settingsAbout) }
                            .accessibilityIdentifier("calc.settings.about")
                        NavigationLink { ExperimentsScreen() } label: {
                            HStack(spacing: Tokens.spacing.stack) {
                                Image(systemName: Symbols.experiments).accessibilityHidden(true)
                                Text(L10n.calc.settingsExperiments)
                            }
                        }
                        .accessibilityIdentifier("calc.settings.experiments")
                    }
                }
                Button { dismiss() } label: {
                    Text(L10n.calo.settingsDone).frame(maxWidth: .infinity).frame(minHeight: Tokens.size.control)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("calc.settings.done")
                .padding(.horizontal, Tokens.spacing.screen)
                .padding(.vertical, Tokens.spacing.stack)
            }
            .navigationTitle(Text(L10n.calc.settingsTitle))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .task {
            prefs = model.preferences
            riserText = inches(prefs.desiredRiser)
            treadText = inches(prefs.desiredTread)
            headroomText = inches(prefs.headroom)
            floorText = inches(prefs.floorThickness)
            spacingText = inches(prefs.spacing)
        }
        .onChange(of: prefs) { _, prefs in model.save(prefs) }
    }

    private func lengthRow(_ label: LocalizedStringResource, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numbersAndPunctuation)
                .frame(maxWidth: 140)
                .onSubmit { commit(id, text.wrappedValue) }
                .onChange(of: text.wrappedValue) { _, value in commit(id, value) }
                .accessibilityIdentifier("calc.settings.\(id)")
        }
    }

    /// A length that does not parse leaves the stored value alone.
    private func commit(_ id: String, _ text: String) {
        guard case let .dimension(d)? = NaturalEntry.parse(text, expecting: .length), d.value > .zero else { return }
        switch id {
        case "riser": prefs.desiredRiser = d.value
        case "tread": prefs.desiredTread = d.value
        case "headroom": prefs.headroom = d.value
        case "floorThickness": prefs.floorThickness = d.value
        case "spacing": prefs.spacing = d.value
        default: break
        }
    }

    private func inches(_ value: Fraction) -> String {
        Format.feetInches(value, precision: .sixtyFourth).text
    }

    private func lookName(_ look: Look) -> LocalizedStringResource {
        switch look {
        case .glass: L10n.calc.lookGlass
        case .tape: L10n.calc.lookTape
        case .daylight: L10n.calc.lookDaylight
        case .blueprint: L10n.calc.lookBlueprint
        }
    }
}

struct CalcAboutScreen: View {
    var body: some View {
        ScrollView {
            Text(L10n.calc.aboutBody)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.spacing.screen)
        }
        .navigationTitle(Text(L10n.calc.settingsAbout))
        .navigationBarTitleDisplayMode(.inline)
    }
}
