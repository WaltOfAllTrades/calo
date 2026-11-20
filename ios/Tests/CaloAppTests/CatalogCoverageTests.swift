@testable import Calo
import Foundation
import Testing

/// Every key named in the `L10n` sources resolves in the shipped catalog, so a typo in either file
/// fails here rather than showing a raw key on screen. Reads the sources relative to this file.
struct CatalogCoverageTests {
    private static var sourceRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // CaloAppTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // ios
            .appendingPathComponent("App/Support")
    }

    private static func keys(in file: String) throws -> [String] {
        let text = try String(contentsOf: sourceRoot.appendingPathComponent(file), encoding: .utf8)
        let pattern = #"LocalizedStringResource\("([a-zA-Z0-9.]+)"\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range(at: 1), in: text).map { String(text[$0]) }
        }
    }

    @Test("every static L10n key in L10n.swift and L10n+Calc.swift is in the catalog")
    func allKeysResolve() throws {
        let keys = try Self.keys(in: "L10n.swift") + Self.keys(in: "L10n+Calc.swift")
        #expect(keys.count > 200)
        var missing: [String] = []
        for key in keys {
            let value = String(localized: LocalizedStringResource(String.LocalizationValue(key)))
            if value == key || value.isEmpty {
                missing.append(key)
            }
        }
        #expect(missing.isEmpty, "missing from Localizable.xcstrings: \(missing)")
    }

    @Test("function field, result, help and look keys the views build dynamically are in the catalog")
    func dynamicKeys() {
        let fieldIds = ["rise", "run", "riser", "tread", "headroom", "floorThickness", "riserLimited", "pitch", "span",
                        "spacing", "planLength", "planWidth", "length", "width", "depth", "height", "diameter", "count",
                        "waste", "bag", "thickness", "pricePerMbm", "chord", "arcAngle", "arcLength", "spring",
                        "corner",
                        "radius", "sides", "diagonal"]
        let resultIds = ["risers", "riserHeight", "riserOverage", "treads", "treadDepth", "treadOverage", "totalRun",
                         "totalRise", "stringer", "opening", "incline", "common", "hip", "plumb", "level", "cheek",
                         "jackIncrement", "roofArea", "squares", "bundles", "sheets", "volume", "withWaste", "bags",
                         "boardFeet", "cost", "diagonal", "area", "perimeter", "angle", "circumference", "radius",
                         "arcAngle", "arcLength", "chord", "segment", "pie", "miter", "bevel", "fullAngle", "halfAngle",
                         "side", "studs", "rise", "run", "pitch", "diameter"]
        let helpIds = ["rise", "run", "riser", "tread", "headroom", "floorThickness", "riserLimited", "pitch", "span",
                       "spacing", "waste", "bag", "pricePerMbm", "generic"]
        var missing: [String] = []
        for key in fieldIds.map({ "calc.field.\($0)" }) + resultIds.map({ "calc.result.\($0)" })
            + helpIds.map({ "calc.help.field.\($0)" }) {
            let value = String(localized: LocalizedStringResource(String.LocalizationValue(key)))
            if value == key {
                missing.append(key)
            }
        }
        #expect(missing.isEmpty, "missing from Localizable.xcstrings: \(missing)")
    }
}
