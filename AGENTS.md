# Coding Agent Instructions — Calo

## Project Overview

Calo is a mobile-first calorie-tracking web app built with vanilla JavaScript (ES modules), Vite, and Dexie (IndexedDB). There is no framework — UI is built by creating DOM elements directly in JS. CSS is plain CSS (no preprocessor).

---

## Feature-Based File Organisation

### Structure

```
src/
  features/
    <featureName>/
      domain/          — Pure data models and business logic (no I/O)
      application/     — Use-case functions that orchestrate domain + infra
      infrastructure/  — Persistence, network, browser APIs
        db/            — Database-specific files (Dexie schemas, migrations)
      ui/              — DOM creation, event wiring, CSS imports
      components/      — Reusable UI pieces scoped to this feature
  main/                — App entry point, top-level wiring only
  styles/              — Global/shared CSS (resets, body, CSS variables)
```

### Rules

- **One feature per folder.** Never put code for feature A inside feature B's directory.
- **Domain has zero dependencies** on infrastructure or UI. Domain files export pure classes/functions only.
- **Application depends on domain + infrastructure.** Each file exports a single use-case function (e.g. `logCalorieEvent`, `getTodaysTotalCalories`).
- **Infrastructure depends on domain** (to hydrate domain objects) but never on application or UI.
- **UI depends on application** (to call use cases) and on its own components, but never directly on infrastructure or domain internals.
- **Barrel files** (`index.js`) are used in `domain/` and `infrastructure/` to re-export public API. Import from the barrel, not from internal file paths.
- **`.keep` files** mark empty directories that are part of the planned structure. Remove them once real files are added.
- **main.js** is only for top-level composition — importing features, mounting to `#app`. No business logic belongs here.

### Adding a New Feature

1. Create `src/features/<name>/` with subfolders: `domain/`, `application/`, `infrastructure/`, `ui/`, `components/`.
2. Add barrel `index.js` files in `domain/` and `infrastructure/`.
3. Wire the feature into `main.js` only when it's ready to mount.

---

## Mobile-First UI Best Practices

### Design Philosophy

This app targets phones first. Every layout and sizing decision must work on a 320px-wide screen before considering larger viewports.

### Sizing — Use Relative Units

| Use | Avoid |
|-----|-------|
| `%`, `vw`, `vh`, `dvh`, `svh` | Fixed `px` for layout dimensions |
| `rem`, `em` | Fixed `px` for font sizes |
| `cqw`, `cqi` (container query units) | `vw` for component-internal sizing |
| `clamp(min, preferred, max)` | Single fixed values |
| `min()`, `max()` for constraints | Breakpoint-only sizing |

- **Font sizes:** Use `clamp()` with container-query units (`cqw`) when font must scale with its parent element, or `vw` when scaling with the viewport. Always set a `rem` floor and ceiling.
  ```css
  font-size: clamp(1rem, 35cqw, 2.6rem);
  ```
- **Container widths:** Prefer `min(percentage, absolute-max)` to let content fill small screens and cap on large ones.
  ```css
  width: min(92vw, 360px);
  ```
- **Spacing/gaps:** Use `rem` or small `vw` values. Avoid fixed `px` gaps in grid/flex layouts.
- **Aspect ratios:** Use `aspect-ratio` to maintain shape without height hacks.

### Layout

- Use **CSS Grid** or **Flexbox** for all layout. Never use floats or absolute positioning for layout (reserve `position: absolute` for layering effects like pseudo-elements).
- Center content with `display: grid; place-items: center;` — not margin hacks.
- Use `env(safe-area-inset-*)` on `body` padding to respect notches and home indicators.
- Set `viewport-fit=cover` in the viewport meta tag (already configured in `index.html`).

### Touch & Interaction

- Set `touch-action: manipulation;` on interactive elements to remove 300ms tap delay.
- Minimum tap target: 44×44 CSS pixels (use `min-width`/`min-height` if needed).
- Use `:active` for press feedback, not `:hover`. Mobile has no hover state.
- Keep transitions short (60–120ms) for tactile feel.
- Never rely on hover-only interactions (tooltips, dropdown menus on hover).

### Responsive Strategy

- **No media-query breakpoints** unless absolutely necessary. Prefer intrinsic sizing (`min()`, `clamp()`, `auto-fit`, `auto-fill`).
- When breakpoints are needed, use `min-width` (mobile-first direction).
- Test at 320px, 375px, 390px, 428px widths — these cover the majority of phones in use.

### Colors & Theming

