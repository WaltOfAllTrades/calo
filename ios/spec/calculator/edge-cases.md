# Calculator — edge cases (decided)

| Id | Case | Handling |
|---|---|---|
| E-K01 | Divide by zero | Result slot shows `error.divideByZero`; expression stays; next key edits it. |
| E-K02 | Decimal and fraction in one number (`3.5 1⁄2`) | The fraction bar is refused (key ignored, `Haptics.error`). |
| E-K03 | Adding a length and an area | `error.dimensionMismatch` with both kinds named. |
| E-K04 | `5′ + 3 =` | 3 is read as 3 in (imperial) / 3 mm (metric); the expression line rewrites it as `3″`; result 5′ 3″. |
| E-K05 | Fraction without denominator then an operator (`15 ⁄ +`) | Denominator = current precision (15/16 at 1/16). `⁄` with precision exact → denominator 64. |
| E-K06 | Unit mark with no number (`′` first) | Ignored. |
| E-K07 | Two operators in a row | The second replaces the first. |
| E-K08 | `=` with an unbalanced `(` | Missing `)` are supplied silently (as calculators do). An unmatched `)` key is ignored. |
| E-K09 | `=` on an empty or operator-ended expression | Trailing operator dropped; empty does nothing. |
| E-K10 | Result exceeds 1,000,000 ft or 10¹² in any unit | `error.tooLarge`; no overflow in `Fraction` (Int arithmetic checked with `multipliedReportingOverflow`; overflow → tooLarge). |
| E-K11 | Precision chip tapped while an error shows | Chip changes; error stays until the expression changes. |
| E-K12 | Unit chip on a scalar result | Chip hidden. |
| E-K13 | Tape reuse while a number is half-typed | The half-typed number is replaced by the tape value. |
| E-K14 | Tape reaches 200 lines | Oldest line dropped on the next `=`. |
| E-K15 | M+ of an area onto a length memory | `error.dimensionMismatch`; memory unchanged. MR into an expression with a mismatching kind evaluates to the same error. |
| E-K16 | App killed mid-entry | Expression, result, memory, precision and unit restored exactly on next launch (P-05). |
| E-K17 | Stairs with neither rise nor run | Results list shows the empty state "Enter a rise or a run". |
| E-K18 | Stairs: riser limited pushes n so high that t < 10″ | Warning on tread, numbers still shown. |
| E-K19 | Roof pitch 0 or run 0 | Pitch 0 gives common = run and hip = run·√2; run 0 gives zeros; no error. Pitch ≥ 90° entry is refused. |
| E-K20 | Polygon with fewer than 3 sides | Field refuses values below 3. |
| E-K21 | Concrete bags when volume is 0 | 0 bags. Fractional bags always round up. |
| E-K22 | Switching unit system | Stored values unchanged; display units switch; expression line keeps the marks it was typed with. |
| E-K23 | Look changed while a sheet is open | Applies immediately, no relaunch. |
| E-K24 | Very large Dynamic Type | Keypad labels cap at `.accessibility1`; the display shrinks to a minimum scale of 0.4; nothing scrolls on 375×667. |
| E-K25 | Backspace on a result after `=` | The result becomes a reusable value token in the expression (exact value, shown at the display precision); a second backspace removes it. |
| E-K26 | Hold a key, then slide off | Help popover appears; releasing off the key does not press it. |
