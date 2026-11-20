# Calculator — formulas and oracles

Every formula here has a unit test that cites the oracle (`tests.md`). Oracles are from
`../../research/features.md`; "UG" is the Construction Master Pro v3.1 User's Guide (page numbers printed).
Values are exact `Fraction`s unless a root or a trig function is involved; then the `Double` result is
snapped with `Fraction(approximating:denominator: 1024)` before display rounding, so a 1/64 display is exact.

## 1. Dimensional algebra
| Left | Op | Right | Result |
|---|---|---|---|
| length | + − | length | length |
| length | + − | scalar | length; the scalar is read in the base unit (in / mm) and the expression line shows it (E-K04) |
| area / volume | + − | same kind | same kind |
| different kinds | + − | | `dimensionMismatch` |
| length | × | length | area |
| area | × | length | volume |
| any | × ÷ | scalar | same kind |
| length | ÷ | length | scalar |
| area | ÷ | length | length |
| volume | ÷ | area | length |
| volume | ÷ | length | area |
| angle | + − × ÷ | scalar / angle | angle (× ÷ angle by angle → scalar) |
| x | op | p % | `x + p%` = x·(1+p/100); `x − p%` = x·(1−p/100); `x × p%` = x·p/100; `x ÷ p%` = x/(p/100) (UG p. 25: D18–D21) |

Precedence: parentheses, then × ÷, then + −, left to right. `±` negates the current number or the result.
`π` is a scalar constant (snapped at 1/1024 only when it reaches a display; kept as a Double factor inside roots).

## 2. Entry
- `5 ′ 3 ″ 1 ⁄ 2` → 63½ in, shown `5′ 3-1⁄2″`. Order largest to smallest; the inch mark separates whole inches
  from a fraction (as on the Construction Master: `5 f 1 i 1 / 2`); a closing `″` after the fraction is
  accepted. The inch mark is optional after a foot mark when there is no fraction (`5 ′ 3` = 5 ft 3 in when
  followed by an operator or `=`), and a fraction right after a foot mark has no whole inches (`5 ′ 3 ⁄ 4`).
  A fraction without a denominator (`15 ⁄` then an operator) uses the precision denominator (UG p. 3).
  Improper fractions allowed (`9 ⁄ 8 ″`). Digits after an inch mark that never get their bar leave the
  expression incomplete.
- `3 . 5 ′` = 3.5 ft. A decimal and a fraction cannot both appear in one number (E-K02).
- A bare number is a scalar unless the expression already has a length and the operator is + or − (§1).
- `″ ″` (inch mark twice) marks square inches, `′ ′` square feet, three marks cubic (UG p. 18). Also reachable
  from the unit chip after a result.
- Backspace removes the last character of the last token; an empty token is removed; a result (after `=`)
  becomes an editable number on first backspace.

## 3. Functions
Notation: R = total rise, r = riser height, n = risers, t = tread depth, T = treads = n − 1, H = headroom,
F = floor thickness, run = T·t. Lengths in inches.

