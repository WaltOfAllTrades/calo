@testable import Calo
import Testing

/// Hosted in the app; the app target is MainActor by default, and so is `KeypadModel`.
@MainActor
struct KeypadModelTests {
    @Test("digits and bonus keys append; the buffer caps at five characters as a whole (E-C04)")
    func bufferCap() {
        let model = KeypadModel()
        model.press(.bonus("80"))
        model.press(.bonus("80"))
        #expect(model.buffer == "8080")
        model.press(.bonus("80")) // would make 6: ignored whole
        #expect(model.buffer == "8080")
        model.press(.digit("00")) // would make 6: ignored
        #expect(model.buffer == "8080")
        model.press(.digit("1"))
        #expect(model.buffer == "80801")
        #expect(model.value == 80801)
    }

    @Test("backspace and clear")
    func editing() {
        let model = KeypadModel()
        model.press(.digit("2"))
        model.press(.digit("5"))
        model.press(.backspace)
        #expect(model.buffer == "2")
        model.press(.backspace)
        model.press(.backspace)
        #expect(model.buffer == "")
        model.press(.digit("9"))
        model.press(.clear)
        #expect(model.buffer == "")
        #expect(model.value == nil)
    }

    @Test("enter logs the signed value, clears, resets the intent")
    func enter() async {
        let model = KeypadModel()
        var logged: [Int] = []
        model.onEnter = { logged.append($0) }
        model.press(.subtract)
        #expect(model.intent == .subtract)
        model.press(.digit("1"))
        model.press(.digit("0"))
        model.press(.digit("0"))
        await model.enter()
        #expect(logged == [-100])
        #expect(model.buffer == "")
        #expect(model.intent == .add)
        #expect(model.error == nil)
    }

    @Test("empty buffer: enter does nothing, intent kept (E-C05)")
    func emptyEnter() async {
        let model = KeypadModel()
        var calls = 0
        model.onEnter = { _ in calls += 1 }
        model.press(.subtract)
        await model.enter()
        #expect(calls == 0)
        #expect(model.intent == .subtract)
    }

    @Test("zeros only: enter clears and resets, stores nothing (E-C03)")
    func zeros() async {
        let model = KeypadModel()
        var calls = 0
        model.onEnter = { _ in calls += 1 }
        model.press(.subtract)
        model.press(.digit("00"))
        model.press(.digit("0"))
        await model.enter()
        #expect(calls == 0)
        #expect(model.buffer == "")
        #expect(model.intent == .add)
    }

    @Test("a failed write keeps the buffer and intent and shows the failure (E-C02)")
    func failure() async {
        let model = KeypadModel()
        struct Boom: Error {}
        model.onEnter = { _ in throw Boom() }
        model.press(.subtract)
        model.press(.digit("5"))
        await model.enter()
        #expect(model.error == .failed)
        #expect(model.buffer == "5")
        #expect(model.intent == .subtract)
        model.clearError()
        #expect(model.error == nil)
    }

    @Test("a second enter while logging is refused with the busy message (E-C01); the first clears at once")
    func busy() async {
        let model = KeypadModel()
        let gate = AsyncStream<Void>.makeStream()
        model.onEnter = { _ in
            for await _ in gate.stream {
                break
            }
        }
        model.press(.digit("7"))
        let first = Task { await model.enter() }
        await Task.yield()
        await Task.yield()
        #expect(model.isLogging)
        #expect(model.buffer == "") // cleared before the write, so new typing is never lost
        model.press(.digit("3"))
        await model.enter()
        #expect(model.error == .busy)
        #expect(model.buffer == "3")
        gate.continuation.yield()
        gate.continuation.finish()
        await first.value
        #expect(model.isLogging == false)
        #expect(model.buffer == "3")
        #expect(model.enterCount == 1)
    }

    @Test("a failed write restores the buffer only if nothing new was typed")
    func failureAfterTyping() async {
        let model = KeypadModel()
        struct Boom: Error {}
        let gate = AsyncStream<Void>.makeStream()
        model.onEnter = { _ in
            for await _ in gate.stream {
                break
            }
            throw Boom()
        }
        model.press(.digit("5"))
        let first = Task { await model.enter() }
        await Task.yield()
        await Task.yield()
        model.press(.digit("9"))
        gate.continuation.yield()
        gate.continuation.finish()
        await first.value
        #expect(model.error == .failed)
        #expect(model.buffer == "9")
    }

    @Test("the layout is the web app's grid")
    func layout() {
        #expect(KeypadModel.Key.layout.count == 20)
        #expect(KeypadModel.Key.layout.first == .add)
        #expect(KeypadModel.Key.layout.last == .enter)
    }
}
