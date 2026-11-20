# Construction calculator feature matrix and test oracles

Research for the Calo iOS construction calculator spec. Compiled 2026-11-20 from public
pages only (no sign-ins, no store downloads). Every claim carries a source URL. Items I could
not confirm are marked **unverified**. Prices are US App Store / Google Play figures as shown
on the day of research and change often.

Primary oracle: **Construction Master Pro v3.1 User's Guide** (models 4065 / 4080 Trig / 44080
Desktop), Calculated Industries, 2023, part no. UG4065E-J, 110 pp.
URL: https://m.media-amazon.com/images/I/A1EbVYUXbjL.pdf
Page numbers below are the printed page numbers ("User's Guide — N"); PDF page = N + 8.
All displayed values are quoted exactly as printed, including the calculator's own display
strings (`5 feet 4-1/2 inch`, `BDFT 26.66667`, etc.).

---

## 1. Product-by-feature matrix

### 1a. Entry model, display, price, platform

| Product | Platform | Price model | Feet / inch / fraction entry | Precision setting | Display convention |
|---|---|---|---|---|---|
| **Construction Master Pro 4065** (hardware) | Handheld | One-time (retail; MSRP not captured) | Dedicated `Feet`, `Inch`, `/` keys; typed largest to smallest: `5 f 1 i 1 / 2` = 5 ft 1-1/2 in. Denominator optional: `15 /` + operator uses the set resolution (15/16 at default). Improper fractions allowed (`9/8`). Unit key pressed 2x = square, 3x = cubic (`100 f f` = `100 sq feet`). Feet-inch format cannot be used for square/cubic entry. [UG pp. 3, 18-19] | Prefs: 1/16 (default), 1/32, 1/64, 1/2, 1/4, 1/8. Temporary per-value re-resolution via `Conv 1/2/3/4/6/8`. Fractional Mode "Standard" (nearest fraction, reduced) or "Constant" (always shows set denominator). [UG pp. 20-21, 83, 85] | `15 feet 9-1/2 inch`, `0-45/64 inch`, `14.0 cu yd`, `195.8333 sq feet`, angles `30.26°`, D:M:S `DMS 23.42.39`. 12-digit display: 8 normal + 4 fractional digits; max 19,999,999.99; internal 12 digits. Negative shown with leading minus: `T+/– – 0-5/16 inch`. [UG pp. 22, 75, 91] |
| **Construction Master Pro Trig 4080** (hardware) | Handheld | One-time | Same keys as 4065 but **no** Length/Width/Height, Blocks, Footing or Drywall keys; replaced by sin/cos/tan (+ inverses via Conv). Height for columns/cones entered via Rise key. [UG p. ii, 16-17, 33] | Same as 4065 | Same as 4065 |
| **Construction Master Pro Calc** (iOS app, id370406446) | iOS 15+, iPadOS, macOS (M1), visionOS; Android (`com.hydrix.laurene`) | Free download, **subscription**: 1 Month Full Access $4.99, 1 Year $39.99; 14-day trial per listing (a developer reply says 7). 41K ratings, 4.8. https://apps.apple.com/us/app/id370406446 | Emulates the 4065 and 4080 keypads in one app; "Fast Fractions Mode" adds dedicated fraction keys. https://www.calculated.com/products/construction-master-pro-app/ | Preset fractions 1/2" through 1/64" (listing) | "Expanded Displayed Digits" (app-only); Advanced Tape saves/emails inputs, descriptions and results as PDF. https://www.calculated.com/products/construction-master-pro-app/ |
| **Measure Master Pro 4020** (hardware) | Handheld | One-time, MSRP $44.95. https://www.calculated.com/products/measure-master-pro/ | Same Feet/Inch/`/` scheme as CM line; ruler fractions only (1/2 … 1/64), no thirds/fifths/tenths; denominator set with Conv + digit | 1/2, 1/4, 1/8, 1/16, 1/32, 1/64 | 11-digit display (7 + 4 fractional); 10-digit internal accuracy |
| **BuildCalc** (42nd Parallel, iOS id333369423) | iOS 17+, iPadOS, macOS 14 (M1), visionOS; Android | **One-time $24.99** (US), no subscription; 75 ratings, 4.7; v2.16.0. https://apps.apple.com/us/app/id333369423 | Interactive input lists; press-and-hold help; press-and-hold a result to copy. Fraction precision settings **unverified** (not on listing or buildcalc.com). https://www.buildcalc.com/ | **unverified** | Results shown as a list per function; results saved under custom labels; tape export (v2.4.7); "Results Only" mode. Metric and imperial shown simultaneously (Family Handyman). https://www.familyhandyman.com/list/construction-calculator-apps/ |
| **Handyman Calculator** (Android; the long-running one, developer Kalyani) | Android | Free; a paid/premium tier is reported at $2–$7.99 by different roundups (**conflicting, unverified**; Play page returned 404 at `com.inturi.net.android.TimberAndLumberCalc`). https://www.capterra.com/resources/best-apps-for-remodelers/ ; https://theweek.com/articles/456504/best-apps-homeimprovement-projects ; https://www.builderonline.com/?p=76361 | Form-based calculators (feet-and-inches calculator, fraction calculator, sq/cu footage) rather than a keypad. https://meistercalc.com/blog/best-construction-calculator-apps-android (names a different "Handyman Calculator" by Sudo Ezekiel; see notes) | **unverified** | Reported 4.4/5 on Play, ~3M installs (secondhand). |
| **Handyman Calculator** (Android `com.handymancalculator`, Sudo Ezekiel, 2026) | Android | Free, "no pro key, subscription or upsell" per its own description (Play billing permission present). v1.0.8, 2026-11-09. https://chrome-stats.com/d/com.handymancalculator | Feet-inch calculator with running memory; "exact fractional tape math in 1/64 units" | 1/64 internal; display setting **unverified** | History tape with reopenable entries; results rounded up to whole bags/sheets/boards |
| **Jobber 6** (Jobber Instruments, hardware) | Handheld | One-time; ~ $70 at the time of a FHB forum thread (down from >$100). https://finehomebuilding.com/forum/jobber-vs-construction-pro | Patented 0–15 keyboard: feet-inch-sixteenths (FIS) typed as one number per field, e.g. 7'-10 1/4"; user "has to think in 16ths" (1/2 = 8). Divisor of 2 must be keyed as "2 0 0" (whole feet). https://www.aecinfo.com/1/company/21/08/57/product283927_1.html ; FHB forum above | Accurate to 1/16; FIS results shown in 16ths or reduced | Rounds the value held in memory to the displayed value (a divide-then-multiply round trip lost 1/16 per a user). Paperless tape of last 16 entries; 6 permanent memories; triangle data retained at power-off. |
| **Jobber X Pro** (Jobber Instruments app) | Android (per askjan) | **unverified** (no store listing found) | Software version of the Jobber 6; feet, inches, fractions, decimals, metric, angles. https://askjan.org/products/Jobber-X-Pro-Calculator-Android.cfm | — | — |
| **Construction Calc Pro / Construction Calc Pro 2** (Snappy Appz, iOS) | iOS 26+ (CCP 2), iPadOS, macOS 26, visionOS | **One-time $13.99**; 9 ratings, 4.7 (CCP 2). Original (iOS 8+, 2018) also $13.99, 11 ratings 2.5. https://apps.apple.com/app/id6446281301 ; https://apps.apple.com/us/app/id458909118 | Keypad arithmetic in feet, inches and fractional inches; reduces fractions; decimal <-> fraction | **unverified** | Scaled stair drawings; graphical triangle display |
| **Construction Calc Pro 7** (Troy Knight, iOS id1419339827) | iOS 15.6+ | Free with ads; $3.99 removes ads; 28 ratings, 4.3; v7.31 (May 2026). https://apps.apple.com/us/app/construction-calc-pro-7/id1419339827 | Form calculators, feet/inches or metric input; "83 tools" | **unverified** | — |
| **DEWALT Mobile Pro** (Infinity Softworks / Delmar-Cengage) | iOS (later Android reported). US App Store URL id512061305 now returns **404 (apparently withdrawn, unverified)**. | Free core + add-on packs: eight packs $0.99–$4.99 each or Master Pack $19.99 (2013). https://www.jlconline.com/products-tools/dewalt-mobile-pro-construction-calculator-app_o | Three keypads; feet and inches entered as fractions or decimals; whole algebraic expressions as one string; **no metric** | Adjustable precision, inches to 1/64; Family Handyman notes it "rounds to the nearest 64th". https://www.familyhandyman.com/list/construction-calculator-apps/ | Toggle units in the view window; History logs entries and results; Memory stores 10 numbers or equations |
| **Fraction Calculator Plus** (Digitalchemy, iOS id580778301) | iOS 15+, iPadOS, macOS, visionOS | Free with ads; Remove ads $3.99; lifetime premium $24.99; weekly/monthly/yearly subs; 23K ratings, 4.9. https://apps.apple.com/us/app/fraction-calculator-plus-get-it-right-every-time/id580778301 | Triple keypad: whole, numerator, denominator typed as three entries ("three and three quarters"). **No feet/inches** on the listing. | A user review mentions rounding to 1/32 or 1/64 with the rounding error shown (**unverified**) | Large digits; auto-reduces; decimal shown alongside each result |
| **Construction Calculator** (xNeat, iOS id1092417398) | iOS/iPadOS 16.4+, visionOS | Free with ads; add-ons: Stair Calculator $4.99, Rafter $4.99, Fraction Calculator $9.99, Calculator Plus $3.99, Themes $1.99, bundles $14.99/$39.99, plus monthly/yearly subs; 688 ratings, 4.7. https://apps.apple.com/us/app/id1092417398 | Type the measurement as read off the tape (12' 6-3/4"); equation and result shown together; cursor editing | **unverified** | Converts among ft-in-frac, inch fraction, yards, decimal feet (10ths/100ths), decimal inches, km/m/cm/mm |
| **Feet and Inches Calculator** (Evan Winograd, iOS id1072241945) | iOS 16+, iPadOS, macOS 13, visionOS | Free with ads; Lifetime $14.99; $0.99/mo; $9.99/yr; 423 ratings, 4.6. https://apps.apple.com/us/app/feet-and-inches-calculator/id1072241945 | Colour-coded fields: blue = feet, green = inches; Advanced Mode for metric | Reviews: decimal and fraction precision selectable, fractions limited to ruler increments (1/16, 1/32) (**secondhand**) | Decimal equivalent shown next to fraction; results cycle to cm/mm |
| **InchWise: Construction Calc** (ProApps, iOS id6813099045) | iOS 17+ | Free with ads; Remove Ads $4.99; no ratings yet; v1.0.1 (Sep 2026). https://apps.apple.com/us/app/inchwise-construction-calc/id6813099045 | Tape that keeps every entry with operator and running result; editing an earlier line recomputes below | Exact to 1/64 internally; display 1/2 … 1/64 | Light/dark, Dynamic Type; PDF/CSV export free |
| **Clad: Feet Inch Calculator** (Alexander Goncharov, iOS id6829445148) | iOS 26+ | Free calculator/tape/convert/export; Pro $6.99/mo, $29.99/yr (7-day trial), $59.99 lifetime; no ratings yet; v1.3 (Nov 2026). https://apps.apple.com/us/app/clad-feet-inch-calculator/id6829445148 | "Type measurements the way you read them off the tape"; exact answer | Results to 1/64; "rounding happens once and is always shown" | Tape of results that can be summed, starred, exported |
| **Builder's Helper MAX** (My Pie Interactive; successor of Carpenter's Helper, iOS id835030206) | iOS 12+ | Free + one-time IAPs: Pro Pack $12.99, Pro Calculator $4.99, Construction/Estimating/Project packs $4.99 each, Quick-Jobs $0.99 each; 1.8K ratings, 4.7; v1.24 (2022). https://apps.apple.com/us/app/id835030206 | Touch keypad for linear/square/cubic; E/M toggle imperial/metric | English inch fractions to **1/128** | Tape logs calculations; Memory Bank running totals; Quick-List of labelled values |
| **Carpenter's Helper / Carpenter's Helper Lite** (My Pie Interactive, 2010) | iOS | Lite free; paid full version (price **unverified**); last update 2010-08-31. appadvice page unreachable at research time (DNS); search snippet only. | — | — | — |
| **Chippy Tools** (iOS + Android) | iOS, Android | Free download; Baluster Spacing free; rest needs Chippy Tools Pro subscription (7-day trial); Play AU IAPs $3.99–$129.99. https://www.chippy.tools/ ; https://meistercalc.com/blog/best-construction-calculator-apps-android | Metric/imperial switch with one tap; mm, feet, inches and fractions | **unverified** | — |
| **Construction Calculator by Reel Calculators** | — | **Not found.** Two searches (one extended) returned no developer or app of that name on the App Store. Possibly renamed or delisted. | — | — | — |

