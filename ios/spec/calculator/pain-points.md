# Calculator — pain points to solve

From `../../research/reviews.md` (157 quotes, 14 themes) and `../../research/features.md`. Each `P-` is a
requirement; the feature column names where it is solved. Ranks are the research's complaint counts.

| Id | Rank | Pain point (what users say) | Requirement | Solved in |
|---|---|---|---|---|
| P-01 | 1 (49) | Subscriptions, paywalls, "free" apps that lock the + key or add ads later | Free. No ads, no IAP, no account, no locked keys, ever. The about page says so in the users' words. | SPEC ground rules, K-001 |
| P-02 | 2 (14) | Fraction entry fights the user: per-entry unit ritual, no backspace through a fraction, no parentheses, scrolling keypads | Type a measurement the way it reads off the tape: `5 ′ 3 1 / 2 ″`. Backspace removes one character at a time, through a fraction. Parentheses on the keypad. The whole expression stays visible above the result. One screen, no scrolling. | K-010, K-011, K-020 |
| P-03 | 3 (10) | Hardware-faithful key sequences are cryptic to newcomers; pros want fidelity | Functions are sheets with labelled fields and a results list (BuildCalc model), not key sequences. Every key and field has hold-to-see help with a worked example. Pros still get the fast path: the keypad handles all arithmetic and conversions without a sheet. | K-021, K-030..K-038 |
| P-04 | 4 (10) | 1/16 rounding read as a bug; 64ths or 11ths appear; no mm or decimal-feet readout | Arithmetic is exact (rational). Rounding happens once, at display, to a denominator shown as a chip beside the result; tapping the chip changes it (1/2 … 1/64, exact). When rounding changed the value the chip says so ("≈"). The unit chip cycles ft-in, decimal ft, decimal in, mm, cm, m without leaving the screen. | K-010, K-012, K-020 |
| P-05 | 5, 8 | Memory and the entry vanish on screen lock, app switch, relaunch | The engine state (expression, result, memory, precision, unit system) is saved on every change and restored on launch. | K-013, K-022 |
| P-06 | 8 | No history, no paper tape, no undo | A tape of every `=` with its expression and result, tap to reuse, swipe to delete, survives relaunch. Undo restores the expression before the last `=` or `AC`. | K-013, K-023 |
| P-07 | 9 | Small keys, small text, no dark mode, layouts that do not fit | Keys ≥ 56 pt, Dynamic Type, light and dark, Increase Contrast honoured. A "Daylight" look with maximum contrast and the largest keys. | design tokens, K-040 |
| P-08 | 4, 7 | Unit modes are confusing; metric is an afterthought | One unit chip, always visible, always tappable. Imperial and metric are the same engine (1 in = 25.4 mm exactly); switching the system is one setting and never changes the stored value. Tapping the result shows every format at once. | K-012, K-020 |
| P-09 | 7 | Missing: parentheses, π, more rafter and stair cases | Parentheses and π on the keypad. Stairs with riser limit and headroom; rafters with hip/valley, jacks and irregular pitch. | K-011, K-030, K-031 |
| P-10 | 6 | Wrong answers after updates; 6″ + 6″ = 181 | Every formula has a unit test against a published worked example (`formulas.md`); the gate refuses a drop in test count. Exact arithmetic means no accumulated float error. | tests.md, verify.sh |
| P-11 | 12 | Needs a connection for receipts or ads on remote sites | No network code exists in the app. | SPEC, verify.sh boundaries |
| P-12 | 5 | Purchase not recognised on a new phone | Nothing to restore: there is no purchase. | P-01 |
| P-13 | praise | Hold-a-key help, triple keypad, full expression on screen, multi-format results, results as a list | Adopted: hold-to-see help; the expression line; the formats sheet; function results as lists. The triple keypad is replaced by natural tape entry (P-02), which the research rates as the stronger model for dimensions. | K-020, K-021 |
