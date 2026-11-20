# Calculator — screens

All on `CalcBackdrop` (per Look). One column, `min(92 % width, 400 pt)`, centred. Fits 375×667 without scrolling.

## Main
```
┌──────────────────────────────────────┐
│ ⟲  ≣  ƒ  M  ⚙                        │  toolbar GlassPill: undo, tape, functions, memory, settings
│                                      │
│  5′ 3-1/2″ + 2′ 9-3/4″               │  expression line (as typed; scrolls horizontally, end visible)
│                        8′ 1-1/4″     │  result (Tokens.font.display, RollingNumber-style roll on change)
│                 [ft-in ▾] [1/16 ≈]   │  unit chip, precision chip (tap to cycle; hold for the full list)
│                                      │
│  AC   ⌫   (   )   ÷                  │  keypad 5×5 GlassKey in one GlassEffectContainer
│  7    8   9   ×   ′                  │  digits plain; operators secondary; ′ ″ ⁄ accent; = prominent
│  4    5   6   −   ″                  │
│  1    2   3   +   ⁄                  │
│  %    0   .   ±   =                  │
└──────────────────────────────────────┘
```
- Hold any key ≥ 0.5 s: a popover with its help and worked example (`help.key.<id>`); release without lifting cancels the press.
- Memory key in the pill opens a small menu: M+, M−, MR, MC, with the stored value shown.
- Error states replace the result text (secondary colour, `Tokens.color.negative` for divide by zero); the expression stays.
- Tap the result → Formats sheet. Tap the tape line → reuse.
- Identifiers: `calc.key.<id>` (`calc.key.7`, `calc.key.feet`, `calc.key.inches`, `calc.key.fraction`, `calc.key.plus`,
  `calc.key.equals`, `calc.key.backspace`, `calc.key.allClear`, `calc.key.percent`, `calc.key.negate`, `calc.key.open`,
  `calc.key.close`, `calc.key.point`, `calc.key.minus`, `calc.key.times`, `calc.key.divide`), `calc.expression`,
  `calc.result`, `calc.chip.unit`, `calc.chip.precision`, `calc.pill.undo|tape|functions|memory|settings`.

## Formats sheet (tap the result)
Medium detent. One row per unit of the result's kind: value, Copy, Use. Also the exact fraction (`389/4 in`).

## Tape sheet
Large detent. List newest first: expression (secondary), result (primary, at the current precision and unit), time.
Tap a row → the result becomes the next operand (or replaces an in-progress number). Swipe → Delete. Toolbar: Clear.
Empty: "Nothing on the tape yet." Identifiers `calc.tape.row.<index>`, `calc.tape.clear`, `calc.tape.empty`.

## Functions sheet
Large detent. A 2-column grid of cards (symbol + title) from the registry: Stairs, Roof, Concrete, Board feet,
Square-up, Circle & arc, Compound miter, Polygon, Studs. Tap → Function detail (pushed inside the sheet).

## Function detail
Fields (each a `GlassField` with its unit; dimension fields accept the same natural entry as the keypad, via a
mini keypad accessory or the system keyboard with `′ ″ ⁄` buttons above it), defaults from preferences,
hold-to-see help per field. Below: results list, each row label + value (+ warning line in `negative` when a
code limit is exceeded) and a Use button. Results update live when every required field is valid.
Identifiers `calc.fn.<function>.field.<id>`, `calc.fn.<function>.result.<id>`, `calc.fn.<function>.use.<id>`.

## Settings sheet
Medium detent, NavigationStack. Unit system (segmented), Default precision (menu), Look (menu: Glass, Tape,
Daylight, Blueprint), Stairs defaults (riser, tread, headroom, floor thickness, Riser limited toggle, limit),
Concrete (waste %, bag size), Spacing (o.c.), About, Experiments ›. Identifiers `calc.settings.<id>`.

## Looks (SPEC choice 6)
| Look | Backdrop | Keys | Display |
|---|---|---|---|
| classic (default, Walt 2026-11-20) | graphite / paper, no grid | rounded keys on a darker base they sink into; graphite digits, grey utility, amber operators, slate unit marks, bright equals | compact |
| glass | graphite / paper, faint grid | circles (system glass) | compact |
| tape | paper (both modes, darker in dark), no grid | rounded squares | a paper-strip card behind expression and result |
| daylight | pure white / pure black, no grid | rounded squares, `Tokens.size.keyMin + 8`, bold labels | high-contrast, larger |
| blueprint | blueprint blue `#0B3D91` (dark) / `#1E56B8` (light), white grid | circles | white text |

## Icon map
`arrow.uturn.backward` (undo), `list.bullet.rectangle` (tape), `function` (functions), `m.square` (memory),
`gearshape` (settings), `stairs`, `house` (roof), `cube` (concrete), `rectangle.split.3x1` (board feet),
`square.split.diagonal` (square-up), `circle` (circle & arc), `angle` (miter), `hexagon` (polygon), `ruler` (studs),
`delete.left` (backspace), `doc.on.doc` (copy), `arrow.down.to.line` (use).