### 3.1 Stairs (UG pp. 15–16, 71–76; FHB; JLC; Navy)
Inputs: rise R (required unless run given), run (optional), desired riser (default 7½), desired tread (10),
headroom (80), floor thickness (10), riser limited (off), riser limit (7¾).
- n = round(R ÷ desired riser) to nearest whole, minimum 1. If riser limited: the ceiling is the stricter of the desired riser and the riser-limit setting; while R ÷ n > ceiling → n + 1 (S4).
- r = R ÷ n (exact). Riser overage = n · r_shown − R (the rounding residue, signed; S4 gives +1/8). Tread overage = T · t_shown − run (S3 gives −5/16).
- If run given: t = run ÷ T; tread overage = t − desired tread. Else t = desired tread, run = T·t.
- Stringer = √((T·t)² + (T·r)²) (excludes the top riser; uses the rounded-to-precision t when run was given, as the UG does: S3).
- Stairwell opening = (H + F) · t ÷ r, using the riser and tread as displayed (rounded to the precision).
- Incline = atan(r ÷ t) in degrees.
- Run-only mode (S2): r = desired riser, T = run ÷ desired tread rounded, n = T + 1, R = n·r.
- Warnings (shown, never blocking): r > 7¾″ (IRC R311.7.5.1), t < 10″ (R311.7.5.2), H < 80″ (R311.7.2).
Oracles: S1 R = 9′11″ → n 16, r 7-7/16, T 15, t 10, open 10′1″, stringer 15′6-15/16″, incline 36.64°.
S2 run 20′ → r 7½, n 25, T 24, open 10′0″, stringer 25′0″, 36.87°, R 15′7½″. S3 R 10′1″ run 15′5″ → r 7-9/16
(warn), n 16, t 12-5/16, T 15, tread overage −5/16, open 12′2½″, stringer 18′0¾″, 31.56°. S4 = S3 riser-limited →
r 7⅛, n 17, t 11-9/16, T 16, open 12′2-1/16″, stringer 18′1-5/16″, 31.64°. S5 FHB 46″ → 6 risers 7-11/16, run 50″.
S9 Navy 107″ at 7″ → 15 risers, r 7⅛.

### 3.2 Roof (UG pp. 10–13, 57–69; JLC; Swanson; Navy)
Pitch p in inches per 12 (entry also as degrees, % grade, slope ratio; all convert: p = 12·tan θ, grade = 100·p/12).
- Common rafter (point to point, no overhang or ridge deduction): common = run · √(1 + (p/12)²).
  Rise = run · p/12. From rise and run: p = 12·rise/run, diag as above.
- Hip/valley (regular): hip = run · √(2 + (p/12)²). Plumb angle = atan(p/(12·√2)); level = 90 − plumb;
  cheek 45°.
- Jacks at spacing s o.c., descending: increment = s · √(1 + (p/12)²); jack k = common − k·increment while > 0,
  list ends at the first ≤ 0 (shown as 0). Irregular hips are out of scope (SPEC).
- Roof area from plan area A and pitch: roof = A · √(1 + (p/12)²); squares = roof/100; bundles = roof/33.33;
  4×8 sheets = roof/32.
Oracles: R4 7/12 run 7′2″ → 8′3-9/16″, plumb 30.26°. R6 7/12 run 11′6″ → rise 6′8½″. R7 30° run 20′4″ → rise
11′8⅞″, diag 23′5¾″. R9 7/12 run 8′5″ 16 o.c. → common 9′8-15/16″, hip 12′10½″, plumb 22.42°, incr 1′6½″,
JK1 8′2⅜″ … JK6 0′5-13/16″, JK7 0. R10 9/12 run 6′9″ 18 o.c. → incr 1′10½″, JK1 6′6¾″ … JK4 0′11¼″.
R15 10/12 plan 14×11 → roof 200.4631 sq ft, 2.00 squares, 6.01 bundles, 6.26 sheets. R19 6/12 → 26.57°, 13.416 per
12. R1 30.45° → 58.787 %, 7-1/16 pitch. R2 47.25 % → 5-11/16, 25.29°.

### 3.3 Concrete (UG pp. 46–50; QUIKRETE 1101; NRMCA CIP 31)
- Slab: V = L·W·D. Footing: V = W·H·length. Column: V = π·(d/2)²·h.
- Waste: V·(1 + waste %), default 10 % (NRMCA: 4–10 %).
- Bags = ceil(V in cu ft ÷ yield); yields 80 lb 0.60, 60 lb 0.45, 50 lb 0.37, 40 lb 0.30 cu ft.
- Display cu yd (27 cu ft) by default; also cu ft, m³.
Oracles: C1 36′3″ × 11′6″ × 4″ → 416.875 sq ft, 5.146605 cu yd. C4 footing 16″ × 8″ × 232′6″ → 7.654321 cu yd.
C2 column d 3′4½″ h 11′6″ → 102.881 cu ft = 3.810408 cu yd. C6 10×10×4″ → 1.235 cu yd, +10 % 1.358.
C8 12×16×4″ → 64 cu ft ÷ 0.60 → 107 bags of 80 lb.

