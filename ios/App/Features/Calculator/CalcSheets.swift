import CalcKit
import DesignSystem
import SwiftUI

/// Every format of the result at once (screens.md → Formats sheet; P-08).
struct FormatsSheet: View {
    let model: CalculatorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.formats(), id: \.unit) { entry in
                    HStack {
                        Text(entry.formatted.text).monospacedDigit()
                        Spacer()
                        Button { UIPasteboard.general.string = entry.formatted.text } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text(L10n.calc.formatsCopy))
                        Button {
                            if let result = model.result {
                                model.insert(result)
                            }
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.down.to.line")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text(L10n.calc.formatsUse))
                    }
                    .accessibilityIdentifier("calc.formats.\(entry.unit.rawValue)")
                }
                if let result = model.result {
                    Section {
                        LabeledContent { Text(result.value.description).monospacedDigit() } label: {
                            Text(L10n.calc.formatsExact)
                        }
                    }
                }
            }
            .navigationTitle(Text(L10n.calc.formatsTitle))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

/// The tape (screens.md → Tape sheet; P-06): tap to reuse, swipe to delete, Clear.
struct TapeSheet: View {
    let model: CalculatorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.tape.isEmpty {
                    ContentUnavailableView { Text(L10n.calc.tapeEmpty) } description: { EmptyView() }
                        .accessibilityIdentifier("calc.tape.empty")
                } else {
                    List {
                        ForEach(Array(model.tape.lines.enumerated()), id: \.element.id) { index, line in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.expression).font(.footnote).foregroundStyle(Tokens.color.textFaint)
                                    .lineLimit(1)
                                HStack {
                                    Text(model.text(for: line)).font(.body.weight(.semibold)).monospacedDigit()
                                    Spacer()
                                    Text(DateText.time(line.date)).font(.caption)
                                        .foregroundStyle(Tokens.color.textFaint)
                                }
                            }
                            .contentShape(.rect)
                            .onTapGesture {
                                model.insert(line.result)
                                dismiss()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction {
                                model.insert(line.result)
                                dismiss()
                            }
                            .accessibilityIdentifier("calc.tape.row.\(index)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { model.deleteTapeLine(id: line.id) } label: {
                                    Label { Text(L10n.calc.tapeDelete) } icon: { Image(systemName: Symbols.trash) }
                                }
                                .accessibilityIdentifier("calc.tape.delete.\(index)")
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text(L10n.calc.tapeTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { model.clearTape() } label: { Text(L10n.calc.tapeClear) }
                        .disabled(model.tape.isEmpty)
                        .accessibilityIdentifier("calc.tape.clear")
                }
            }
        }
        .presentationDetents([.large])
    }
}
