import CaloKit
import DesignSystem
import SwiftUI

/// The gear's sheet (calo/screens.md → Settings sheet): rows, toggles, daily target, Experiments,
/// Clear daily log, Done. Medium detent; Today's Log and About push inside and raise it to large.
/// The target commits when its field loses focus, on Done and when the sheet goes (E-C09), and is
/// clamped by `Settings` itself.
struct CaloSettingsSheet: View {
    let dash: DashModel
    @Environment(\.calo) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var detent = PresentationDetent.medium
    @State private var path: [Destination] = []
    @State private var settings = Settings.defaults
    @State private var targetText = ""
    @State private var hasEntries = false
    @State private var loaded = false
    @FocusState private var targetFocused: Bool

    enum Destination: Hashable {
        case log, about, experiments
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                List {
                    Section {
                        NavigationLink(value: Destination.log) {
                            Text(L10n.calo.settingsTodayLog)
                        }
                        .accessibilityIdentifier("calo.settings.todayLog")
                        NavigationLink(value: Destination.about) {
                            Text(L10n.calo.settingsAbout)
                        }
                        .accessibilityIdentifier("calo.settings.about")
                    }
                    Section {
                        Toggle(isOn: $settings.showName) { Text(L10n.calo.settingsShowName) }
                            .accessibilityIdentifier("calo.settings.showName")
                        Toggle(isOn: $settings.showDetails) { Text(L10n.calo.settingsShowDetails) }
                            .accessibilityIdentifier("calo.settings.showDetails")
                    }
                    Section {
                        HStack {
                            Text(L10n.calo.settingsTarget)
                            Spacer()
                            TextField("", text: $targetText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($targetFocused)
                                .onSubmit(commitTarget)
                                .accessibilityLabel(Text(L10n.calo.settingsTarget))
                                .accessibilityIdentifier("calo.settings.target")
                        }
                    }
                    Section {
                        NavigationLink(value: Destination.experiments) {
                            // Plain text beside the symbol: a `Label` here is drawn but not exposed to accessibility.
                            HStack(spacing: Tokens.spacing.stack) {
                                Image(systemName: Symbols.experiments).accessibilityHidden(true)
                                Text(L10n.calo.settingsExperiments)
                            }
                        }
                        .accessibilityIdentifier("calo.settings.experiments")
                    }
                }
                // Footer below the list, never an overlay: rows must not be drawn under it. Done lives here
                // (not in the bar) because bar buttons do not scale with Dynamic Type.
                HStack(spacing: Tokens.spacing.stack) {
                    if hasEntries {
                        clearButton
                    }
                    Button { commitTarget(); dismiss() } label: {
                        Text(L10n.calo.settingsDone).frame(maxWidth: .infinity).frame(minHeight: Tokens.size.control)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("calo.settings.done")
                }
                .padding(.horizontal, Tokens.spacing.screen)
                .padding(.vertical, Tokens.spacing.stack)
            }
            .navigationTitle(Text(L10n.calo.brand))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .log: TodayLogScreen(dash: dash)
                case .about: AboutScreen()
                case .experiments: ExperimentsScreen()
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .onChange(of: path) { _, path in
            if path.isEmpty {
                Task { await reloadHasEntries() } // rows may have been deleted in the log
            } else {
                detent = .large
            }
        }
        .onChange(of: settings) { _, settings in
            guard loaded else { return }
            dash.save(settings)
        }
        .onChange(of: targetFocused) { _, focused in
            if !focused {
                commitTarget()
            }
        }
        .onDisappear(perform: commitTarget)
        .task {
            settings = dash.settings
            targetText = String(settings.dailyTarget)
            loaded = true
            await reloadHasEntries()
        }
    }

    private var clearButton: some View {
        TwoTapButton(
            String(localized: L10n.calo.settingsClear),
            confirmTitle: String(localized: L10n.calo.settingsClearConfirm),
            doneTitle: String(localized: L10n.calo.settingsClearDone),
            glass: false,
            action: {
                try? await env.store.clear(in: dash.window)
                await dash.refresh()
                try? await Task.sleep(for: Motion.clearedLinger)
                hasEntries = false
            }
        )
        .accessibilityIdentifier("calo.settings.clear")
    }

    private func reloadHasEntries() async {
        hasEntries = await ((try? env.store.entries(in: dash.window)) ?? []).isEmpty == false
    }

    /// E-C09: empty or non-numeric leaves the value; out of range is clamped by `Settings`.
    private func commitTarget() {
        guard let value = Int(targetText.trimmingCharacters(in: .whitespaces)), value >= 0 else {
            targetText = String(settings.dailyTarget)
            return
        }
        let next = Settings(dailyTarget: value, showName: settings.showName, showDetails: settings.showDetails)
        if next != settings {
            settings = next
        }
        targetText = String(next.dailyTarget)
    }
}

/// The web app's about page (calo/copy.md).
struct AboutScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.spacing.screen) {
                Text(L10n.calo.aboutQuote)
                    .font(.title2.weight(.semibold))
                    .italic()
                Text(L10n.calo.aboutTagline)
                    .font(.headline)
                    .foregroundStyle(Tokens.color.accent)
                Text(L10n.calo.aboutBody)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.spacing.screen)
        }
        .navigationTitle(Text(L10n.calo.brand))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("calo.about")
    }
}