### 1b. Function matrix

Y = present and sourced; P = partial; – = absent or not documented; ? = unverified.
Columns: Conv = unit conversions incl. metric; A/V = area and volume; Conc = concrete yards/bags;
BdFt = board feet; Stair = rise/run/stringer; Hdrm = headroom/stairwell opening; Roof = pitch +
common/hip/valley/jack + rake; Diag = diagonal/square-up; Circ = circle/arc/segment; Poly = polygon;
CM = compound miter/crown; Est = drywall/paint/tile/block estimators; % = percent key; Mem = memory;
Tape = paperless tape/history; Cost = cost per unit; Trig = sin/cos/tan.

| Product | Conv | A/V | Conc | BdFt | Stair | Hdrm | Roof | Diag | Circ | Poly | CM | Est | % | Mem | Tape | Cost | Trig |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CM Pro 4065 | Y (yd, ft, in, m, cm, mm; sq/cu; lb/kg/ton) | Y (L/W/H keys, square-up, perimeter, wall area) | Y (yards auto on mixed units; footing key; bags –) | Y | Y (riser/tread/stringer/incline/overage, riser-limited) | Y (stairwell opening from headroom + floor thickness) | Y (pitch in 4 formats; common; regular+irregular hip/valley; jacks with increment; plumb/level/cheek; rake wall; roof squares/bundles/sheets) | Y | Y (dia, area, circ, arc, chord, segment, pie, rise, arched walls) | Y (full/half angle, side, perimeter, area) | Y (miter + bevel from spring + corner angle) | Y (drywall 4x8/4x9/4x12; blocks/bricks; studs) | Y (4-function) | Y (M+ with avg/count; M1–M3 permanent) | Y (20 entries) | Y | – |
| CM Pro Trig 4080 | Y | P (no L/W/H keys; no wall/room area) | P (no footing key) | Y | Y | Y | Y | Y | Y | Y | Y | P (studs only; no drywall/blocks) | Y | Y | Y | Y | Y |
| CM Pro Calc app | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y (+ crown angle) | Y | Y | Y (4 memories) | Y (Advanced Tape, PDF/email) | Y | Y (Trig mode) |
| Measure Master Pro | Y | Y | P (volume only) | Y | – | – | – | – | Y (circ, area, arc) | – | – | – | Y | Y | Y (20) | Y | – |
| BuildCalc | Y (metric + imperial simultaneously) | Y (gable area, room mode) | Y (footer sizes) | ? | Y (stringer drawings, throat, sub-risers, balusters) | ? | Y (common w/ birdsmouth, hip, irregular hip, purlin/backing/plan angles, sheathing) | Y | ? | ? | Y (miter saw vs protractor display) | Y (brick, block, tile, drywall, shingles, fence) | ? | Y (saved labelled results) | Y (tape export) | ? | ? |
| Handyman Calc (Kalyani) | Y | Y | Y (concrete, asphalt) | ? | ? | – | ? | – | – | – | – | Y (many; attic vent, T&G, brick/block) | – | – | P (notepad, time tracker) | ? | – |
| Handyman Calc (Sudo Ezekiel) | Y | Y | Y (slab/footing/column + bags) | Y (+cost) | Y | – | P (common rafter + angle only) | Y (3-4-5 check) | P (circle) | – | – | Y (drywall, paint, roofing, tile, mulch) | – | Y (running memory) | Y | Y | – |
| Jobber 6 | Y (FIS, mm, decimal, inches) | P (areas of circles/triangles; sq/cu yards) | P (cubic yards) | Y | ? (not on the AEC page; retailer snippets say "stairways") | – | Y (hip/valley pitch, length, jacks, rake) | Y | Y (circle, segment, arch rise) | – | – | – | ? | Y (6) | Y (16) | ? | Y (D:M:S, right triangles) |
| Construction Calc Pro 2 | Y | Y (compound objects) | Y (estimate) | Y (lumber) | Y (incl. stairwell opening, stringer, drawings) | Y | P (rafters, rise/run, slope via trig) | Y | Y (sector, arc) | – | Y (any spring/wall angle) | Y (drywall, block, paint, tile) | ? | Y (unlimited slots) | Y (estimate sheet) | ? | Y |
| Construction Calc Pro 7 | Y | Y | Y | Y | ? | – | Y (rafter, rise/run/angle) | – | – | – | Y (crown) | Y (drywall, paint, flooring, roofing, drop ceiling, balusters) | – | – | – | Y (linear/sq cost) | – |
| DEWALT Mobile Pro | P (imperial only; a conversion template) | Y | Y (slab template, bags) | ? | P (via trig; stairs in packs) | – | P (hip, valley, cripple, ridge in Carpentry pack) | – | – | – | – | Y (drywall, paint, studs; packs for tile/flooring) | Y | Y (10) | Y | Y (business pack) | Y (+ hyperbolic, logs) |
| Fraction Calculator Plus | – | – | – | – | – | – | – | – | – | – | – | – | – | ? | ? | – | – |
| xNeat Construction Calculator | Y | – | – | – | Y (paid) | – | Y (common + hip/valley, paid) | Y (triangle, paid) | Y (circular, arc; paid) | – | – | – | – | – | – | – | – |
| Feet and Inches Calculator (Winograd) | Y | Y | Y (with Excel output) | Y | Y (stringer, overhang, nosing) | – | Y (common, jack, hip/valley, 3D, PDF) | Y (triangle) | Y | – | P (miter) | Y (tile/brick, grid ceiling, baluster/fence) | – | – | – | – | – |
| InchWise | Y (mixed in one expression) | Y (rooms, walls with openings, slabs, footings, columns) | Y (yards, m3, bags) | – | Y (user supplies code limits) | – | Y (common, hip, valley, pitch in rise/ft and degrees) | Y | Y (circle, arc) | – | – | Y (studs, drywall, tile, paint, decking, roofing) | – | – | Y (tape = history; jobs) | – | – |
| Clad | Y (length, area, volume, weight) | Y | Y (+bags) | – | Y (L and U with landing; ±1 riser compare) | – | Y (common, hip, valley, jack; squares, bundles; pitch gauge) | – | – | – | Y (crown, miter) | Y (studs, drywall, decking, fence, tile, paint; cut lists w/ kerf) | – | – | Y (tape, starred, export) | Y (shopping list totals) | – |
| Builder's Helper MAX | Y | Y | Y (concrete, block) | Y | Y | – | Y (pitch/rise/run/diag auto-solve; roof Quick-Job) | Y | Y (arc/circle, column/cone) | – | Y (crown/miter) | Y (drywall, flooring, painting, fencing, decking, wall framing) | – | Y (Memory Bank) | Y | ? | – |
| Chippy Tools | Y | – | Y (+ gravel, soil, asphalt) | – | Y | – | P (roof pitch, rake walls) | Y (check square, diagonal) | – | – | – | Y (decking, fence picket, wainscoting, equal spacing) | – | – | – | – | P (triangles) |

