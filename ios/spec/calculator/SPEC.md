# Construction calculator — build spec

## What it is
A free construction calculator that does what the Construction Master Pro and BuildCalc do, with the
pain points in `pain-points.md` solved: **type a measurement the way it reads off the tape, see exactly
what you typed, get an exact answer rounded once to a denominator you can see and change, and never lose
your work.** Feet-inch-fraction arithmetic to 1/64 and beyond, metric at parity, and the trade functions
(stairs, roof, concrete, board feet, square-up, circles, miters, polygons, studs) as sheets with labelled
fields and results lists.

A separate product from Calo. It shares `DesignSystem` and nothing else (code-standards 16).

## Ground rules
- Native Swift 6 / SwiftUI. iOS 26.0 minimum. iPhone only. Portrait only. English only.
- Liquid Glass is the design system (`../design/liquid-glass.md`).
- Free. No ads, no purchases, no account, no network, no analytics (P-01, P-11). Nothing leaves the phone.
- Exact arithmetic: `Fraction` end to end; `Double` only for trig, roots and metric display, snapped back
  through `Precision` (code-standards 7, P-04, P-10).
- Every formula is tested against a published worked example (`formulas.md`, `tests.md`).

## In scope (v1)
| Area | What ships |
|---|---|
| Engine | Tokens, natural entry (`5′ 3 1/2″`), parentheses, + − × ÷, %, ±, π, dimensional algebra (length, area, volume, scalar, angle), exact evaluation, error states. |
| Display | Expression line; result with a unit chip (cycles formats) and a precision chip (cycles 1/2 … 1/64, exact; shows ≈ when rounding changed the value); tap the result for every format at once. |
| Keypad | 5 × 5 glass keys: `AC ⌫ ( ) ÷ / 7 8 9 × ′ / 4 5 6 − ″ / 1 2 3 + ⁄ / % 0 . ± =`. Hold any key for help. |
| Toolbar pill | Undo, Tape, Functions, Memory (M+ M− MR MC), Settings. |
| Tape | Every `=` as a line (expression, result); tap to reuse the result; swipe to delete; clear all; persists; 200 lines. |
| Memory | One memory with M+, M−, MR, MC; persists. |
| Functions | Stairs, Roof (pitch, common, hip/valley, jacks, roof area), Irregular hip (irregular hip/valley, both jack sets, mate mode), Rake wall, Arched wall (inside and outside), Concrete (slab, footing, column; waste; bags), Board feet (with count and cost), Square-up / diagonal, Circle & arc, Compound miter, Polygon, Studs, Drywall, Blocks & bricks (blocks, bricks, pavers; waste), Balusters, Weight (tons per cubic yard). Each: fields, results list, "Use" to send a result to the keypad, hold-to-see help with a worked example. Added 2026-11-20 on Walt's instruction to reach Construction Master parity. |
| Conversions | Length ft-in / decimal ft / decimal in / yd / mm / cm / m; area sq in / sq ft / sq yd / m²; volume cu in / cu ft / cu yd / m³ / L; angle degrees / pitch (in per 12) / percent grade / D:M:S display. |
| Settings | Unit system (imperial / metric), default precision, stair defaults (riser, tread, headroom, floor thickness, riser limit on/off), concrete waste % and bag size, o.c. spacing, Look (visual option), Experiments (Open as). |
| Persistence | Engine state, memory, settings and tape restored on launch (P-05, P-06). |

## Deliberate choices (logged in PROGRESS.md)
1. **Natural tape entry over the triple keypad.** The three-field keypad is praised for pure fractions; for
   dimensions the research rates "type it as you read it" higher, and it keeps one keypad.
2. **A unitless operand added to a length is read in the base unit** (inches in imperial, millimetres in
   metric) and the expression line shows the unit it was given, so nothing is silent. The Construction
   Master's behaviour here is undocumented; a dimension error would punish the most common slip (E-K04).
3. **Volume results default to cubic yards in imperial** (the Construction Master's "Standard" rule) because
   that is what concrete is ordered in; the unit chip cycles to cu ft, cu in, m³, L.
4. **Rounding is display-only.** Stored values stay exact; the tape stores exact values and shows them at the
   precision in force when reused.
5. **Code limits are shown, not enforced.** Stairs flag a riser over 7¾″, a tread under 10″ or headroom under
   6′ 8″ (IRC R311.7) with a visible warning; the numbers are still given (the research: apps that ship no
   code tables are preferred by pros, apps that hide the answer are not).
6. **Four looks, one default.** `Glass` (default: round glass keys, graphite/paper backdrop), `Tape` (rounded
   square keys, paper tape strip), `Daylight` (maximum contrast, largest keys, no grid), `Blueprint`
   (blueprint-blue backdrop, white grid). Default `Glass` because it is the only one that reads as the system
   design and so needs no explanation; the others exist for Walt to try on site. Switchable in Settings → Look.

## Do not build
- Ads, purchases, subscriptions, "pro" tiers, locked keys, trials, accounts, cloud sync, analytics, crash reporting.
- Apple Watch, iPad layout, landscape, widgets, Siri, Shortcuts, share extensions.
- Projects, saved jobs, labelled results, PDF/CSV export, printing, sharing the tape (a later feature; the tape
  model must stay serialisable).
- Trig keys beyond what the functions need (no sin/cos/tan keys on the keypad); hyperbolic, logs, exponent mode.
- Material estimators not in the Construction Master: paint, tile, decking, fences. The function registry
  must make adding one a new type.
- Cost per unit except board-feet cost.
- "Constant" fraction mode, exponent/overflow modes, Jobber-style sixteenths entry.
- A tutorial, onboarding screens, tips beyond hold-to-see help.
- Haptic or sound customisation; custom fonts.

## Door-keeping rules
1. `CalcKit` imports Foundation only; every function is a pure `static func` on a type in `Functions/`, taking
   and returning `Dimension` / `Fraction` values.
2. `Function` is a protocol (id, title, symbol, fields, help example, `solve(inputs) -> [Result]`); the registry
   is one array; the Functions sheet renders the registry. New functions are new types.
3. `Precision.round(_:)` is the only rounding; `Dimension.formatted(in:precision:)` the only formatter.
4. `EntryEngine` is a plain `@Observable` state machine with no SwiftUI import, fully unit-tested, driven by `Key` values.
5. `Tape`, `Memory` and `CalcPreferences` are `Codable`; `HistoryStore` writes atomically; nothing else touches the files.
6. One strings catalog; views use `L10n.calc.*`. Help text and worked examples live in the catalog too.
7. Looks are values of one `Look` enum read by `DesignSystem`-level style choices; no look-specific view trees.
8. Nothing from "Do not build" is implemented, stubbed or scaffolded.

## Build order (`features.json`)
1. `Dimension`, `Unit`, `Precision`, formatting; `Token`, `EntryEngine`, evaluation; persistence types.
2. Main screen: display, chips, keypad, toolbar pill, hold-to-see help; tape sheet; memory; formats sheet.
3. Functions: registry, sheet, detail sheet; stairs, roof, concrete, board feet, square-up, circle/arc, compound miter, polygon, studs.
4. Settings, looks, Experiments link.
5. UI tests, accessibility audit, briefing.
