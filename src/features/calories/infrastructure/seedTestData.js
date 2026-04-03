/**
 * Test data seeder for calLog table.
 *
 * Toggle SEED_ENABLED to insert 30 days of realistic test data on app load.
 * Wired in: src/main/main.js — called at the end of the module.
 */

import { db } from "./db/dexieDb.js";

const SEED_ENABLED = true;

// ── Recurring items (10 total) ──────────────────────────────────────────
// Frequency bias: "beginning" = days 0-12, "middle" = days 9-21, "end" = days 17-29

const ITEMS = [
  // Beginning-biased
  { name: "Greek Yogurt",       cal: 150, desc: "" },
  // Middle-biased
  { name: "Turkey Sandwich",    cal: 450, desc: "turkey, lettuce, tomato, swiss cheese, whole wheat bread" },
  // End-biased
  { name: "Protein Shake",      cal: 200, desc: "whey protein, almond milk, peanut butter" },
  // Uniform
  { name: "Banana",             cal: 105, desc: "" },
  { name: "Black Coffee",       cal: 5,   desc: "" },
  { name: "Grilled Chicken",    cal: 280, desc: "seasoned chicken breast, olive oil" },
  { name: "Rice Bowl",          cal: 520, desc: "white rice, teriyaki chicken, steamed broccoli, soy sauce" },
  { name: "Scrambled Eggs",     cal: 220, desc: "eggs, butter, cheddar cheese" },
  { name: "Apple",              cal: 95,  desc: "" },
  { name: "Pasta with Meat Sauce", cal: 550, desc: "spaghetti, ground beef, marinara sauce, parmesan" }
];

// Extra items for variety — not part of the "10 recurring" set
const EXTRAS = [
  { name: "Oatmeal",        cal: 300, desc: "rolled oats, honey, blueberries" },
  { name: "Caesar Salad",   cal: 350, desc: "romaine, croutons, parmesan, caesar dressing" },
  { name: "Trail Mix",      cal: 175, desc: "" },
  { name: "Orange Juice",   cal: 110, desc: "" },
  { name: "Cheese Quesadilla", cal: 380, desc: "flour tortilla, cheddar, mozzarella, salsa" },
  { name: "",               cal: 120, desc: "" },
  { name: "",               cal: 250, desc: "" },
  { name: "Granola Bar",    cal: 190, desc: "" },
  { name: "Avocado Toast",  cal: 310, desc: "sourdough, avocado, salt, red pepper flakes, lemon juice" },
  { name: "Iced Latte",     cal: 180, desc: "espresso, oat milk, vanilla syrup" }
];

// Day index 0 = 29 days ago, 29 = today
// No entries on these days (missed logging)
const SKIP_DAYS = new Set([7, 14, 22]);

// Days that exceed target (~2200-2600 kcal)
const HIGH_DAYS = new Set([4, 11, 25]);

// Very low days (~600-1000 kcal)
const LOW_DAYS = new Set([2, 18, 27]);

// Deterministic pseudo-random from seed
function seededRand(seed) {
  let s = seed;
  return function () {
    s = (s * 16807 + 0) % 2147483647;
    return (s - 1) / 2147483646;
  };
}

function pickWeighted(rand, items, weights) {
  const total = weights.reduce((a, b) => a + b, 0);
  let r = rand() * total;
  for (let i = 0; i < items.length; i++) {
    r -= weights[i];
    if (r <= 0) return items[i];
  }
  return items[items.length - 1];
}

function itemWeight(dayIndex, itemIndex) {
  // Greek Yogurt — beginning bias
  if (itemIndex === 0) return dayIndex < 13 ? 5 : 1;
  // Turkey Sandwich — middle bias
  if (itemIndex === 1) return (dayIndex >= 9 && dayIndex <= 21) ? 5 : 1;
  // Protein Shake — end bias
  if (itemIndex === 2) return dayIndex > 17 ? 5 : 1;
  return 2;
}

function buildDayEntries(dayIndex, rand) {
  if (SKIP_DAYS.has(dayIndex)) return [];

  let targetTotal;
  if (HIGH_DAYS.has(dayIndex)) {
    targetTotal = 2200 + Math.floor(rand() * 400);
  } else if (LOW_DAYS.has(dayIndex)) {
    targetTotal = 600 + Math.floor(rand() * 400);
  } else {
    targetTotal = 1500 + Math.floor(rand() * 450);
  }

  const entries = [];
  let running = 0;
  const entryCount = LOW_DAYS.has(dayIndex) ? 3 + Math.floor(rand() * 3) : 5 + Math.floor(rand() * 5);
  const allPool = [...ITEMS, ...EXTRAS];
  const weights = allPool.map((_, i) => i < ITEMS.length ? itemWeight(dayIndex, i) : 1);

  for (let e = 0; e < entryCount; e++) {
    const isLast = e === entryCount - 1;
    let item;

    if (isLast && running < targetTotal) {
      // Last entry fills the gap with a plausible value
      const gap = targetTotal - running;
      const candidates = allPool.filter(it => Math.abs(it.cal - gap) < 200);
      if (candidates.length > 0) {
        item = candidates[Math.floor(rand() * candidates.length)];
        item = { ...item, cal: gap };
      } else {
        item = { name: "", cal: gap, desc: "" };
      }
    } else {
      item = pickWeighted(rand, allPool, weights);
      // Slight cal variation (+/- 15%)
      const variance = 0.85 + rand() * 0.30;
      item = { ...item, cal: Math.round(item.cal * variance) };
    }

    // Variation in what fields are set (name only, desc only, both, neither)
    const roll = rand();
    let name = item.name;
    let desc = item.desc;
    if (roll < 0.08) { name = ""; desc = ""; }
    else if (roll < 0.15 && desc) { name = ""; }
    else if (roll < 0.25) { desc = ""; }

    running += item.cal;
    entries.push({ cal: item.cal, name, desc });
  }

  return entries;
}

export async function seedTestData() {
  if (!SEED_ENABLED) return;

  const count = await db.table("calLog").count();
  if (count > 0) return;

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const rand = seededRand(42);
  const rows = [];

  for (let dayIndex = 0; dayIndex < 30; dayIndex++) {
    const entries = buildDayEntries(dayIndex, rand);
    const dayDate = new Date(today);
    dayDate.setDate(dayDate.getDate() - (29 - dayIndex));

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      // Spread entries between 7:00 and 21:00
      const startMin = 7 * 60;
      const endMin = 21 * 60;
      const span = endMin - startMin;
      const offsetMin = entries.length > 1
        ? Math.floor(startMin + (i / (entries.length - 1)) * span)
        : startMin + Math.floor(span / 2);
      const jitter = Math.floor(rand() * 15);

      const ts = new Date(dayDate);
      ts.setHours(0, 0, 0, 0);
      ts.setMinutes(offsetMin + jitter);

      rows.push({
        calories: entry.cal,
        name: entry.name,
        description: entry.desc,
        createdOn: ts.toISOString(),
        updatedOn: ts.toISOString()
      });
    }
  }

  await db.table("calLog").bulkAdd(rows);
}