Sources for the matrix rows are the per-product URLs in table 1a, plus for the CM Pro row the
User's Guide table of contents pp. 1–17 and examples pp. 29–81.

---

## 2. Worked examples (unit-test oracles)

Format: inputs → expected outputs, with display strings as printed. Where I re-derived a value
to confirm the oracle's formula, the derivation is marked "check".

### 2.1 Dimensional entry, conversion and arithmetic (CM Pro UG)

| # | Inputs | Expected | Source |
|---|---|---|---|
| D1 | `5 f 1 i 1 / 2` | `5 feet 1-1/2 inch` | UG p. 18 |
| D2 | `44 / 64 + 1 / 64 =` | `0-45/64 inch`; then Conv 1/16 → `0-11/16 inch`; 1/2 → `0-1/2 inch`; 1/32 → `0-23/32 inch`; 1/4 → `0-3/4 inch`; 1/64 → `0-45/64 inch`; 1/8 → `0-3/4 inch` | UG p. 21 |
| D3 | 14 ft → yd, ft-in, in, m, cm, mm | `4.666667 yd`, `14 feet 0 inch`, `168 inch`, `4.267 m`, `426.72 cm`, `4267.2 mm` | UG p. 22 |
| D4 | 15 ft 9-1/2 in → decimal feet | `15.79167 feet`; back → `15 feet 9-1/2 inch` | UG p. 22 |
| D5 | 17.32 ft → ft-in-frac | `17 feet 3-13/16 inch` (17.32 ft = 207.84 in; 3.84 in → 3-13/16 at 1/16) | UG p. 22 |
| D6 | 8-1/8 in → decimal in → decimal ft | `8.125 inch`, `0.677083 feet` | UG p. 23 |
| D7 | 9.0625 in → fraction | `9-1/16 inch`; → `0.755208 feet` | UG p. 23 |
| D8 | 14 sq ft → sq in, sq yd, sq m, sq cm | `2016. sq inch`, `1.555556 sq yd`, `1.300643 sq m`, `13006.43 sq cm` | UG p. 23 |
| D9 | 14 cu ft → cu in, cu yd, cu m | `24192. cu inch`, `0.518519 cu yd`, `0.396436 cu m` | UG p. 23 |
| D10 | 11 in + 2 ft 1 in | `3 feet 0 inch` | UG p. 24 |
| D11 | 5 ft 7-1/2 in + 18 ft 8 in | `24 feet 3-1/2 inch` | UG p. 24 |
| D12 | 11 ft 7-1/2 in − 3 ft | `8 feet 7-1/2 inch` | UG p. 24 |
| D13 | 81 in − 32 in | `49 inch` | UG p. 24 |
| D14 | 5 ft 3 in × 11 ft 6-1/2 in | `60.59375 sq feet` | UG p. 24 |
| D15 | 2 ft 7 in × 10 | `25 feet 10 inch` | UG p. 24 |
| D16 | 30 ft 4 in ÷ 7 in | `52.` (dimensionless) | UG p. 24 |
| D17 | 20 ft 3 in ÷ 9 | `2 feet 3 inch` | UG p. 24 |
| D18 | 18 % of 500 ft | `90 feet 0 inch` | UG p. 25 |
| D19 | 137 sq ft + 10 % | `150.7 sq feet` | UG p. 25 |
| D20 | 552 ft 6 in − 20 % | `442 feet 0 inch` | UG p. 25 |
| D21 | 350 cu yd ÷ 80 % | `437.5 cu yd` | UG p. 25 |
| D22 | 5 ft 4-1/2 in + 8 in + 3.5 yd | running: `6 feet 0-1/2 inch`, total `16 feet 6-1/2 inch` | UG p. 29 |
| D23 | 10 ft ÷ 2 ft 2 in | `4.615385` (4 whole pieces) | UG p. 29 |
| D24 | 2 ft 5 in × 3 | `7 feet 3 inch` = `7.25 feet` | UG p. 30 |
| D25 | 13 ft 8 in ÷ 2; 14 ft 10 in ÷ 2 | `6 feet 10 inch`; `7 feet 5 inch` | UG p. 30 |
| D26 | Tape: 4 f + 5 f + 6 f + 7 f = | `TTL= 22 feet 0 inch`; entries `01 4 feet 0 inch`, `02+ 5 feet 0 inch` … | UG p. 27 |
| D27 | 23°42'39" → decimal | `23.71°`; 44.29° → `DMS 44.17.24`; 30°89' auto-corrects to 31°29'0" | UG p. 78 |
| D28 | 2,500 lb → kg, ton, met ton | `1133.981 kg`, `1.25 ton`, `1.133981 met ton` | UG p. 34 |
| D29 | 5 cu yd @ 1.5 ton/cu yd | `15000. lb`, `7.5 ton`, `6803.886 kg` | UG p. 34 |

