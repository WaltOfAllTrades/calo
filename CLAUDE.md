# Calo (repository)

Two things live here:
- The **web app** at the root (`src/`, Vite, Dexie), deployed to GitHub Pages from `main`. Conventions: `AGENTS.md`.
- The **iOS install** in `ios/` (Swift 6, SwiftUI, Liquid Glass): the native Calo and a separate construction
  calculator in one app. Everything about it, including how to work and the fixed signing values, is in
  `ios/CLAUDE.md`. Read that first for any iOS work. Its spec is `ios/spec/`; status is `ios/SETUP_STATUS.md`.

Nothing in `ios/` may change the web app or its deploy. The overnight goal that started the iOS work is `GOAL.md`.
