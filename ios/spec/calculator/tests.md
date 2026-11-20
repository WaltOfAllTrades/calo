# Calculator — tests

Swift Testing unless marked UI. Every formula test names its oracle id from `formulas.md` in a comment.

## CalcKit (`Tests/CalcKitTests`)
- `FractionTests`: reduce, sign, arithmetic, rounding, decimal parse, overflow → nil.
- `DimensionTests`: construction from ft/in/frac; metric exactness (1 in = 254/10 mm); algebra table §1 incl. mismatch errors; percent rules D18–D21.
- `PrecisionAndFormatTests`: D2 (45/64 at each precision), D3–D9 conversions, D5 17.32 ft, whole-feet `0″`, sub-inch `0-`, negative sign, ≈ flag, metric decimals.
- `EntryEngineTests`: natural entry D1; D10–D17 arithmetic; D22 running total; parentheses; E-K02, E-K04–E-K09, E-K13, E-K25; backspace through a fraction; undo after `=` and `AC`; memory M+/M−/MR/MC and E-K15; snapshot encode/decode round trip (E-K16).
- `StairsTests`: S1–S5, S9; warnings on S3; E-K17, E-K18.
- `RoofTests`: R1, R2, R4, R6, R7, R9, R10, R15, R19; E-K19.
- `ConcreteTests`: C1, C2, C4, C6, C8; E-K21.
- `BoardFeetTests`: B1–B4, B9–B11.
- `SquareUpTests`: A3, A8, A9.
- `CircleTests`: X1–X4.
- `MiterTests`: X8. `PolygonTests`: X7, E-K20. `StudsTests`: X17.
- `TapeAndHistoryTests`: append, cap at 200 (E-K14), delete, clear, atomic write and reload.
- `PreferencesTests`: defaults match ontology; decode with missing keys.
- `FunctionRegistryTests`: nine functions, unique ids, every field has help, every function solves its oracle through the generic `solve(inputs:)` path.

## App logic (`Tests/CaloAppTests`)
- `CalcNoLiteralStringsLint`: no literal in `Text(`/`Label(` under `App/Features/Calculator`.
- `LookTests`: every `Look` resolves a backdrop, key shape and key size; default is glass.

## UI (XCUITest, `-calc.uitest` → empty tape, default prefs, Open as calculator)
- `addsTwoDimensions`: 5 ′ 3 ″ 1 ⁄ 2 + 2 ′ 9 ″ 3 ⁄ 4 = → result `8′ 1-1/4″`; expression line shows `5′ 3-1⁄2″ + 2′ 9-3⁄4″`.
- `precisionChipCycles`: 1 ⁄ 3 ″ = → `0-5/16″` with ≈; tap chip → 1/32 `0-11/32″`; tap to exact → `1/3″`.
- `unitChipCycles`: 14 ′ = → tap unit chip → `168″` → `4.267 m`.
- `tapeReuse`: two `=` then open tape → two rows; tap the first → it is the operand; swipe delete → one row.
- `undoAfterEquals`: expression restored.
- `stairsSheet`: Functions → Stairs → rise 9 ′ 11 ″ → risers 16, riser `7-7/16″`, stringer `15′ 6-15/16″`; Use → on keypad.
- `concreteBags`: slab 12 × 16 × 4″ → 107 bags.
- `lookSwitch`: Settings → Look → Daylight → keypad identifiers still present, backdrop changes (screenshot attached).
- `memoryPersists`: M+ 5 ′, relaunch, MR → `5′ 0″`.
- `accessibilityAudit` without the contrast rule on glass screens; `holdToSeeHelp`: long-press `′` shows the help popover.
