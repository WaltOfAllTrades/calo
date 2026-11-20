import CaloKit
import DesignSystem
import SwiftUI

/// Calo's one screen (calo/screens.md → Main): header, Dash, details fields, entry display, keypad.
/// The keypad model enforces the entry rules; this view wires enter to the store and keeps the
/// Dash current (feature C-022). The Dash renders only after its first load, so the numbers never
/// flash 0 / 2000 before the real ones.
struct CaloScreen: View {
    @Environment(\.calo) private var env
    @Environment(\.experiments) private var experiments
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dash: DashModel?
    @State private var keypad = KeypadModel()
    @State private var name = ""
    @State private var details = ""
    @State private var showsSettings = false
    @State private var errorClearTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            CaloBackdrop()
            if let dash {
                GeometryReader { geo in
                    content(dash, height: geo.size.height)
                }
            }
        }
        .task {
            guard dash == nil else { return }
            let model = DashModel(env: env)
            wireKeypad(model)
            await model.refresh()
            dash = model
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, let dash else { return }
            Task { await dash.refresh() }
        }
        .onChange(of: keypad.error) { _, error in
            scheduleErrorClear(error)
            if let text = errorText {
                AccessibilityNotification.Announcement(String(localized: text)).post()
            }
        }
        .onDisappear {
            errorClearTask?.cancel()
            dash?.stopRollover()
        }
        .sensoryFeedback(Haptics.enter, trigger: keypad.enterCount)
        .sensoryFeedback(Haptics.error, trigger: keypad.error) { _, new in new != nil }
        .sheet(
            isPresented: $showsSettings,
            onDismiss: {
                Task { await dash?.refresh() }
                experiments.activate() // a product picked in Experiments switches once the sheet is gone
            },
            content: {
                if let dash {
                    CaloSettingsSheet(dash: dash)
                }
            }
        )
    }

    private func content(_ dash: DashModel, height: CGFloat) -> some View {
        VStack(spacing: Tokens.spacing.stack) {
            CaloHeader(date: dash.window.start, onSettings: { showsSettings = true })
            DashView(totals: dash.totals, error: errorText, compact: dash.settings.showsAnyField)
                .frame(maxHeight: .infinity)
            VStack(spacing: Tokens.spacing.stack) {
                if dash.settings.showsAnyField {
                    DetailsFields(
                        name: $name, details: $details,
                        showName: dash.settings.showName, showDetails: dash.settings.showDetails
                    )
                }
                EntryDisplay(intent: keypad.intent, buffer: keypad.buffer)
                KeypadView(keypad: keypad)
                    .frame(height: KeypadLayout.height(available: height, rows: 5, columns: 4))
            }
        }
        .padding(.horizontal, Tokens.spacing.screen)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
    }

    private var errorText: LocalizedStringResource? {
        switch keypad.error {
        case .busy: L10n.calo.errorBusy
        case .failed: L10n.calo.errorFailed
        case nil: nil
        }
    }

    /// Enter: write through the store with the fields as they are at that moment, clear them,
    /// refresh the Dash (C-022).
    private func wireKeypad(_ dash: DashModel) {
        keypad.onEnter = { [env] signed in
            let entry = Entry(calories: signed, name: name, details: details, createdAt: env.now())
            try await env.store.add(entry)
            name = ""
            details = ""
            await dash.refresh()
        }
    }

    /// The error line clears itself after Motion.errorHold (web: 3 s).
    private func scheduleErrorClear(_ error: KeypadModel.KeypadError?) {
        errorClearTask?.cancel()
        guard error != nil else { return }
        errorClearTask = Task {
            try? await Task.sleep(for: Motion.errorHold)
            guard !Task.isCancelled else { return }
            keypad.clearError()
        }
    }
}

/// How tall a keypad is for the space on screen: the keys want to be squares, at least 44 pt and at
/// most 88 pt, and the keypad never takes more than 62 % of the height so the Dash keeps room
/// (architecture §7: fits 375×667 without scrolling; the Dash shrinks first).
enum KeypadLayout {
    static func height(available: CGFloat, rows: Int, columns _: Int) -> CGFloat {
        let gaps = CGFloat(rows - 1) * Tokens.spacing.keyGap
        let minimum = CGFloat(rows) * Tokens.size.control + gaps
        let maximum = CGFloat(rows) * 88 + gaps
        return min(max(available * 0.62, minimum), maximum)
    }