- Define all colors as CSS custom properties in `:root`.
- Use `color-mix(in hsl, ...)` to derive related shades from a base color so the palette stays consistent when a single value changes.
- Keep derived colors referencing their base:
  ```css
  --intent-active: #ff8a14;
  --intent: color-mix(in hsl, var(--intent-active), black 62%);
  ```

---

## CSS Conventions

### File Scoping

- **Global styles** go in `src/styles/app.css` (body, root variables, resets).
- **Feature styles** go next to their JS file: `keypad.css` beside `keypad.js`, `keyButton.css` beside `keyButton.js`.
- CSS files are linked in `index.html`, not imported in JS.
- Never put styles for one component inside another component's CSS file.

### Naming

- Use **BEM-like naming**: `.key-button`, `.key-button--variant`, `.key-button__label`, `.key-button.is-active`.
- Modifier classes use `--` prefix: `key-button--number`, `key-button--intent`.
- State classes use `is-` prefix: `is-active`, `is-disabled`.

### Pseudo-Element Layering

When using `::before` / `::after` for decorative layers behind an element:

1. Set `position: relative; isolation: isolate;` on the parent.
2. Make the element background `transparent`.
3. Paint the visible face in `::after` with `z-index: -1`.
4. Paint the decorative layer in `::before` with `z-index: -2`.
5. Text content needs a wrapper element (e.g. `.key-button__label`) with `z-index: 0` to stay on top.
6. Always add `pointer-events: none;` to pseudo-elements.

### Custom Property Overrides

Use CSS custom properties on the base class and override in variant/state selectors — never duplicate full `background:` declarations:

```css
.key-button { --key-face: var(--number); }
.key-button--intent { --key-face: var(--intent); }
.key-button--intent.is-active { --key-face: var(--intent-active); }
```

### Transitions

- Only transition properties that actually change. List them explicitly — never use `transition: all`.
- Keep durations under 150ms for press/tap feedback.

---

## JavaScript Conventions

### Language & Module Style

- **Plain ES modules** (`import`/`export`). No CommonJS, no bundler-specific syntax.
- `"type": "module"` is set in `package.json`.
- Use `.js` extensions in import paths (required by Vite in dev mode for vanilla JS).

### DOM Construction Pattern

UI elements are built with factory functions that return DOM nodes:

```js
export function createComponent({ prop1, prop2 }) {
  const root = document.createElement("div");
  // build, wire events, return root
  return root;
}
```

- Factory functions are named `create<ComponentName>`.
- Accept a single options object for all props/callbacks.
- Return a single root DOM element.
- Wire `addEventListener` inside the factory — the caller just appends the returned node.

### State Management

- Local state lives as a plain object inside the factory closure.
- Re-render by clearing `innerHTML` and rebuilding (acceptable for small component trees).
- No global state store. Features own their own state.

### Naming

- **Files:** camelCase for JS (`keyButton.js`, `logCalorieEvent.js`), camelCase for CSS (`keyButton.css`). PascalCase for domain classes (`CalLogEvent.js`).
- **Functions:** camelCase, verb-first (`createKeypad`, `logCalorieEvent`, `getTodaysTotalCalories`).
- **Classes:** PascalCase (`CalLogEvent`, `CaloriesLogRepository`).
- **CSS classes:** kebab-case with BEM (`key-button--number`).

### Error Handling

- Validate inputs at system boundaries (user input, database reads) — not inside pure domain logic.
- Use early returns for guard clauses, not deeply nested if/else.
- Let unexpected errors propagate — don't swallow them with empty catch blocks.

---

## Tooling

| Tool | Purpose |
|------|---------|
| Vite | Dev server, production build |
| Dexie | IndexedDB wrapper (client-side persistence) |

- Run `npm run dev` for local development.
- Run `npm run build` for production output.
- No test runner is configured yet. When tests are added, place them beside the file they test: `CalLogEvent.test.js` next to `CalLogEvent.js`.

---

## Performance (Mobile)

- Minimise DOM nodes. Fewer elements = faster paint on low-end phones.
- Avoid layout thrashing: batch DOM reads before writes.
- Use `will-change` sparingly (only on properties that actually animate).
- Prefer CSS transitions over JS animation.
- Lazy-load features that aren't visible on first paint.

---

## Accessibility Baseline

- Use semantic HTML elements (`<button>`, not `<div>` with click handler).
- Ensure sufficient color contrast (4.5:1 for normal text, 3:1 for large text).
- All interactive elements must be keyboard-reachable (buttons are by default).
- Provide `aria-label` on buttons whose visible text is a symbol (`+`, `−`, `⌫`).

---

## Event Handling

### Event Delegation

