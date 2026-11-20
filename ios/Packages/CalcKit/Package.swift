// swift-tools-version: 6.2
// CalcKit: the construction calculator's engine. Imports Foundation only (architecture §2), so every
// formula is a pure function testable without a simulator. Not MainActor (architecture §4).
// Never imports CaloKit: the two products share nothing but DesignSystem (code-standards 16).
import PackageDescription

let package = Package(
    name: "CalcKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CalcKit", targets: ["CalcKit"]),
    ],
    targets: [
        .target(
            name: "CalcKit",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(nil),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
    ]
)
