import CaloKit
import Testing

struct MigrationIndexTests {
    @Test("v1 carries the createdAt index the day-window queries rely on (architecture §3)")
    func index() async throws {
        let store = try GRDBLogStore(url: nil)
        let names = try await store.indexNames()
        #expect(names.contains("entry_createdAt"))
    }
}
