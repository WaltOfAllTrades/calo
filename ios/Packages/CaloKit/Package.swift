// swift-tools-version: 6.2
// CaloKit: the calorie tracker's domain and persistence. The ONLY package that imports GRDB
// (architecture §2). Not MainActor (architecture §4): database work runs off the main actor.
// Never imports CalcKit: the two products share nothing but DesignSystem (code-standards 16).
import PackageDescription

let package = Package(
    name: "CaloKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CaloKit", targets: ["CaloKit"]),
    ],
    dependencies: [
        // Pinned exactly: the generated .xcodeproj (and its Package.resolved) is gitignored,
        // so the pin lives here to make every checkout build the same GRDB.
        .package(url: "https://github.com/groue/GRDB.swift", exact: "7.12.0"),
    ],
    targets: [
        .target(
            name: "CaloKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(nil),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
    ]
)
