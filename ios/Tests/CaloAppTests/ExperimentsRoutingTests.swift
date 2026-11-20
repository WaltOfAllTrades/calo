@testable import Calo
import Foundation
import Testing

/// Experiments: Open as defaults to Calo, persists, and the launch argument overrides (C-040).
@MainActor
struct ExperimentsRoutingTests {
    private func suite() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "calo.experiments.tests.\(UUID().uuidString)"))
    }

    @Test("defaults to Calo and persists a change; the switch waits for activate()")
    func defaultsAndPersistence() throws {
        let defaults = try suite()
        let store = ExperimentsStore(defaults: defaults, arguments: [])
        #expect(store.openAs == .calo)
        #expect(store.active == .calo)
        store.save(Experiments(openAs: .calculator))
        #expect(store.openAs == .calculator)
        #expect(store.active == .calo)
        store.activate()
        #expect(store.active == .calculator)
        let reopened = ExperimentsStore(defaults: defaults, arguments: [])
        #expect(reopened.active == .calculator)
    }

    @Test("the launch argument wins over the stored value")
    func launchArgument() throws {
        let defaults = try suite()
        ExperimentsStore(defaults: defaults, arguments: []).save(Experiments(openAs: .calculator))
        let forced = ExperimentsStore(defaults: defaults, arguments: ["-calo.openAs", "calo"])
        #expect(forced.active == .calo)
        let bad = ExperimentsStore(defaults: defaults, arguments: ["-calo.openAs", "nonsense"])
        #expect(bad.active == .calculator)
    }

    @Test("unknown keys decode to defaults")
    func decoding() throws {
        let data = Data(#"{"openAs": "calculator", "later": true}"#.utf8)
        #expect(try JSONDecoder().decode(Experiments.self, from: data).openAs == .calculator)
        let garbage = Data(#"{"openAs": "watch"}"#.utf8)
        #expect(try JSONDecoder().decode(Experiments.self, from: garbage).openAs == .calo)
    }
}
