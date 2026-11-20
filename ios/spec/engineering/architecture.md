# Architecture (both products)

## Why boundaries are enforced by the compiler
Agents follow rules the build enforces far better than rules in a document. Every code-standards rule that
can be a package boundary is one, and `scripts/verify.sh` step 2 checks the import lists below.

## 1. App pattern
- `@Observable` model and service objects, provided through the SwiftUI Environment.
- Logic in plain, testable types inside the packages. Screens hold layout and bindings.
- A screen model exists only where a screen has real logic: the Calo keypad entry, the calculator engine.
- No TCA or other architecture framework. No third-party SDKs except GRDB.

## 2. Layout
```
ios/
├── project.yml                  XcodeGen. The .xcodeproj is generated and gitignored.
├── CLAUDE.md  PROGRESS.md  SETUP_STATUS.md
├── scripts/                     verify.sh, pass-feature.sh, refresh-device.sh, hooks/protect-paths.sh
├── spec/                        this spec
├── research/                    sourced research (features.md, reviews.md)
├── App/                         thin: entry, root switch, wiring, Localizable.xcstrings, PrivacyInfo.xcprivacy
│   └── Features/
│       ├── Calo/                Calo screens and screen models
│       ├── Calculator/          calculator screens and screen models
│       └── Experiments/         the Settings → Experiments section shared by both (which product opens)
├── Packages/
│   ├── DesignSystem/            tokens, glass components, Motion, Haptics, Symbols. Imports SwiftUI.
│   ├── CaloKit/                 Calo domain + persistence: Entry, Settings, LogStore (GRDB). Imports Foundation, GRDB, OSLog.
│   └── CalcKit/                 calculator engine: Dimension, Fraction, Unit, Entry state machine, functions,
│                                History store (JSON file). Imports Foundation only.
├── Tests/                       DesignSystemTests, CaloKitTests, CalcKitTests, CaloAppTests (hosted)
└── UITests/
```

| Package | Contains | May import | Must not import |
|---|---|---|---|
| `DesignSystem` | tokens, glass components, `Motion`, `Haptics`, `Symbols` | Foundation, SwiftUI | CaloKit, CalcKit |
| `CaloKit` | `Entry`, `Settings`, `LogStore` (protocol + GRDB + in-memory), `DayWindow`, `DashTotals` | Foundation, GRDB, OSLog | SwiftUI, CalcKit |
| `CalcKit` | `Fraction`, `Dimension`, `Unit`, `Precision`, `EntryEngine`, `Functions` (stairs, roof, concrete…), `Tape`, `Memory`, `HistoryStore` | Foundation, OSLog | SwiftUI, GRDB, CaloKit |
| App | screens, screen models, wiring | everything | — |

Why each boundary exists:
- `CalcKit` imports nothing but Foundation → every formula is a pure function and its tests need no simulator.
- `CaloKit` owns the database → one place writes entries; the in-memory store runs every test and the UI tests.
- `CaloKit` and `CalcKit` never meet → the products stay separable into two App IDs later (GOAL: "keep the seam clean").
- Only `DesignSystem` is shared → one glass vocabulary, two products.

## 3. Storage
### Calo: GRDB (SQLite)
Decision 2026-11-20 (logged in PROGRESS.md): GRDB over SwiftData. Reasons: explicit migrations; an in-memory
`DatabaseQueue` makes every test and UI test hermetic; the toolchain is proven in Curata on this machine;
no model-container actor quirks. Walt's web schema is mirrored, not imported.
- Table `entry`: `id INTEGER PK`, `calories INTEGER NOT NULL` (signed: add positive, subtract negative),
  `name TEXT NOT NULL DEFAULT ''`, `details TEXT NOT NULL DEFAULT ''`, `createdAt DATETIME NOT NULL`,
  `updatedAt DATETIME NOT NULL`. Index on `createdAt`.
- Migration `v1` on day one; never edited. Later changes are new migrations.
- File: Application Support/`calo.sqlite`, file protection `completeUntilFirstUserAuthentication`.
- "Today" is the device calendar's day containing `now` in the current time zone (`DayWindow`), computed in
  `CaloKit`, so the midnight rollover and the UI tests (which pin `now`) agree.
- Settings: one `Codable` struct (`dailyTarget: Int = 2000`, `showName: Bool = false`, `showDetails: Bool = false`)
  as JSON in `UserDefaults`; missing keys decode to defaults.

### Calculator: JSON files, no database
- `HistoryStore`: the last 200 tape lines as JSON in Application Support/`calc-history.json`, written atomically.
- `Memory` (M+, M−, MR, MC) and the current precision/unit mode: JSON in `UserDefaults` through one `CalcPreferences`
  struct, so a relaunch restores them (pain point P-05 "memory clears").

### Shared
- `Experiments` (which product opens, and each product's visual options): one `Codable` struct in `UserDefaults`
  under its own key. Each product reads only its own fields.

## 4. Concurrency
- Swift 6 language mode. Approachable Concurrency on. App target and `DesignSystem`: default MainActor isolation.
- `CaloKit`, `CalcKit`: not MainActor. `Sendable` value types; `LogStore` is an actor over a `DatabaseQueue`.
- Each `Package.swift` sets its isolation and language mode explicitly.

## 5. Testing
- Swift Testing for unit tests. Suites sharing a database are `@Suite(.serialized)`.
- XCUITest for flows, listed per product in `tests.md`. The app under UI test runs with
  `-calo.uitest` (in-memory store, pinned `now`, seeded entries) or `-calc.uitest` (empty history, pinned prefs).
- Every formula test cites the published worked example it checks (URL or document and page in a comment).
- `scripts/verify.sh`: protected files → boundaries → lint → xcodegen → build → unit tests → UI tests → result
  checks (no skips, no expected failures, counts not below the last green run).

## 6. Must-dos
- `PrivacyInfo.xcprivacy` from the first commit: no tracking, no data collected, required-reason entry for UserDefaults.
- Accessibility floor: every icon-only control has an `accessibilityLabel`; Dynamic Type up to the accessibility
  sizes does not clip the keypads (they scale, the labels do not); Reduce Motion honored through `Motion`;
  Increase Contrast and Reduce Transparency checked in the UI audit.
- Strings: one `Localizable.xcstrings`; no user-facing literal in a view (`L10n` enum); one date/time formatter per product.
- Logging: `OSLog` only. Never log entry text or calculator input.
- Portrait only: `UISupportedInterfaceOrientations` = portrait. iPhone only (`TARGETED_DEVICE_FAMILY = 1`);
  iPad compatibility mode must not crash (one launch smoke test).
- No network. No accounts. No analytics. Nothing leaves the phone.

## 7. Devices
- Simulator for `verify.sh`: `iPhone 17`. Walt's phone: iPhone 15 Pro Max.
- Layout rules: no fixed frames; respect safe areas; both keypads must fit a 375×667 pt screen without scrolling.
