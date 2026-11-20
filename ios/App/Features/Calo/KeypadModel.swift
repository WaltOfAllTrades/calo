import CaloKit
import Foundation
import Observation

/// The keypad's state machine (ontology #keypad; SPEC door-keeping 4): buffer, intent, enter.
/// Plain and testable; it knows nothing about views. Every key but enter applies synchronously, so
/// taps keep their order (E-C16). Enter clears the buffer and resets the intent *before* the write,
/// as the web app did, so nothing typed during the write is lost; a failed write puts the buffer and
/// intent back for a retry (E-C02; calo/SPEC.md deviation 6).
@Observable
final class KeypadModel {
    /// The web app's limit: five characters, whatever key produced them.
    static let maxBufferLength = 5

    private(set) var buffer = ""
    private(set) var intent = Entry.Intent.add
    /// The error line's text key, or nil when clear.
    private(set) var error: KeypadError?
    private(set) var isLogging = false
    /// Counts successful enters, for the haptic trigger.
    private(set) var enterCount = 0

    /// What enter asks of the owner: log this signed value. Throws on failure.
    var onEnter: (Int) async throws -> Void = { _ in }

    enum KeypadError: Equatable {
        case busy, failed
    }

    enum Key: Equatable {
        case digit(String) // "0"…"9", "00"
        case bonus(String) // "80", "60", "40", "20"
        case add, subtract, clear, backspace, enter

        /// Keys in the web app's grid order (screens.md → Main).
        static let layout: [Key] = [
            .add, .subtract, .clear, .backspace,
            .bonus("80"), .digit("7"), .digit("8"), .digit("9"),
            .bonus("60"), .digit("4"), .digit("5"), .digit("6"),
            .bonus("40"), .digit("1"), .digit("2"), .digit("3"),
            .bonus("20"), .digit("00"), .digit("0"), .enter,
        ]
    }

    /// The typed magnitude, or nil when the buffer is empty.
    var value: Int? {
        buffer.isEmpty ? nil : Int(buffer)
    }

    /// Applies a key. Enter starts its write and returns; `enter()` is the awaitable form.
    func press(_ key: Key) {
        switch key {
        case let .digit(text), let .bonus(text):
            append(text)
        case .add:
            intent = .add
        case .subtract:
            intent = .subtract
        case .clear:
            buffer = ""
        case .backspace:
            buffer = String(buffer.dropLast())
        case .enter:
            Task { await enter() }
        }
    }

    func clearError() {
        error = nil
    }

    /// E-C04: a key that would push the buffer past five characters is ignored whole.
    private func append(_ text: String) {
        let next = buffer + text
        guard next.count <= Self.maxBufferLength else { return }
        buffer = next
    }

    func enter() async {
        guard let value else { return } // E-C05
        if value == 0 { // E-C03: zeros clear and reset, nothing stored
            buffer = ""
            intent = .add
            return
        }
        if isLogging { // E-C01
            error = .busy
            return
        }
        let typed = (buffer, intent)
        buffer = ""
        intent = .add
        isLogging = true
        error = nil
        defer { isLogging = false }
        do {
            try await onEnter(typed.1.signedCalories(value))
            enterCount += 1
        } catch {
            // E-C02: put the entry back so a retry is one tap, unless the user has typed since.
            if buffer.isEmpty {
                buffer = typed.0
                intent = typed.1
            }
            self.error = .failed
        }
    }
}