    /// The side of one square key for a keypad of the given size.
    static func keySide(in size: CGSize, rows: Int, columns: Int) -> CGFloat {
        let w = (size.width - CGFloat(columns - 1) * Tokens.spacing.keyGap) / CGFloat(columns)
        let h = (size.height - CGFloat(rows - 1) * Tokens.spacing.keyGap) / CGFloat(rows)
        return max(Tokens.size.control, min(w, h))
    }
}

/// Brand, the responsive date, the settings gear (screens.md → Main header).
struct CaloHeader: View {
    let date: Date
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: Tokens.spacing.stack) {
            Text(L10n.calo.brand)
                .font(.title2.weight(.bold))
                .lineLimit(1)
            Spacer(minLength: 0)
            ViewThatFits(in: .horizontal) {
                Text(DateText.headerFull(date))
                Text(DateText.headerMedium(date))
                Text(DateText.headerShort(date))
            }
            .font(.subheadline)
            .foregroundStyle(Tokens.color.textFaint)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("calo.header.date")
            Spacer(minLength: 0)
            GlassCircleButton(
                symbol: Symbols.settings,
                label: String(localized: L10n.calo.a11ySettings),
                action: onSettings
            )
            .accessibilityIdentifier("calo.header.settings")
        }
        .frame(minHeight: Tokens.size.control)
    }
}

/// Logged | Remaining with rolling digits and the error line (ontology #dash).
struct DashView: View {
    let totals: DashTotals
    let error: LocalizedStringResource?
    /// Smaller numbers when the details fields are visible (web `has-details`).
    let compact: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Tokens.spacing.stack) {
            HStack(spacing: 0) {
                counter(totals.logged, label: L10n.calo.dashLogged, a11y: L10n.calo.a11yDashLogged(totals.logged))
                    .accessibilityIdentifier("calo.dash.logged")
                Rectangle()
                    .fill(Tokens.color.textFaint.opacity(0.3))
                    .frame(width: 1, height: compact ? 40 : 56)
                counter(
                    totals.remaining, label: L10n.calo.dashRemaining,
                    a11y: L10n.calo.a11yDashRemaining(totals.remaining)
                )
                .accessibilityIdentifier("calo.dash.remaining")
            }
            Text(error ?? "")
                .font(.footnote)
                .foregroundStyle(Tokens.color.negative)
                .frame(minHeight: 18)
                .opacity(error == nil ? 0 : 1)
                .motion(Motion.errorFade, reduceMotion: reduceMotion, value: error == nil)
                .accessibilityIdentifier("calo.dash.error")
                .accessibilityHidden(error == nil)
        }
    }

    private func counter(_ value: Int, label: LocalizedStringResource, a11y: String) -> some View {
        VStack(spacing: 2) {
            RollingNumber(value, font: compact ? Tokens.font.displayCompact : Tokens.font.display)
            Text(label)
                .font(Tokens.font.label)
                .tracking(1.2)
                .foregroundStyle(Tokens.color.textFaint)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11y)
    }
}

/// Intent label left, buffer right (ontology #display). The buffer is always an accessibility
/// element, even when empty, so assistive tech and the UI tests can read it.
struct EntryDisplay: View {
    let intent: Entry.Intent
    let buffer: String

    var body: some View {
        HStack {
            Text(intent == .add ? L10n.calo.intentAdd : L10n.calo.intentSubtract)
                .font(Tokens.font.intent)
                .tracking(1)
                .foregroundStyle(Tokens.color.accent)
                .accessibilityIdentifier("calo.display.intent")
            Spacer()
            Text(buffer.isEmpty ? " " : buffer)
                .font(Tokens.font.buffer)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(buffer)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityIdentifier("calo.display.buffer")
        }
        .frame(minHeight: Tokens.size.control)
    }
}

/// The optional Item and Log details fields (ontology #details).
struct DetailsFields: View {
    @Binding var name: String
    @Binding var details: String
    let showName: Bool
    let showDetails: Bool

    var body: some View {
        VStack(spacing: Tokens.spacing.stack) {
            if showName {
                GlassField(String(localized: L10n.calo.fieldName), text: $name)
                    .accessibilityIdentifier("calo.field.name")
            }
            if showDetails {
                GlassField(String(localized: L10n.calo.fieldDetails), text: $details, lines: 2)
                    .accessibilityIdentifier("calo.field.details")
            }
        }
    }
}