Other-source conversions: JLC fraction/decimal — 7/16 = 0.4375; 0.39 × 16 = 6.24 → 6/16 = 3/8;
0.42 lies between 3/8 (0.375) and 7/16 (0.437). https://www.jlconline.com/training-the-trades/framing-square-basics-rafter-layout_o

### 2.2 Area, volume, square-up

| # | Inputs | Expected | Source |
|---|---|---|---|
| A1 | 7 ft 4 in squared | `53.77778 sq feet` | UG p. 31 |
| A2 | 12 ft 6 in × 15 ft 8 in | `195.8333 sq feet` | UG p. 31 |
| A3 | L 20 ft 6 in, W 25 ft 6 in | `AREA 522.75 sq feet`, `SQUP 32 feet 8-5/8 inch`, `PER 92 feet 0 inch` | UG p. 31 |
| A4 | 3 ft × 1 ft 9-5/8 in × 2 ft 4 in | `12.61458 cu feet` → `0.467207 cu yd` | UG p. 32 |
| A5 | L 15, W 20, H 12 ft | `VOL 3600. cu feet`, `WALL 840. sq feet`, `ROOM 1140. sq feet` (4 walls + ceiling) | UG p. 32 |
| A6 | Cylinder dia 2 ft 4 in, h 4 ft 6 in | `AREA 4.276057 sq feet`, `COL 19.24226 cu feet` | UG p. 33 |
| A7 | Cone dia 3 ft 6 in, h 5 ft | `AREA 9.621128 sq feet`, `CONE 16.03521 cu feet` | UG p. 33 |
| A8 | Square-up 45 ft 6 in × 23 ft 8 in | `DIAG 51 feet 3-7/16 inch` | UG p. 51 |
| A9 | 9 ft rise, 12 ft run | `DIAG 15 feet 0 inch`, `PTCH 9 inch`, `PTCH 36.87°` | UG p. 59 |

### 2.3 Stairs

CM Pro defaults: desired riser 7-1/2 in, desired tread 10 in, floor thickness 10 in, headroom 6 ft 8 in
(UG p. 15, 82). Number of risers = rise ÷ desired riser, rounded to nearest whole; treads = risers − 1.
"Riser Limited" (Conv + Stair) adds one riser so the actual riser never exceeds the stored limit (p. 16).
Nosing is **not** modelled; "adjust per local codes" (p. 15). The yield symbol appears when the
incline exceeds the stored riser/tread ratio by 10 % (p. 15).

| # | Inputs | Expected (CM Pro display) | Source |
|---|---|---|---|
| S1 | Rise 9 ft 11 in only | `R-HT 7-7/16 inch`, `RSRS 16.`, `R+/– 0 inch`, `T-WD 10 inch`, `TRDS 15.`, `T+/– 0 inch`, `OPEN 10 feet 1 inch`, `STRG 15 feet 6-15/16 inch`, `INCL 36.64°`, `RUN 12 feet 6 inch` | UG p. 72 |
| S2 | Run 20 ft only | `R-HT 7-1/2 inch`, `RSRS 25.`, `T-WD 10 inch`, `TRDS 24.`, `OPEN 10 feet 0 inch`, `STRG 25 feet 0 inch`, `INCL 36.87°`, `RISE 15 feet 7-1/2 inch` | UG p. 74 |
| S3 | Rise 10 ft 1 in, run 15 ft 5 in | `R-HT 7-9/16 inch` (with over-limit flag), `RSRS 16.`, `R+/– 0 inch`, `T-WD 12-5/16 inch`, `TRDS 15.`, `T+/– – 0-5/16 inch`, `OPEN 12 feet 2-1/2 inch`, `STRG 18 feet 0-3/4 inch`, `INCL 31.56°` | UG p. 75 |
| S4 | Same as S3, Riser Limited (limit 7-1/2) | `R-HT 7-1/8 inch`, `RSRS 17.`, `R+/– 1/8 inch`, `T-WD 11-9/16 inch`, `TRDS 16.`, `T+/– 0 inch`, `OPEN 12 feet 2-1/16 inch`, `STRG 18 feet 1-5/16 inch`, `INCL 31.64°` | UG p. 76 |

Checks (my derivation, matches S1–S3 to the displayed 1/16):
- Stringer = √((treads × tread)² + (treads × riser)²), i.e. **excludes the top riser**: S1 √(150² + 111.5625²) = 186.94 in = 15' 6-15/16"; S2 √(240² + 180²) = 300 in.
- S3 uses the *rounded* tread (12-5/16) in the stringer: √(184.6875² + 113.4375²) = 216.74 in = 18' 0-3/4".
- Stairwell opening = (headroom + floor thickness) × tread ÷ riser: S1 (80 + 10) × 10 ÷ 7.4375 = 121.0 in = 10' 1".
- Incline = atan(riser ÷ tread): S1 atan(7.4375/10) = 36.64°.

