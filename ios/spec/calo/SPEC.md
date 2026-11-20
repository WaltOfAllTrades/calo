# Calo (native) — build spec

## What it is
The web app in `../../../src/` ported to a native iOS app with Liquid Glass: **three-second calorie logging.**
Type a number, tap enter, see today's logged and remaining roll. Nothing else gets in the way.

Identical in function to the web app as of commit `98239ff` (2026-04-02), with the deviations listed below.

## Ground rules
- Native Swift 6 / SwiftUI. iOS 26.0 minimum. iPhone only. Portrait only. English only.
- Liquid Glass is the design system (`../design/liquid-glass.md`). Keys and controls are system glass.
- Local storage only (GRDB, `../engineering/architecture.md` §3). No network, accounts, analytics or SDKs beyond GRDB.
- Free Personal Team: no paid capabilities.

## In scope (v1)
| Area | What ships |
|---|---|
| Main | Header (brand, today's date, gear), Dash (Logged, Remaining, error line), Details fields (per settings), Entry display, Keypad. |
| Logging | Enter logs the buffer with the intent; busy guard; failure message; fields clear; intent resets; dash rolls. |
| Day | Day window in the device zone; rollover at midnight and on foreground. |
| Settings | Sheet: Today's Log, About, Show item name, Show log details, Daily target, Clear daily log (two-tap), Done, Experiments. |
| Today's Log | Time, Cal, Item (if any), Details (if any); tap to edit; swipe to delete; empty state. |
| About | The web app's text. |
| Experiments | Open as: Calo / Calculator (shared with the calculator; `../calculator/SPEC.md`). |

## Deviations from the web app (decided 2026-11-20, each logged in PROGRESS.md)
1. **"Reports" is not ported.** The web button closes the overlay and does nothing. A dead control is a placeholder (code-standards 10).
2. **A buffer of only zeros is not logged.** Enter with value 0 clears the buffer and does nothing else (E-C03). The web app stored a 0-calorie row.
3. **Delete is a swipe action**, edit is a tap; the web app showed ✎ ✕ on tap. Same functions, the platform's gesture.
4. **Light mode exists.** The web app was dark only; the native app follows the system appearance with the same night palette in dark.
5. **Settings is a sheet** (medium detent, pages push inside it) instead of a modal card.
Everything else matches: key layout and labels, bonus values, 5-character buffer, intent reset after enter,
daily target 2000 and its 0…99999 range, field visibility rules, the error strings, the about text,
clear-daily-log only when today has entries and its two-tap confirmation.

## Do not build
- Reports, charts, history beyond today, weekly totals, streaks, badges.
- Food database, search, barcode scan, HealthKit, Apple Watch, widgets, Siri, Live Activities.
- Accounts, sync, iCloud, export, import of the web app's IndexedDB data.
- Reminders or notifications of any kind.
- Themes beyond the system appearance; custom fonts (the web app's IBM Plex is not bundled).
- Landscape, iPad layout.
- Any calculator functionality inside Calo screens (the two products share nothing but DesignSystem).

## Door-keeping rules
1. `CaloKit` imports Foundation, GRDB, OSLog only; nothing in `App/Features/Calo` imports GRDB or CalcKit.
2. `LogStore` is a protocol with a GRDB implementation and an in-memory implementation; the UI tests use the latter.
3. `DayWindow` is the only definition of today. `Entry.signedCalories` is the only sign rule.
4. `KeypadModel` (buffer, intent, enter) is a plain `@Observable` type with no SwiftUI import, fully unit-tested.
5. Settings is one `Codable` struct with defaults; unknown keys ignored.
6. One strings catalog; views use `L10n.calo.*`. One `DateText` for the header date and the log's time column.
7. Motion and tokens are referenced, never inlined.
8. Nothing from "Do not build" is implemented, stubbed or scaffolded.

## Build order (`features.json`)
1. Skeleton: `project.yml`, packages, test targets, privacy manifest, strings catalog, `verify.sh`, hooks.
2. `DesignSystem`: tokens, Motion, Haptics, Symbols, `GlassKey`, `RollingNumber`, `GlassField`, `TwoTapButton`, backdrops.
3. `CaloKit`: `Entry`, `Entry.Intent`, `DayWindow`, `Settings`, `LogStore` (GRDB + memory), totals.
4. `KeypadModel`.
5. Main screen and the logging flow, rollover.
6. Settings sheet, Today's Log, About.
7. Experiments (Open as) and the root switch.
8. UI tests, accessibility audit, iPad smoke, `refresh-device.sh`, briefing.