When a container holds many similar interactive children (e.g. a keypad full of buttons), prefer a single listener on the parent over one listener per child:

```js
root.addEventListener("click", (e) => {
  const btn = e.target.closest(".key-button");
  if (!btn) return;
  // handle btn
});
```

- Reduces memory footprint when the child count is large.
- Survives re-renders — no need to rebind after `innerHTML = ""`.
- Still attach directly when there is only one element or the handler is unique per element.

### Passive Listeners

For `touchstart`, `touchmove`, `wheel`, and `scroll` listeners that do **not** call `preventDefault()`, pass `{ passive: true }`:

```js
element.addEventListener("touchmove", handler, { passive: true });
```

This unblocks the browser compositor thread and prevents scroll jank on mobile.

### Cleanup

When a component is removed from the DOM, clean up:

- `removeEventListener` for any listeners on `window`, `document`, or long-lived elements.
- `clearInterval` / `clearTimeout`.
- `observer.disconnect()` for `IntersectionObserver`, `ResizeObserver`, `MutationObserver`.

Listeners on elements that are garbage-collected (removed from DOM and unreferenced) are cleaned automatically — no action needed for those.

---

## Security

### XSS Prevention

- **Never** assign user-supplied or dynamic strings to `innerHTML`, `outerHTML`, or `insertAdjacentHTML`.
- Use `textContent` for text, `createElement` + `appendChild` for structure.
- If you must render HTML from data, sanitize with the browser's `Sanitizer` API or a trusted library.

### Content Security

- Avoid `eval()`, `new Function()`, and inline `onclick` attributes.
- Keep Dexie queries parameterised — never concatenate user input into query strings.

---

## User Preference Media Queries

### Reduced Motion

Respect users who prefer reduced motion. Wrap all animations/transitions in a media query or disable them:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
  }
}
```

Place this in `src/styles/app.css`.

### Dark / Light Mode

If a light theme is added later, use `prefers-color-scheme` to switch CSS custom properties:

```css
@media (prefers-color-scheme: light) {
  :root {
    --bg: #f8f9fa;
    --text: #1a1a1a;
  }
}
```

Keep it in `:root`-level custom properties so the entire palette pivots from one place.

---

## CSS — Additional Patterns

### Logical Properties

Prefer CSS logical properties over physical ones so layout adapts to writing direction (LTR/RTL):

| Use | Instead of |
|-----|------------|
| `margin-inline-start` | `margin-left` |
| `padding-block` | `padding-top` / `padding-bottom` |
| `inset-inline` | `left` / `right` |
| `border-inline-end` | `border-right` |
| `inline-size` | `width` |
| `block-size` | `height` |

Not all properties need to change — only those that carry directional meaning.

### Overscroll Behaviour

Prevent pull-to-refresh and scroll-chaining on modal/overlay components:

```css
.scroll-container {
  overscroll-behavior: contain;
}
```

On `body` or `html`, use `overscroll-behavior-y: none;` to suppress pull-to-refresh globally if unwanted.

### CSS Containment

For components that repaint independently (lists, cards, off-screen sections), add containment hints:

```css
.card {
  contain: layout style paint;
}
```

This tells the browser that changes inside `.card` cannot affect anything outside it, allowing cheaper repaints.

### Focus Visibility

Style keyboard focus without showing outlines on tap:

```css
:focus-visible {
  outline: 2px solid var(--intent-active);
  outline-offset: 2px;
}

:focus:not(:focus-visible) {
  outline: none;
}
```

This keeps accessibility intact for keyboard users while removing distracting rings on touch.

---

## Offline & PWA Readiness

Even before adding a service worker, structure the app so it can go offline cleanly:

- **All data is in IndexedDB** (Dexie) — already done. No server dependency for reads.
- When network features are added, queue writes locally and sync when online (`navigator.onLine`, `online`/`offline` events).
- Keep asset paths relative so a future service worker can cache them easily.
- When ready, add a `manifest.json` with `display: "standalone"`, theme color, and icons so the app installs to the home screen.

---

## What NOT to Do

- Do not introduce a framework (React, Vue, etc.) without explicit approval.
- Do not add TypeScript — this project is plain JS.
- Do not add CSS preprocessors (Sass, Less, PostCSS plugins).
- Do not use `px` for layout sizing or font sizes (use relative units).
- Do not put infrastructure concerns (fetch, IndexedDB) in domain or UI code.
- Do not create global mutable state or singletons outside feature boundaries.
- Do not add comments explaining *what* code does — only *why* when the reason isn't obvious.
- Do not add third-party UI libraries without explicit approval.
