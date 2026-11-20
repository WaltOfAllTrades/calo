# spec/ — the specification for the Calo iOS install

This folder is the only specification. Build what it says and nothing else. Two separate products live
here, each with its own folder, and a shared engineering and design layer they both obey.

```
spec/
├── README.md                 this file
├── engineering/
│   ├── architecture.md       packages, boundaries, storage, concurrency, testing, must-dos (both products)
│   └── code-standards.md     rules for all code
├── design/
│   └── liquid-glass.md       glass rules, tokens, motion, haptics (both products)
├── calo/                     product 1: the calorie tracker (port of ../../src)
│   ├── ontology.yaml  SPEC.md  screens.md  copy.md  edge-cases.md  tests.md  features.json
└── calculator/               product 2: the construction calculator
    ├── ontology.yaml  SPEC.md  screens.md  copy.md  formulas.md  pain-points.md  edge-cases.md  tests.md  features.json
```

## Reading order
1. `engineering/architecture.md`, `engineering/code-standards.md`, `design/liquid-glass.md`.
2. For the product being built: `ontology.yaml` → `SPEC.md` → `screens.md` → `copy.md` → `edge-cases.md` → `tests.md` → `features.json`.
3. `../research/` holds the sourced research behind the calculator spec. It is background, not requirements;
   where it and the spec disagree, the spec wins and the disagreement goes in `PROGRESS.md`.

## Rules of the folder
- Every sentence in `engineering/`, `design/`, `calo/` and `calculator/` is a requirement unless it says
  "tuning value", which means: start here, adjust on a device, log the final value.
- Numbers prefixed `E-` are edge cases with a decided handling. `T-` are tests. `P-` are pain points from the
  research that a feature must solve. Feature ids are `C-0xx` (Calo, includes the shared skeleton) and `K-0xx` (calculator).
- Internal terms never appear in the UI. User-facing text comes from each product's `copy.md` and lives in the
  one strings catalog.
- `features.json`: flip `passes` to `true` only with `scripts/pass-feature.sh` after `scripts/verify.sh` exits 0.
  Never edit or delete an entry.
- "Do not build" lists are binding. Code may leave a seam for a listed item; it may not implement, stub or
  scaffold it.
- Working with Walt: he is an OOP beginner by his own description. Explain the reasoning behind structural
  choices. If something he asks for looks wrong, say so and offer the alternative.
- When Apple's documentation and this spec disagree, stop on that item, log it in `PROGRESS.md`, pick the spec.
