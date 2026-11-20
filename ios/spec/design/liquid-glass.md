# Liquid Glass: rules, tokens, motion, haptics (both products)

Source of every rule: Apple's Liquid Glass pages (Human Interface Guidelines → Materials; "Applying Liquid
Glass to custom views"; "Landmarks: Building an app with Liquid Glass"). Read them before the first use of a
glass API. Where this file and an Apple page disagree, stop and log it.

## Principles
1. **Glass is the control layer.** Keys, pills, circles, switches and toolbars are glass. Backgrounds, the dash
   numbers, the calculator display and list rows are plain content so the glass has something to refract.
2. **Let the system draw it.** `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)` and `.glassEffect()`. No
   custom shadows, highlights, blurs or gradients on controls. The web app's bevelled key ring is not ported.
3. **One `GlassEffectContainer` per keypad**, spacing `Tokens.spacing.glassBlend`, so neighbouring keys blend
   and a key can morph (`glassEffectID`) when the layout changes between visual options.
4. **No glass on glass.** Text on a glass surface uses the vibrant foreground; never a second glass layer.
5. **`.regular` everywhere.** `.clear` is not used: both products place glass over their own quiet backgrounds,
   where `.clear` would wash out.
6. **Tint only the one prominent action per region.** Calo: the active intent key (+ or −) and Enter.
   Calculator: the active unit key and `=`. Everything else is untinted; colour comes from symbols and labels.
7. **Monochrome SF Symbols** everywhere else. The icon map is in each product's `screens.md`.
8. **Concentric corners.** Nested shapes use `.rect(corners: .concentric)`; capsules for pills; circles for keys.
9. **Keep content and glass separated at rest.** Keypads sit inside the safe area with `Tokens.spacing.screen`
   margins; the dash never runs under glass.
10. **System bars stay system.** No `toolbarBackground` overrides; sheets keep the system `presentationBackground`.
11. **Test under Reduce Transparency, Increase Contrast and Reduce Motion.** The UI tests run the accessibility
    audit (without the contrast rule on glass screens, per Walt's Curata decision 2026-11-20, with measured
    contrast recorded in PROGRESS.md).

## Backgrounds (the content layer)
Each product owns one background view in `DesignSystem`:
- `CaloBackdrop`: the web app's night (`#020617`) in dark mode; a cool off-white in light mode; a soft radial wash
  of the accent at the top (12 % opacity, tuning value). Follows the system appearance (the web app was dark only;
  decision logged).
- `CalcBackdrop`: a neutral graphite in dark, warm paper in light, with a faint 1-inch grid at 4 % opacity
  (tuning value) so the glass keys have texture to refract. Visual options may swap it (calculator/screens.md).

## Tokens (`DesignSystem/Tokens.swift`)
```
Tokens.color.accent          = Color(light: #ff8a14, dark: #ff8a14)   // Calo's orange, from the web app
Tokens.color.calcAccent      = Color.yellow                            // the calculator's "tape" yellow; options may override
Tokens.color.negative        = Color.red
Tokens.color.text            = Color.primary
Tokens.color.textFaint       = Color.secondary
Tokens.color.night           = #020617

Tokens.radius.card           = 20
Tokens.radius.field          = 14

Tokens.size.control          = 44      // minimum tap target
Tokens.size.keyMin           = 56      // keypad key diameter floor (P-07: gloves)
Tokens.size.pillHeight       = 44

Tokens.spacing.screen        = 16
Tokens.spacing.keyGap        = 10      // tuning value
Tokens.spacing.glassBlend    = 4       // GlassEffectContainer spacing
Tokens.spacing.stack         = 12
```
Type: system text styles only. Dash numbers and the calculator display use `.system(.largeTitle, design: .rounded)`
with `.monospacedDigit()`. Dynamic Type respected; keypad labels cap at the `.accessibility1` size so the grid
never scrolls.

## Components (`DesignSystem`)
- `GlassKey(label:symbol:role:action:)` — a circular (or rounded-square, per option) glass key; `role` picks plain,
  secondary (dimmer label), accent (tinted), prominent (`.glassProminent`). ≥ `Tokens.size.keyMin`.
- `GlassCircleButton(symbol:action:)` — 44 pt icon button (settings gear, back).
- `GlassPill(items:)` — horizontal capsule of symbol buttons (calculator: undo / tape / memory).
- `RollingNumber(value:)` — `Text` with `.contentTransition(.numericText(countsDown:))` driven by `Motion.digitRoll`;
  the iOS answer to the web app's digit reels. Negative values render a real minus sign (U+2212).
- `GlassField(placeholder:text:)` — text field inside a glass capsule.
- `TwoTapButton(title:confirmTitle:doneTitle:action:)` — the "Clear daily log" pattern: first tap arms, second
  tap acts, label changes, disarms after `Motion.armTimeout`.

## Motion (`DesignSystem/Motion.swift`)
Every animation references one of these. Each has a Reduce Motion branch.

| Name | Value | Reduce Motion |
|---|---|---|
| `digitRoll` | 0.6 s ease-out numericText (tuning value; web was 0.9 s) | plain replace |
| `keyPress` | system button press | system |
| `intentSwitch` | 0.15 s ease-out glass morph | instant |
| `errorFade` | 0.2 s in, holds 3 s, 0.3 s out | same timing, no fade |
| `armTimeout` | 4 s then disarm | same |
| `sheet` | system | system |
| `tapeScroll` | system scroll | system |
| `resultSettle` | 0.2 s ease-out (calculator result emphasis) | instant |

Nothing else animates.

## Haptics (`DesignSystem/Haptics.swift`)
`key` (selection changed on every key), `enter` (impact light), `error` (notification error), `arm` (impact medium),
`cleared` (notification success), `result` (impact light, calculator `=`).
