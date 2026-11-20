import CaloKit
import DesignSystem
import SwiftUI

/// Today's entries (calo/screens.md → Today's Log): tap to edit, swipe to delete, empty state.
struct TodayLogScreen: View {
    let dash: DashModel
    @Environment(\.calo) private var env
    @State private var rows: [Entry] = []
    @State private var editing: Entry?

    private var hasName: Bool {
        rows.contains { !$0.name.isEmpty }
    }

    private var hasDetails: Bool {
        rows.contains { !$0.details.isEmpty }
    }

    var body: some View {
        List {
            Section {
                if rows.isEmpty {
                    Text(L10n.calo.logEmpty)
                        .foregroundStyle(Tokens.color.textFaint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityIdentifier("calo.log.empty")
                } else {
                    header
                    ForEach(rows) { entry in
                        Button { editing = entry } label: { row(entry) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("calo.log.row.\(entry.id)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { await delete(entry) }
                                } label: {
                                    Label { Text(L10n.calo.logDelete) } icon: { Image(systemName: Symbols.trash) }
                                }
                                .accessibilityIdentifier("calo.log.delete.\(entry.id)")
                            }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.calo.logTitle).font(.title2.weight(.bold)).foregroundStyle(Tokens.color.text)
                    Text(L10n.calo.logSubtitle).font(.footnote)
                }
                .textCase(nil)
                .padding(.bottom, 4)
            }
        }
        .navigationTitle(Text(L10n.calo.brand))
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .onChange(of: dash.window) { _, _ in Task { await reload() } } // E-C07: a new day while open
        .sheet(item: $editing) { entry in
            EditEntrySheet(entry: entry, onSave: { calories, name, details in
                try? await env.store.update(
                    id: entry.id,
                    calories: calories,
                    name: name,
                    details: details,
                    now: env.now()
                )
                await reload()
                await dash.refresh()
            })
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.calo.logColumnTime).frame(width: 72, alignment: .leading)
            Text(L10n.calo.logColumnCalories).frame(width: 56, alignment: .trailing)
            if hasName {
                Text(L10n.calo.logColumnName).frame(maxWidth: .infinity, alignment: .leading)
            }
            if hasDetails {
                Text(L10n.calo.logColumnDetails).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Tokens.color.textFaint)
    }

    private func row(_ entry: Entry) -> some View {
        HStack {
            Text(DateText.time(entry.createdAt)).frame(width: 72, alignment: .leading)
            Text(signed(entry.calories))
                .monospacedDigit()
                .foregroundStyle(entry.calories < 0 ? Tokens.color.negative : Tokens.color.text)
                .frame(width: 56, alignment: .trailing)
            if hasName {
                Text(entry.name).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            }
            if hasDetails {
                Text(entry.details).frame(maxWidth: .infinity, alignment: .leading).lineLimit(2)
            }
        }
        .contentShape(.rect)
    }

    private func signed(_ calories: Int) -> String {
        calories >= 0 ? "+\(calories)" : "\u{2212}\(abs(calories))"
    }

    private func reload() async {
        rows = await (try? env.store.entries(in: dash.window)) ?? []
    }

    private func delete(_ entry: Entry) async {
        try? await env.store.delete(id: entry.id)
        await reload()
        await dash.refresh()
    }
}

/// Edit entry (calo/screens.md): calories, item, details; Save validates an integer (E-C10).
struct EditEntrySheet: View {
    let entry: Entry
    let onSave: (Int, String, String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var caloriesText = ""
    @State private var name = ""
    @State private var details = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: L10n.calo.editCalories), text: $caloriesText)
                    .keyboardType(.numbersAndPunctuation)
                    .accessibilityIdentifier("calo.edit.calories")
                TextField(String(localized: L10n.calo.editName), text: $name)
                    .accessibilityIdentifier("calo.edit.name")
                TextField(String(localized: L10n.calo.editDetails), text: $details, axis: .vertical)
                    .lineLimit(2 ... 4)
                    .accessibilityIdentifier("calo.edit.details")
            }
            .navigationTitle(Text(L10n.calo.editTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(L10n.calo.editCancel) }
                        .accessibilityIdentifier("calo.edit.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) { Text(L10n.calo.editSave) }
                        .accessibilityIdentifier("calo.edit.save")
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            caloriesText = String(entry.calories)
            name = entry.name
            details = entry.details
        }
    }

    private func save() {
        guard let calories = Int(caloriesText.trimmingCharacters(in: .whitespaces)) else { return }
        let name = name, details = details
        Task {
            await onSave(calories, name, details)
            dismiss()
        }
    }
}
