import Foundation
import Testing

/// No user-facing literal in a view (architecture §6, code-standards 9): every `Text("…")`,
/// `Label("…")` and `Button("…")` under App/Features must come from the catalog. Reads the sources
/// relative to this file.
struct NoLiteralStringsLint {
    private static var featuresRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Features")
    }

    @Test("Text, Label and Button never take a literal with letters in it")
    func noLiterals() throws {
        let files = try FileManager.default.subpathsOfDirectory(atPath: Self.featuresRoot.path)
            .filter { $0.hasSuffix(".swift") }
        #expect(files.count > 10)
        let pattern = #"(Text|Label|Button)\("([^"\\]*)""#
        let regex = try NSRegularExpression(pattern: pattern)
        var offenders: [String] = []
        for file in files {
            let text = try String(contentsOf: Self.featuresRoot.appendingPathComponent(file), encoding: .utf8)
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range(at: 2), in: text) else { continue }
                let literal = String(text[range])
                if literal.contains(where: \.isLetter) {
                    offenders.append("\(file): \(literal)")
                }
            }
        }
        #expect(offenders.isEmpty, "literals in views: \(offenders)")
    }
}
