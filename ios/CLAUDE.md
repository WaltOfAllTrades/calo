# Calo iOS (`ios/`)

Native Swift 6 / SwiftUI, iOS 26, Liquid Glass. Two separate products in one install:
**Calo** (the calorie tracker, a port of the web app in `../src/`) and the **construction calculator**.
Decided 2026-11-20 from Walt's goal (`../GOAL.md`).

**The specification is `spec/`.** Read `spec/README.md` first. `spec/` is read-only to the build loop;
only Walt changes it. Nothing outside `spec/` describes what the apps do.
Status and resume point: `SETUP_STATUS.md`. Running log of decisions and device results: `PROGRESS.md`.

## How to work here (Walt's standing instruction)
- Be agentic. Walt runs long unattended sessions and does not want to be asked for routine approvals.
  Make the decision, log it in `PROGRESS.md`, keep going. Ask only for the items under "Fixed values".
- Walt is an OOP beginner by his own description. Explain the reasoning behind structural choices in
  commit messages and `PROGRESS.md`. If something he asks for looks wrong, say so and offer the alternative.
- When the spec and an Apple page disagree: stop on that item, log it, pick the spec, move on. Never silently pick.

## Session protocol (the loop)
1. Read `SETUP_STATUS.md`, `PROGRESS.md`, then `spec/calo/features.json` and `spec/calculator/features.json`.
   Pick the first entry whose `passes` is false and whose `dependsOn` all pass. Calo's list before the calculator's.
2. Work on branch `ios` (or a short `ios/<F-id>-<slug>` branch merged back into `ios`). Small commits.
   `./scripts/verify.sh` must exit 0 before a PR to `main`.
3. Flip `passes` to `true` only with `./scripts/pass-feature.sh <id>` after a green `verify.sh`.
   Never edit or delete a `features.json` entry; add a note in `PROGRESS.md` instead.
4. PRs to `main` with `gh pr create`; merge your own (`gh pr merge --squash --delete-branch` is **not** used for
   `ios` while it is the long-lived branch: merge with a merge commit and keep the branch). `main` always
   builds and passes `verify.sh`; the web app's Pages deploy on `main` must stay untouched (nothing outside `ios/`
   changes except `GOAL.md`, `CLAUDE.md` at the root, and `.gitignore`).

## Fixed values: never change without asking the user
- Bundle ID: `com.waltofalltrades.calo` (tests: `.tests`, `.uitests`). One App ID for both products for now.
- Team: `Z3W92U6PBC`, "Walter Wear (Personal Team)", free, automatic signing.
- Never edit the bundle ID, DEVELOPMENT_TEAM, CODE_SIGN_STYLE or entitlements to work around an error.
  Report it verbatim, diagnose, then ask. Free accounts get only 10 App IDs per 7 days.

## Commands (run inside `ios/`)
- Full gate before every PR: `./scripts/verify.sh` (protected files, package boundaries, lint, xcodegen, build,
  unit + UI tests on one simulator, no skips, counts not below `.verify/last-green.txt`).
- Record a passing feature: `./scripts/pass-feature.sh C-0xx` / `K-0xx`.
- Tests live in `Tests/<Package>Tests`, `Tests/CaloAppTests` and `UITests/`; they are Xcode test targets.
- On device / renew the 7-day profile: `./scripts/refresh-device.sh` (cable or same Wi-Fi; phone unlocked, Developer Mode on).
- Project generator: XcodeGen (`project.yml` → generated, gitignored `.xcodeproj`). Packages in `Packages/`, committed.

## Layout (`spec/engineering/architecture.md`)
`App/` (entry, root switch, `Features/Calo`, `Features/Calculator`, `Features/Experiments`),
`Packages/{DesignSystem,CaloKit,CalcKit}`, `Tests/`, `UITests/`, `scripts/`, `spec/`, `research/`.
- `CalcKit` imports Foundation only. `CaloKit` imports Foundation and GRDB. `DesignSystem` imports SwiftUI.
  `CaloKit` and `CalcKit` never import each other (the two products share nothing but DesignSystem).
- `CaloKit`, `CalcKit` are not MainActor; App and `DesignSystem` are. Each `Package.swift` sets language mode 6 and isolation.

## Simulators (Xcode 27.2, iOS 27.2 runtime)
- Default `iPhone 17`. Check names with `xcrun simctl list devices available`.

## Machine limits (MacBook Air M2, 8 GB RAM)
- One simulator and one xcodebuild at a time; `-parallel-testing-enabled NO`; `xcrun simctl shutdown all` when idle.
- Curata (`~/Developer/Curata`) may be building in another session: `verify.sh` waits for other xcodebuilds.

## Free tier (Personal Team): hard rules
- Development signing only. Profiles expire 7 days after issue. Caps: 3 devices, 10 App IDs per 7 days, 3 apps per device.
- NEVER add: Push Notifications, In-App Purchase, Sign in with Apple, NFC, iCloud/CloudKit, Apple Pay, Associated Domains,
  Game Center, WeatherKit, Siri, Network Extensions, App Attest. App Store Connect is unavailable.

## Coding rules
- Swift 6, SwiftUI, iOS 26.0 minimum, iPhone, portrait only. Follow `spec/engineering/code-standards.md`.
- Nothing from either SPEC's "Do not build" ships on by default.
- Swift Testing for unit tests, XCUITest for UI tests. Logic lives in the packages, not in views.
- Tests are not edited to pass. `Tests/`, `UITests/`, `scripts/verify.sh`, `scripts/pass-feature.sh`, the hook and the
  test settings in `project.yml` are read-only once on `main`, except in the skeleton features that create them.
  Enforced by the PreToolUse hook `scripts/hooks/protect-paths.sh` and by `verify.sh` step 1.
- Never print, log or commit secrets. Public repo: no personal data in commits, fixtures or screenshots.
- `PrivacyInfo.xcprivacy` from the first commit (UserDefaults is a required-reason API).