Other sources (three or more independent):

| # | Inputs | Expected | Source |
|---|---|---|---|
| S5 | Total rise 46 in, max riser 7-3/4 | 46 ÷ 7.75 = 5.93 → **6 risers**, riser 46 ÷ 6 = 7.66 in (7-11/16); 5 treads × 10 in = **50 in** total run; alternative 7 risers → 6.57 in riser, 60 in run | Fine Homebuilding, "Laying Out Basic Stair Stringers" https://www.finehomebuilding.com/project-guides/framing/laying-out-basic-stair-stringers |
| S6 | Measured 30-3/4 in subfloor-to-subfloor, −3/4 in bottom finish, +1/2 in top finish → total rise 30-1/2 in | 30-1/2 ÷ 7 ≈ 4 → **4 risers**, riser **7-5/8 in**; unit run 10 in; rise + run = 17-5/8 in; (article's total-run step uses 3 × 10 = 30 in) | JLC, "Stair Stringers: Calculation and Layout" https://www.jlconline.com/training-the-trades/stair-stringers-calculation-and-layout_o |
| S7 | Total rise 50.75 in, ~7 in target | 50.75 ÷ 7 = 6.55 → **7 risers**, riser ≈ **7.25 in**; rounding down to 6 would give > 8 in (non-compliant) | Home Depot, "How to Measure Stair Stringers" https://www.homedepot.com/c/ah/how-to-measure-stair-stringers/9ba683603be9fa5395fab90122fef874 (page blocked at fetch time; figures from search snippet, **verify**) |
| S8 | Deck stair: run budget 120 in, unit run 10-1/2 in, total rise 98-1/8 in | 120 ÷ 10.5 = 11-7/16 → **12 steps**; actual run 12 × 10.5 = **126 in**; stringer √(126² + 98²) = √25,480 = **159.62 in = 13.3 ft** → buy 14-ft 2x12s (6-in fudge). Note: 98.125 ÷ 12 = 8.18 in riser exceeds 7-3/4; the article does not compute the riser. | Fine Homebuilding, "Laying Out the Deck Stair Stringers" https://www.finehomebuilding.com/project-guides/decks/laying-out-the-deck-stair-stringers |
| S9 | Total rise 8 ft 11 in = 107 in, customary riser 7 in | 107 ÷ 7 = 15 (fraction dropped) → **15 risers**, riser ≈ **7-1/8 in**; unit run = 17-1/2 − 7-1/8 = **10-3/8 in** | Builder 3&2 Vol. 2 (US Navy NAVEDTRA), "Stairway Layout" https://constructionmanuals.tpub.com/14044/css/Stairway-Layout-196.htm |

### 2.4 Rafters and roof

CM Pro: pitch enterable as inches (`7 i p`), degrees (`30 p`), percent grade (`75 % p`) or ratio
(`.75 Conv p`); repeated `Pitch` presses cycle formats (p. 10). Common rafter = point-to-point
diagonal, **no overhang or ridge deduction** (p. 11). Jack default spacing 16 in o.c.; "JK n" labels;
ascending/descending preference; irregular jacks either keep o.c. or "mate" (JAC-JAC) (pp. 12–13, 85).

| # | Inputs | Expected (CM Pro display) | Source |
|---|---|---|---|
| R1 | Pitch 30.45° | `%GRD 58.78702`, `SLP 0.58787`, `PTCH 7-1/16 inch` | UG p. 57 |
| R2 | Grade 47.25 % | `SLP 0.4725`, `PTCH 5-11/16 inch`, `PTCH 25.29°` | UG p. 57 |
| R3 | Slope 0.65 | `PTCH 7-13/16 inch`, `33.02°`, `%GRD 65.` | UG p. 57 |
| R4 | 7/12, span 14 ft 4 in (run 7 ft 2 in) | `DIAG 8 feet 3-9/16 inch`, `PLMB 30.26°`, `LEVL 59.74°` | UG p. 58 |
| R5 | Rise 6 ft 11-1/2 in, run 14 ft 6 in | `DIAG 16 feet 1 inch`, `PTCH 5-3/4 inch`, `25.64°` | UG p. 58 |
| R6 | 7/12, run 11 ft 6 in | `RISE 6 feet 8-1/2 inch` | UG p. 59 |
| R7 | 30°, run 20 ft 4 in | `RISE 11 feet 8-7/8 inch`, `DIAG 23 feet 5-3/4 inch` | UG p. 59 |
| R8 | Sheathing: 6/12, diagonal 4 ft | `RUN 3 feet 6-15/16 inch` | UG p. 60 |
| R9 | 7/12, run 8 ft 5 in, 16 o.c. | Common `DIAG 9 feet 8-15/16 inch`; hip `H/V 12 feet 10-1/2 inch`, `PLMB 22.42°`, `LEVL 67.58°`, `CHK1 45.00°`; jacks `INCR 1 feet 6-1/2 inch`, `JK 1 8 feet 2-3/8 inch`, `JK 2 6 feet 7-7/8 inch`, `JK 3 5 feet 1-3/8 inch`, `JK 4 3 feet 6-13/16 inch`, `JK 5 2 feet 0-5/16 inch`, `JK 6 0 feet 5-13/16 inch`, `JK 7 0 feet 0 inch` | UG pp. 60–61 |
| R10 | 9/12, run 6 ft 9 in, 18 o.c. | `INCR 1 feet 10-1/2 inch`, `JK 1 6 feet 6-3/4 inch`, `JK 2 4 feet 8-1/4 inch`, `JK 3 2 feet 9-3/4 inch`, `JK 4 0 feet 11-1/4 inch`, `JK 5 0 feet 0 inch`, `PLMB 36.87°`, `LEVL 53.13°` | UG p. 61 |
| R11 | Irregular: 7/12 main, run 4 ft, irregular pitch 8/12, 16 o.c. both sides | Common `DIAG 4 feet 7-9/16 inch`; `IH/V 5 feet 9-11/16 inch`, `PLMB 23.70°`, `LEVL 66.30°`, `CHK1 41.19°`, `CHK2 48.81°`; irregular jacks `INCR 1 feet 4-13/16 inch`, `IJ 1 2 feet 9-5/8 inch`, `IJ 2 1 feet 4-13/16 inch`, `PLMB 33.69°`, `LEVL 56.31°`; regular jacks `INCR 1 feet 9-3/16 inch`, `JK 1 2 feet 10-3/8 inch`, `JK 2 1 feet 1-1/4 inch`, `CHK1 48.81°` | UG pp. 62–63 |
| R12 | Same as R11, ascending, jacks mate (JAC-JAC) | `IJ 1 1 feet 4-13/16 inch`, `IJ 2 2 feet 9-5/8 inch`, `IJ 3 4 feet 2-1/2 inch`; regular side `JKOC 14 inch`, `INCR 1 feet 6-1/2 inch`, `JK 1 1 feet 6-1/2 inch`, `JK 2 3 feet 1-1/16 inch`, `JK 3 4 feet 7-9/16 inch` | UG pp. 64–65 |
| R13 | Rake wall: rise 4 ft, run 8 ft, 16 o.c., no base | `RW 1 3 feet 4 inch`, `RW 2 2 feet 8 inch`, `RW 3 2 feet 0 inch`, `RW 4 1 feet 4 inch`, `RW 5 0 feet 8 inch`, `BASE 0 feet 0 inch`, `RW 26.57°` | UG p. 66 |
| R14 | Rake wall with 5 ft base | `RW 1 8 feet 4 inch` … `RW 5 5 feet 8 inch`, `BASE 5 feet 0 inch`, `26.57°` | UG p. 67 |
| R15 | Roof covering: 10/12, plan 14 × 11 ft | `ROOF 200.4631 sq feet`, `SQRS 2.00`, `BNDL 6.01`, `B-SZ 33.33 sq feet`, `4X8 6.26`, `PLAN 154. sq feet` | UG p. 68 |
| R16 | Rise 10, run 15, plan 50 × 30 ft | `ROOF 1082.776 sq feet`, `SQRS 18.03`, `BNDL 54.08`, `4X8 56.34`, `PTCH 8 inch`, `PLAN 1500. sq feet` | UG p. 69 |
| R17 | 8/12 → angle, tangent | `PTCH 33.69°`, tan `0.666667`; 30.25° → `PTCH 7 inch` | UG p. 80 |

Checks: R4 86 in × √(1 + (7/12)²) = 99.57 in = 8' 3-9/16" ✓; R9 hip 101 in × √(2 + (7/12)²) = 154.5 in = 12' 10-1/2" ✓ (hip run basis 16.97 per 12 of common run); jack increment = o.c. × common factor = 16 × 1.1577 = 18.52 in = 1' 6-1/2" ✓.

Other sources:

| # | Inputs | Expected | Source |
|---|---|---|---|
| R18 | 6/12, building base 139-3/4 in (inside-to-inside), multiplier 139.75 ÷ 12 = 11.65 | Common rafter 13.42 × 11.65 = **156.343 in = 156-5/16 in**; ridge height 69-7/8 in; hip base 1.414 × 139.75 = 197.61 in, hip length 18 × 11.65 = **209.7 in = 209-11/16 in** (6-16.97-18 triangle); birdsmouth level cut 4-1/2 in | JLC, "Framing Square Basics: Rafter Layout" https://www.jlconline.com/training-the-trades/framing-square-basics-rafter-layout_o |
| R19 | 6/12 | 26.57°, 50 % slope, **13.416 in per 12 in of run**, multiplier **1.118**; run 8 → 8.94 ft, 10 → 11.18, 12 → 13.42, 14 → 15.65, 16 → 17.89, 18 → 20.12, 20 → 22.36 ft (before tail) | Swanson Tool, 6/12 rafter reference https://swansontoolco.com/learn/pitch/6-12 |
| R20 | 6/12, run 14 ft 11-1/4 in, 16 o.c. (CM Pro demo) | Common **16' 8-7/16"**, hip/valley **22' 4-7/8"**, hip plumb 19.5°, first jack **15' 2-1/2"** | ProTradeCraft https://www.protradecraft.com/construction-phase/framing/video/55182006/how-to-calculate-hip-valley-and-jack-rafter-lengths |
| R21 | 8/12, common run 15 ft, hip run 21.21 ft | Hip unit length **18.76 in per 16.97 in** of hip run; hip length 18.76 × 15 = **281.40 in = 23.45 ft** | Builder 3&2 Vol. 2 (NAVEDTRA) https://constructionmanuals.tpub.com/14044/css/Hip-Continued-73.htm |
| R22 | 6/12, run 12 ft | 13' 5" (a reader comment; one comment says 13' 6", which is ~1 in long). Check: 12 × 1.118 = 13.416 ft = 13' 5" | Fine Homebuilding, "Laying Out a Common Rafter" (comments) https://www.finehomebuilding.com/project-guides/framing/laying-out-a-common-rafter-2 |

### 2.5 Concrete

CM Pro: mixed-unit volume (ft × ft × in) displays in **cubic yards automatically** under the default
"Standard" volume preference (p. 46, 84). Footing key default 264 sq in (p. 9); bags are **not** a CM Pro function.

| # | Inputs | Expected | Source |
|---|---|---|---|
| C1 | Driveway 36 ft 3 in × 11 ft 6 in × 4 in; $55/cu yd | `416.875 sq feet`, `5.146605 cu yd`, cost `$283.06` | UG p. 46 |
| C2 | 5 columns dia 3 ft 4-1/2 in, h 11 ft 6 in; 1.75 ton/cu yd | `AREA 8.946176 sq feet`, `COL 102.881 cu feet`, `3.810408 cu yd`, × 5 = `19.05204 cu yd`, `33.34107 ton`, `66682.14 lb`, `30246.51 kg` | UG p. 47 |
| C3 | Patio: A (24'6" − 7') × 27' = 472.5; B 7 × 9 = 63; C 9 × 9 = 81 sq ft; depth 4-1/2 in; $45/cu yd | `M+ 616.5 sq feet`, `8.5625 cu yd`, `$385.31` | UG p. 48 |
| C4 | Footing 16 in × 8 in, length 232 ft 6 in; then × 5 | `F-AR STORED 128. sq inch`, `FTG 7.654321 cu yd`, `38.2716 cu yd` | UG p. 50 |
| C5 | Back-fill: 55 ft × 3 ft × 2 ft + triangle (65 % grade, 2 ft rise → `RUN 3 feet 0-15/16 inch`) | `M+ 499.2308 cu feet` = `18.49003 cu yd` | UG p. 53 |
| C6 | 10 × 10 ft slab, 4 in | 33.3 cu ft = **1.23 cu yd**; +10 % → **1.36 cu yd** (≈ 82 bags of 60 lb) | https://everycalculators.com/concrete-slab-calculator-yards.html (calculator site; check: 100 × 0.3333 ÷ 27 = 1.235) |
| C7 | 10 × 12 ft slab, 6 in | 60 cu ft = **2.3 cu yd** | Hunker https://www.hunker.com/13401513/how-to-calculate-concrete-needed-to-pour-a-slab/ (snippet) |
| C8 | 12 × 16 ft slab, 4 in | 63.9 cu ft ÷ 0.60 = 106.5 → **107 bags of 80 lb** | MudMixer https://mudmixer.com/blogs/news/how-many-bags-of-concrete-do-you-need (snippet; check 192 × 0.3333 = 64.0 cu ft) |
| C9 | Coverage per cubic yard | 27 sq ft at 12 in, 54 sq ft at 6 in, **81 sq ft at 4 in**; bags per yard 45 (80 lb), 60 (60 lb), 72 (50 lb) | Inch Calculator https://www.inchcalculator.com/concrete-calculator/ |

### 2.6 Board feet

CM Pro: entry format "Inch × Inch × Feet" then `Conv 8` (Bd Ft); 1 board foot = 144 cu in; cost key
expects **per thousand board feet (MBM)** (p. 4, 38).

| # | Inputs | Expected | Source |
|---|---|---|---|
| B1 | 2 × 4 × 14 | `BDFT 9.333333` | UG p. 38 |
| B2 | 2 × 10 × 16 | `BDFT 26.66667` | UG p. 38 |
| B3 | 2 × 12 × 18 | `BDFT 36.` | UG p. 38 |
| B4 | Sum 72 bd ft × $250/MBM | `$18.00` | UG p. 38 |
| B5 | 150 cu ft → bd ft | `BDFT 1800.` | UG p. 38 |
| B6 | 1" × 12" × 1' | 1 BDFT | Wood-Mizer https://woodmizer.com/us/learning-center/what-is-a-board-foot |
| B7 | 2 × 4 × 10' | 6.667 BDFT (also .667/ft × 10 = 6.67) | Wood-Mizer |
| B8 | 2 × 10 × 16' | 26.667 BDFT | Wood-Mizer |
| B9 | 84 pcs 2 × 8 × 12' | 1,344 BDFT | Wood-Mizer |
| B10 | 5/4 × 6 × 14' (1.25 thick) | 8.75 BDFT; 1 × 6 × 14' = 7 BDFT | Wood-Mizer |
| B11 | Random-width oak 1 × 7.75 in × 63 in ÷ 144 | 3.39 BDFT | Wood-Mizer |
| B12 | 3 in × 2 in × 12 ft | 6 board feet; shortcuts 2x4 = 0.66/ft, 2x6 = 1/ft, 2x12 = 2/ft | Engineering ToolBox https://www.engineeringtoolbox.com/board-foot-d_1453.html |
| B13 | Formula and 2x10 factor | length ft × thickness in × width in ÷ 12; 2x10 = 1.66667 bd ft per linear ft | JLC Field Guide: Lumber https://www.jlconline.com/how-to/framing/lumber/lumber-field-guide |

### 2.7 Circle, arc, polygon, compound miter, drywall, block, studs, balusters (CM Pro UG)

| # | Inputs | Expected | Source |
|---|---|---|---|
| X1 | Circle dia 11 in | `AREA 95.03318 sq inch`, `CIRC 34-9/16 inch` | p. 39 |
| X2 | Dia 5 ft, arc 85° | `ARC 3 feet 8-1/2 inch` | p. 39 |
| X3 | Chord 3 ft 6 in, rise 1 ft 3 in | `RAD 1 feet 10-3/16 inch`, `ARC 142.15°`, `ARC 4 feet 7-1/16 inch` | pp. 39–40 |
| X4 | Dia 5 ft, arc length 3 ft 3 in | `ARC 74.48°`, `CORD 3 feet 0-5/16 inch`, `SEG 1.051381 sq feet`, `PIE 4.0625 sq feet`, `RISE 0 feet 6-1/8 inch` | p. 40 |
| X5 | Arched wall: chord 8 ft 1 in, rise 2 ft 10-1/2 in, 16 o.c. | `ARC 141.70°`, `ARC 10 feet 7 inch`, `SEG 16.96327 sq inch` (sic — printed unit), `PIE 22.63527 sq inch`, `AW 1 0 feet 2-9/16 inch`, `AW 2 0 feet 11-3/16 inch`, `AW 3 2 feet 9-1/8 inch`; with 2 ft base: `AW 1 2 feet 2-9/16 inch`, `AW 2 2 feet 11-3/16 inch`, `AW 3 4 feet 9-1/8 inch` | pp. 41–43 |
| X6 | Inside arched wall: chord 15 ft, rise 5 ft | `ARC 134.76°`, `ARC 19 feet 1-5/16 inch`, `SEG 54.19722 sq feet`, `PIE 77.63472 sq feet`, `AW 1 4 feet 10-11/16 inch`, `AW 2 4 feet 6-5/8 inch`, `AW 3 3 feet 11-3/8 inch`, `AW 4 3 feet 0-1/16 inch`, `AW 5 1 feet 6-1/4 inch` | p. 44 |
| X7 | Polygon radius 15 ft, 6 sides | `FULL 120.00°`, `HALF 60.00°`, `SIDE 15 feet 0 inch`, `PER 90 feet 0 inch`, `AREA 584.5671 sq feet`; fewer than 4 sides → `None` | p. 49 |
| X8 | Compound miter: spring 38°, corner 60° | `MITR 46.84°`, `BEVL 43.03°`; default spring 45°; corner entry < 25 is treated as polygon side count | p. 45, 8 |
| X9 | Drywall 150 sq ft | `4x8 4.6875` (5), `4x9 4.166667` (5), `4x12 3.125` (4) | p. 52 |
| X10 | Drywall 40 ft length | `4x8 10.`, `4x9 10.`, `4x12 10.` (based on 4-ft width) | p. 52 |
| X11 | Blocks: L 22 ft + 15 ft 8 in = 37 ft 8 in, H 4 ft, 128 sq in block, +5 % | `BLKS 169.5`, `177.975` (178) | p. 35 |
| X12 | Blocks for 300 sq ft +3 % | `BLKS 337.5`, `347.625` (348) | p. 35 |
| X13 | Blocks on 150 ft perimeter +3 % | `BLKS 112.50`, `115.875` (116) | p. 36 |
| X14 | Blocks on 20 ft length (16 in block) | `BLKS 15.` | p. 36 |
| X15 | Face brick 21 sq in, 40 × 8 ft wall +3 % | `BLKS 2194.286`, `2260.114` (2261) | p. 37 |
| X16 | Pavers 32 sq in, 5 × 15 ft | `BLKS 337.5` (338) | p. 37 |
| X17 | Studs 16 o.c., wall 18 ft 7-1/2 in | `STUD 15.` | p. 78 |
| X18 | Balusters: span 156 in, ~4 in gap, 1-1/2 in balusters | 156 ÷ 5.5 = `28.36364` (28); 28 × 1.5 = `42 inch`; 156 − 42 = `114 inch`; 114 ÷ 29 = `3-15/16 inch` | p. 77 |
| X19 | Grade 35 % → D:M:S | `DMS 19.17.24` (so 18°15' passes) | p. 80 |
| X20 | Rise 6 ft, hyp 10 ft → angle | `0.6` → `53.13°` → `DMS 53.07.48` | p. 81 |

---

## 3. Conventions

### 3.1 Fractions and rounding
- Default resolution **1/16 in** across the CM Pro line; selectable 1/2, 1/4, 1/8, 1/16, 1/32, 1/64 (UG pp. 20, 83). "All examples in this User's Guide are based on 1/16"."
- Two fraction modes: **Standard** = nearest fraction, reduced (45/64 at 1/16 shows `0-11/16`); **Constant** = always the set denominator (UG p. 85, 21).
- Rounding is **display-only**: the full value is retained internally (12 digits); re-resolution with Conv + digit is temporary (UG p. 21, 91). Contrast: the Jobber 6 is reported to round the stored value to the displayed 1/16 (FHB forum, https://finehomebuilding.com/forum/jobber-vs-construction-pro).
- Newer apps advertise **exact rational arithmetic** to 1/64 with one visible rounding step (InchWise, Clad; see table 1a). DEWALT Mobile Pro rounds to 1/64 (Family Handyman). Builder's Helper MAX goes to 1/128. Measure Master Pro and CM line support ruler fractions only, not thirds/fifths/tenths (https://www.calculated.com/products/measure-master-pro/).
- Denominator-less entry (`15 /`) is interpreted at the current resolution (UG p. 3). Improper fractions accepted (UG p. 3).
- Jobber convention: all fractions typed as **sixteenths** (1/2 = 8) via the 0–15 keypad (AEC page; FHB forum).

### 3.2 Feet-inch mode and decimals
- CM Pro keeps one dimensional format per value: `Feet` after `Conv` toggles ft-in-frac ↔ decimal feet; `Inch` toggles frac ↔ decimal inches (UG p. 3). Decimal feet convert to ft-in-frac at the set resolution: 17.32 ft → `17 feet 3-13/16 inch` (p. 22).
- Whole-foot results still print `0 inch` (`14 feet 0 inch`, `3 feet 0 inch`); sub-inch results print a leading `0-`: `0-45/64 inch`, `0 feet 6-1/8 inch` (pp. 21–24, 40).
- Mixed-unit products auto-promote: ft × ft-in = sq feet; ft × ft × in = **cu yd** (Standard preference); same-unit cubic stays cu ft (pp. 46, 83–84). Area/volume display can be forced to sq ft / sq yd / sq m or cu yd / cu ft / cu m.
- Feet-inch format cannot label square or cubic entries; square/cubic are "unit key pressed 2×/3×" (p. 18).
- Metric linear results default to 3 decimals (`4.267 m`) with a FLOAT option (p. 85); degrees default to 2 decimals (p. 85).
- Auto-range: overflow in small units re-expresses in the next larger unit (20,000,000 mm → 20,000 m) unless exponent mode is on (p. 91).
- Error codes: `OFLO`, `MATH Error` (÷0), `DIM Error`, `ENT Error`, `TRIG Error`, `None` (stairs without rise/run; polygon < 4 sides) (p. 91, 49).

### 3.3 Negative dimensions
- CM Pro prints a minus sign before the dimension: `T+/– – 0-5/16 inch` (UG p. 75). Riser/tread "overage/underage" are signed remainders: positive = overage, negative = underage (p. 71). Change-sign is `Conv –` (p. 2).
- No app listing documented a different negative convention; **unverified** for BuildCalc, Jobber.

### 3.4 Stair code limits commonly used (IRC)
- **R311.7.5.1 Riser height:** "The maximum riser height shall be 7 3/4 inches (196 mm)." Measured vertically between leading edges of adjacent treads; greatest minus smallest in a flight ≤ 3/8 in. (SC adoption of IRC, https://www.law.cornell.edu/regulations/south-carolina/R-8-1210; Knox County 2018 IRC handout https://www.KnoxCounty.org/codes/pdfs/construction_info/Stairs.pdf)
- **R311.7.5.2 Tread depth:** minimum 10 in, measured horizontally between vertical planes of the foremost projections of adjacent treads; ≤ 3/8 in variation (Knox County handout; Viewrail IRC 2021 summary https://resources.viewrail.com/code-compliance/stair-code/tread-depth-and-risers).
- **R311.7.2 Headroom:** not less than **6 ft 8 in** measured vertically from the sloped plane adjoining the tread nosing or from the landing floor (Knox County handout; FHB cites "80 in").
- **R311.7.5.3 Nosing:** 3/4 to 1-1/4 in projection, radius ≤ 9/16 in, bevel ≤ 1/2 in; not required when tread depth ≥ 11 in (Knox County handout; Viewrail).
- Landing at bottom of a straight run ≥ 36 in (JLC; FHB). Masonry riser limit 8 in (SC regs).
- Rules of thumb (not code): rise + run ≈ 17–18 in (JLC, FHB deck article: "approximately 18 in"); Navy manual: 17-1/2 in; comfortable rise 7–8 in (JLC); comfortable incline 35–37° (Trex https://www.trex.com/academy/how-to-guides/all-guides/how-to-calculate-cut-stair-stringers).
- CM Pro defaults (7-1/2 in riser, 10 in tread, 6'8" headroom, 10 in floor thickness) sit inside these limits; its "Riser Limited" mode enforces the stored maximum by adding one riser (UG p. 16).
- One source (Jaspector "IRC 2024") claims 8.25 in / 9 in; it contradicts every code text found and is treated as **unreliable**.
- InchWise and Clad explicitly ship **no code tables**; the user supplies limits (listings).

### 3.5 Concrete bag yields and waste
- QUIKRETE Concrete Mix No. 1101 data sheet: **80 lb ≈ 0.60 cu ft (17 L); 60 lb ≈ 0.45 cu ft (12.7 L); 40 lb ≈ 0.30 cu ft (8.5 L)** (verified from the PDF text; https://www.hooverfence.com/mas_assets/theme/hooverfence/pdfs/data_sheet-concrete mix 1101.pdf — mirror of https://www.Quikrete.com/PDFs/DATA_SHEET-Concrete%20Mix%201101.pdf). The current Quikrete sheet also lists 50 lb ≈ 0.37 cu ft (search snippet, **unverified**).
- Bags per cubic yard (27 ÷ yield): 45 × 80 lb, 60 × 60 lb, 90 × 40 lb, ~72–73 × 50 lb. Inch Calculator table: 45 / 60 / 72. An older rule of thumb (2/3, 1/2, 1/3 cu ft) appears in forums and over-states yield.
- Quikrete's own calculator: yields "are approximate and do not allow for uneven substrate, waste, etc."; "All calculations are rounded up to the next highest whole bag." https://www.quikrete.com/calculator/
- **Waste factor:** NRMCA CIP 31: "Quantity of concrete ordered should be 4% to 10% more than an estimate calculated from the plan dimensions to account for contingencies." https://www.nrmca.org/wp-content/uploads/2021/01/31pr.pdf (verified from PDF text). Inch Calculator: add 5–10 %. Common app default: 10 %, 15–20 % for irregular or sloped pours (several calculator sites, lower authority).
- CM Pro handles waste as a plain percent add-on (`+ 5 %`) and shows fractional block/brick counts that the user rounds up (UG pp. 35–37); Sudo Ezekiel's Handyman Calculator and Quikrete round up to whole bags automatically.
- Concrete weight default in CM Pro: 1.5 ton/cu yd (UG p. 82).

### 3.6 Other defaults worth copying
- Jack rafter / stud / rake-wall spacing 16 in o.c.; roof bundle 33.33 sq ft; square 100 sq ft; block 8 × 16 in = 128 sq in with 16-in length; face brick 21 sq in; paver 32 sq in; footing 264 sq in; crown spring angle 45°; drywall sheets 4×8, 4×9, 4×12 (UG pp. 6, 9, 14, 82).
- Board foot cost is quoted per **MBM** (thousand board feet) (UG p. 38).
- CM Pro hip/valley and common lengths exclude overhang, ridge thickness and material thickness (UG pp. 11–12); JLC measures hip length "at the center of the member thickness".

---

## 4. Gaps and unverified items
- **Reel Calculators**: no such developer or app found (two searches, one extended).
- **Carpenter's Helper**: only a 2010 "Lite" listing exists in search snippets; appadvice.com did not resolve. Builder's Helper MAX (same developer) documented instead.
- **DEWALT Mobile Pro**: US App Store id512061305 returns 404; appfollow mirror timed out twice; no end-of-life notice found. Treat as withdrawn until checked in the App Store app.
- **Handyman Calculator (Kalyani)**: Play listing not reachable (404 on the package reported by third parties); price tier conflicting across roundups.
- **Jobber 6 manual** (62 pp.) and **Jobber X Pro** store listing not found online.
- **BuildCalc** fraction precision and rounding not documented publicly; test in-app.
- **Home Depot stair example (S7)** and **Hunker/MudMixer concrete examples (C7, C8)** come from search snippets; the pages blocked automated fetch.
- Pressbooks "Carpentry Refresher" (BC textbook) returned 403; its stair and roof chapters would add textbook oracles.
- Measure Master Pro full user guide not found; feature list is from calculated.com.