### 3.4 Board feet (UG p. 38; Wood-Mizer; JLC)
- bdft = thickness(in) · width(in) · length(ft) ÷ 12 (= cu in ÷ 144) × count. Cost = bdft × price per MBM ÷ 1000, or × price per bdft.
Oracles: B1 2×4×14 → 9.333333. B2 2×10×16 → 26.66667. B3 2×12×18 → 36. B4 72 bdft × $250/MBM → $18.00.
B9 84 × 2×8×12 → 1344. B10 5/4×6×14 → 8.75. B11 1×7.75×63 in ÷ 144 → 3.39.

### 3.5 Square-up / diagonal (UG pp. 31, 51, 59)
- Any two of rise, run, diagonal → the third, pitch and angle. Perimeter and area of the rectangle. 3-4-5 check: shows the diagonal for the given legs.
Oracles: A3 20′6″ × 25′6″ → area 522.75 sq ft, diag 32′8⅝″, perimeter 92′. A8 45′6″ × 23′8″ → 51′3-7/16″.
A9 rise 9′ run 12′ → 15′, pitch 9, 36.87°.

### 3.6 Circle & arc (UG pp. 39–40)
- From diameter: circumference π·d, area π·d²/4. From chord c and rise h: radius = (c²/4 + h²)/(2h); arc angle =
  2·asin(c/(2r)); arc length = r·θ; segment area = r²/2·(θ − sin θ); pie area = r²·θ/2. From diameter and arc
  angle: arc length. From diameter and arc length: angle, chord, rise.
Oracles: X1 d 11″ → area 95.03318 sq in, circ 34-9/16″. X2 d 5′ arc 85° → 3′8½″. X3 chord 3′6″ rise 1′3″ →
radius 1′10-3/16″, 142.15°, arc 4′7-1/16″. X4 d 5′ arc 3′3″ → 74.48°, chord 3′0-5/16″, segment 1.051381 sq ft,
pie 4.0625 sq ft, rise 0′6⅛″.

### 3.7 Compound miter (UG p. 45)
- Spring angle S (default 45°), corner angle C: miter = atan(sin S ÷ tan(C/2)) and bevel = asin(cos S · cos(C/2)). Oracle X8: S 38°, C 60° → miter 46.84°, bevel 43.03°.

### 3.8 Polygon (UG p. 49)
- Radius r (circumscribed), n sides (≥ 3): full (interior) angle 180 − 360/n, half of that, side = 2r·sin(180/n), perimeter n·side,
  area = n·r²·sin(360/n)/2. Oracle X7: r 15′, 6 sides → 120°, 60°, side 15′, perimeter 90′, area 584.5671 sq ft.

### 3.9 Studs (UG p. 78)
- studs = ceil(length ÷ spacing) + 1. Oracle X17: 18′7½″ at 16 o.c. → 15.

## 4. Conversions (UG pp. 22–23)
D3 14 ft → 4.666667 yd, 168 in, 4.267 m, 426.72 cm, 4267.2 mm. D4 15′9½″ → 15.79167 ft. D5 17.32 ft →
17′3-13/16″. D7 9.0625 in → 9-1/16″, 0.755208 ft. D8 14 sq ft → 2016 sq in, 1.555556 sq yd, 1.300643 m².
D9 14 cu ft → 24192 cu in, 0.518519 cu yd, 0.396436 m³. Metric linear shows 3 decimals; decimal feet and
inches 6 significant digits; angles 2 decimals; D:M:S as `23°42′39″` (D27).

## 5. Display strings
Compact default: `15′ 9-1/2″`, `0-45/64″`, `14′ 0″`, `195.8333 sq ft`, `5.1466 cu yd`, `4.267 m`, `30.26°`.
Negative: leading U+2212. Whole feet keep `0″`; sub-inch keeps the leading `0-` (UG convention).
