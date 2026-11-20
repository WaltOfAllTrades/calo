# PROGRESS — Calo iOS

Running log of decisions, disagreements and device results. Newest entries at the bottom of each day.

## 2026-11-20 (overnight run, started ~05:00)
Goal: `../GOAL.md` (Walt, verbatim). Two separate products in one install, spec-driven, verify.sh gate.

### Decisions
- **Layout.** Everything under `ios/`; branch `ios`; the web app and its Pages deploy untouched. Root `CLAUDE.md`
  points at `ios/CLAUDE.md`. `GOAL.md` kept at the root as the assignment of record.
- **Packages.** `DesignSystem` (shared, MainActor), `CaloKit` (Calo domain + GRDB), `CalcKit` (calculator engine,
  Foundation only). CaloKit and CalcKit never import each other, so splitting into two App IDs later is a
  project.yml change, not a refactor (Walt: "keep the seam clean"). Reasoning for an OOP beginner: a package is
  a wall the compiler enforces; two products behind two walls cannot grow into each other by accident.
- **Storage for Calo: GRDB, not SwiftData.** Explicit migrations, in-memory database for every test and UI test,
  same toolchain as Curata on this machine. SwiftData would save a dependency but costs hermetic tests.
- **Calculator storage: JSON files + UserDefaults**, no database. The tape is 200 lines at most.
- **Deviations from the web app** (spec/calo/SPEC.md): no "Reports" button (it did nothing); zero-only buffers
  are not logged; delete is a swipe, edit a tap; light mode exists; Settings is a sheet. Everything else identical.
- **Backgrounds follow the system appearance.** The web app was dark only; glass needs a content layer in both.
- **Keys are system glass buttons** (`.glass` / `.glassProminent`, circle border shape). The web app's bevel ring
  is not ported; Liquid Glass draws its own edge.
- **Haptics as `SensoryFeedback`** constants, not UIKit generators, so DesignSystem stays SwiftUI-only.
- **Feature ids**: `C-` Calo and skeleton, `K-` calculator. `pass-feature.sh` routes by prefix.
- **`.claude/settings.json` not written by me.** The auto-mode classifier refused the write (it registers the
  edit-protection hook). The gate's step 1 enforces the same rule from the shell side, so nothing is unprotected
  at merge time; only the in-editor early warning is missing. Walt can add the file (template in SETUP_STATUS.md).

### Research
- `research/reviews.md`: 157 quotes clustered into 14 themes. Top: price/subscription (49), fraction-entry
  friction (14), learning curve (10), precision/unit-mode surprises (10), licence restore (10), accuracy and
  update breakage (10), state lost on screen lock, no tape/history, readability, offline. Praise worth copying:
  hold-a-key help, triple keypad (whole / numerator / denominator), full expression on screen, multi-format results.
- `research/features.md`: feature matrix and worked examples (in progress at the time of writing).

### Disagreements / open items for Walt
- None yet.

### Build log (continued)
- Skeleton gate green at 43 tests (06:3x). Calo screens, settings, log, about, Experiments and the whole
  calculator engine + functions written next; gate re-run pending with ~130 tests.
- **`Measure` and `DisplayUnit`** are the code names for the ontology's `#dimension` and `#unit`: Foundation
  exports `Dimension` and `Unit` (NSDimension/NSUnit), and every SwiftUI file imports Foundation, so the
  spec names were ambiguous at every use site. The ontology terms stay; the exception is noted in `Measure.swift`.
- Lint: swiftformat's `wrapMultilineStatementBraces` fights swiftlint's `opening_brace`, so it is disabled in
  `.swiftformat`; `--maxwidth 120` lets swiftformat wrap long lines instead of me doing it by hand. Switch-
  dispatch functions (`press`, `evaluate`, `NumberToken.dimension`, `Format.suffix`) carry a scoped
  `cyclomatic_complexity` disable with the reason in a comment; the complexity is the enum, not the logic.
- Stairs (formulas.md §3.1 refined from the UG oracles): the *rounded* riser and tread feed the stringer, opening
  and incline, and the overage results are `n·riser_rounded − rise` and `T·tread_rounded − run`, which is the
  only reading that reproduces S1–S4 to the 1/16. Riser-limited mode treats the desired riser as the ceiling (S4).
