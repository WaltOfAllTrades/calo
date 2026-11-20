# Code standards

Applies to all code, human or agent, in both products.

1. **Model is separate from views.** `CaloKit` and `CalcKit` know nothing about screens. Screens display the model and call it.
2. **Scope names by meaning, not by screen.** `Entry.Intent`, not `Keypad.Intent`: the display and the log use it too.
3. **Nest types to avoid collisions.** `Entry.Intent`, `Dimension.Unit`, `Stair.Result`. No bare `Action`, `Item`, `Manager`, `Helper`, `Data`.
4. **Fixed sets are enums; extra data is an associated value.** `case function(Function.Kind)`, `case digit(Int)`.
5. **Each rule lives in exactly one place.** "Today" is `DayWindow`; the signed-calorie rule is `Entry.signedCalories`;
   tape rounding is `Precision.round(_:)`. Nothing re-derives them.
6. **One source of truth; compute the rest.** Entries are stored; logged, remaining and the day's table are computed.
   The calculator stores the tape; the display is a projection of the engine state.
7. **Exactness.** Calculator arithmetic uses `Fraction` (integer numerator and denominator) end to end; `Double` appears
   only at the edges (trig, square roots, metric display) and is rounded back through `Precision` before display.
8. **Ontology IDs map to code names.** Segments before the last → nested UpperCamelCase types; last segment →
   lowerCamelCase member. `#entry.intent.subtract` → `Entry.Intent.subtract`.
9. **Internal names never reach the UI.** Views use `L10n`; code uses ontology terms. Never build user text from type names.
10. **No placeholder implementations.** A function either does its job or does not exist. No `TODO` returns, no fake success,
    no button that does nothing (the web app's inert "Reports" button is not ported; see calo/SPEC.md).
11. **Search before adding.** Before writing a type or function, search the codebase for an existing one.
12. **Tests are not edited to pass.** `Tests/`, `UITests/`, `scripts/verify.sh`, `scripts/pass-feature.sh`, the hook and the
    test settings in `project.yml` are read-only to the loop once on `main`. A failing test means the code is wrong or the
    spec needs Walt.
13. **Motion and tokens are referenced, never inlined.** `Motion.digitRoll`, `Tokens.radius.card`; no literal durations,
    colours or radii in views.
14. **Comments explain why, not what.** Especially above a formula (cite the source) and anywhere a rule exists because
    of a pain point (`// P-03`).
15. **Public repo hygiene.** No personal data in fixtures, screenshots or tests. No secrets anywhere; reference them by env
    var name only.
16. **The two products share only `DesignSystem`.** An `import CaloKit` under `Features/Calculator` (or the reverse) fails the gate.
