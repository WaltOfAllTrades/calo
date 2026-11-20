# Calo — screens

All screens sit on `CaloBackdrop`. Layout follows the web app: a single column, `min(92 % width, 360 pt)` wide,
centred; header on top, dash filling the middle, the bottom group (fields, display, keypad) pinned above the
home indicator. Everything must fit a 375×667 pt screen without scrolling (the dash shrinks first, as on the web).

## Main
```
┌──────────────────────────────────┐
│ Calo        Thursday, Nov 20   ⚙ │  header: brand (bold), date (ViewThatFits: full / medium / short), gear (GlassCircleButton)
│                                  │
│     1,240     │     760          │  dash: RollingNumber ×2, labels LOGGED / REMAINING, 1-pt divider
│     LOGGED    │   REMAINING      │  error line below (hidden when empty; reserves one line)
│                                  │
│ [ Item                        ]  │  details fields (GlassField), only when showName / showDetails
│ [ Log details                 ]  │
│ ADD                        250   │  entry display: intent label (accent, uppercase), buffer (tabular)
│  (+) (−) (C) (⌫)                 │  keypad 4×5, GlassKey, one GlassEffectContainer
│  80   7   8   9                  │
│  60   4   5   6                  │
│  40   1   2   3                  │
│  20  00   0  (⏎)                 │
└──────────────────────────────────┘
```
- Key roles: digits plain; bonus keys secondary (dimmer label); C and ⌫ accent; Enter prominent; the active
  intent key prominent, the other plain. Switching intent morphs the prominence (`Motion.intentSwitch`).
- Key symbols: `plus`, `minus`, `delete.left`, `return`. Labels for digits and bonus keys.
- Dash numbers: grouping separators per locale; remaining negative shows U+2212. Digits are monospaced.
- Date format: full `EEEE, MMMM d`; medium `EEE, MMMM d`; short `EEE, MMM d` (the web's three variants), chosen by `ViewThatFits`.
- Accessibility: keys labelled ("Add", "Subtract", "Clear", "Backspace", "Enter", digits by value, bonus "80"); dash
  read as "Logged 1,240 calories", "Remaining 760 calories"; the error line is an accessibility announcement.
- Identifiers (for UI tests): `calo.key.<label>` (`calo.key.plus`, `calo.key.enter`, `calo.key.7`…), `calo.dash.logged`,
  `calo.dash.remaining`, `calo.dash.error`, `calo.display.intent`, `calo.display.buffer`, `calo.field.name`,
  `calo.field.details`, `calo.header.settings`, `calo.header.date`.

## Settings sheet (gear)
Medium detent; a `NavigationStack` inside so Today's Log and About push and raise the detent to large.
```
  Calo                                  (header: app mark + name)
  Today’s Log                        ›
  About                              ›
  ────────────────────────────────────
  Show item name                   (●)
  Show log details                 (○)
  ────────────────────────────────────
  Daily target                 [ 2000 ]   numeric keyboard, 0…99999, commits on end editing; invalid → unchanged
  ────────────────────────────────────
  Experiments                        ›   (shared section, calculator/SPEC.md)
  [ Clear daily log ]                     only when today has entries; TwoTapButton →
                                          "Tap to confirm removal" → "Daily log cleared" (disabled, gone after 1.2 s)
  Done
```
- Closing the sheet (Done or swipe) re-applies field visibility and refreshes the dash.
- Identifiers: `calo.settings.todayLog`, `calo.settings.about`, `calo.settings.showName`, `calo.settings.showDetails`,
  `calo.settings.target`, `calo.settings.experiments`, `calo.settings.clear`, `calo.settings.done`.

## Today's Log (pushed)
- Title "Today’s Log", subtitle "Everything logged today at a glance."
- A `List` of today's entries, oldest first. Columns: time (`h:mm a`), calories (signed, "+250" / "−120", negative in
  `Tokens.color.negative`), item (only when any row has a name), details (only when any row has details).
- Tap a row → Edit entry sheet. Swipe leading-to-trailing → Delete (destructive, immediate, no confirm; the web had none).
- Empty: "No entries yet today." centred.
- Identifiers: `calo.log.row.<id>`, `calo.log.empty`.

## Edit entry (sheet over the log)
- Title "Edit Entry". Fields: Calories (numeric, signed allowed), Item, Log details (2 lines). Cancel / Save.
- Save with a non-integer calories value does nothing (web behaviour). Save updates `updatedAt`.
- Identifiers: `calo.edit.calories`, `calo.edit.name`, `calo.edit.details`, `calo.edit.save`, `calo.edit.cancel`.

## About (pushed)
- Pull quote "Simplicity is sophistication.", tagline "And 3-second calorie logging rocks.", then the paragraph
  from `copy.md`.

## Icon map
`gearshape` (settings), `plus`, `minus`, `delete.left`, `return`, `chevron.right` (rows), `trash` (swipe delete),
`flask` (Experiments row).