- Compound miter: `miter = atan(sin S ÷ tan(C/2))`, `bevel = asin(cos S · cos(C/2))` reproduces X8 (46.84°, 43.03°).
- E-K25 implemented as: backspace on a committed result turns it into a reusable value token; a second
  backspace removes it. Converting an arbitrary exact fraction back into typed digits was not worth the edge cases.
- Natural entry in function fields (`NaturalEntry`) accepts the keypad's own vocabulary plus `5' 3 1/2"`,
  `7/12`, `30°`, `58.8%`, `1500 mm`, so a value copied from the tape pastes back in.
- Adversarial reviews of CalcKit and of the Calo wiring launched as read-only subagents while the gate runs.

### Adversarial review round 1 (CalcKit + Calo wiring), ~06:00
Two read-only reviews, 15 findings each. Must-fixes applied; the rest logged below as deferred or decided.
- **Spec corrections before first merge** (my own spec text from this session, so corrected rather than
  stopped on): the entry sequence `5 ′ 3 1 ⁄ 2 ″` was ambiguous (no separator between whole inches and the
  numerator; `11⁄16` after `3` cannot be split). Adopted the Construction Master's rule: the inch mark separates
  (`5 ′ 3 ″ 1 ⁄ 2`, shown `5′ 3-1⁄2″`). formulas.md §2, tests.md, copy.md help, the UI test updated.
  Also corrected to match the UG oracles the spec cites: riser/tread overage = rounding residue; stairwell
  opening and stringer use the displayed (rounded) riser and tread; compound miter uses S directly; polygon
  "full angle" is the interior angle; riser-limited ceiling = min(desired riser, riser limit).
- **No traps from the keypad**: `Fraction` arithmetic runs in Int128 and reduces before narrowing; checked
  helpers return nil → `tooLarge`; `Fraction(approximating:)` is failable (NaN, ∞, huge); decimal entry is
  capped at 18 integer digits and 9 decimals; E-K10 magnitude cap enforced after `=`; pitch capped below 90°;
  stairs refuse zero/negative sizes and the riser-limited loop is bounded; circle refuses a zero radius.
- **E-K04 marking** records exactly which operand was coerced during evaluation (not by adjacency), so
  `5′ × 2 + 3″` is left alone and `(5′ + 3) × 2′` marks the 3 even though the result is an area.
- Reused values print in the kind's default unit for the system at the precision in force. `±` and unit
  marks after a reused value no longer delete it.
- Formatting: integers print exactly; decimal and metric units compute ≈ by reading the shown digits back;
  pitch shows ≈ only when rounded and keeps the minus; `−0″` cannot appear; `% grade` suffix unified; D:M:S
  added to the angle unit cycle.
- Concrete reads waste as a number (7.5 % works); unknown bag sizes snap to the nearest known size.
- **Calo wiring**: daily target commits on focus loss and on dismiss and is clamped; keypad keys are
  synchronous and enter clears the buffer before the write (web order) and restores it on failure, which is
  **deviation 6** in spec terms (E-C01/E-C02 kept their meaning: nothing typed during the write is lost);
  the product switch waits for the Experiments sheet to dismiss; the buffer is always an accessibility
  element; the target field has a label; swipe-to-delete needs the button (no full swipe) so the UI test can
  find it; the dash renders after its first load; rollover and error timers are cancelled on disappear;
  the broken-database fallback fails writes from the first key; environments are built once; Today's Log
  reloads on rollover; TwoTapButton uses bordered styles inside sheets (no glass on glass); fields are capsules.
- Deferred (logged, not fixed tonight): overflow fallback approximates at 1/1024 for chains of many
  6-decimal factors; `±` after `)`; `%` after `)`; the error line clears on MR/MC/undo; `Function` is a spec
  struct with closures rather than a protocol (same door-keeping effect); the 375×667 layout is checked on the
  simulator rather than proven by a test; `Motion.intentSwitch` morph between button styles.
