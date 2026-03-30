import { db } from "../features/calories/infrastructure/db/dexieDb";
import { logCalorieEvent } from "../features/calories/application/logCalorieEvent";
import { getTodaysTotalCalories } from "../features/calories/application/getTodaysTotalCalories";

(async () => {
  console.info("🧪 Starting calorie test");

  // ✅ reset table before test
  await db.table("CaloriesLog").clear();
  console.info("🧹 Cleared CaloriesLog table");

  // ✅ log multiple calorie events (today)
  await logCalorieEvent(300, "add", "Breakfast", "Eggs and toast");
  await logCalorieEvent(600, "add", "Lunch", "Sandwich");
  await logCalorieEvent(150, "subtract", "Exercise", "Jogging");
  await logCalorieEvent(400, "add", "Dinner", "Chicken and rice");

  console.info("✅ Logged multiple calorie events");

  // ✅ get today's total calories
  const total = await getTodaysTotalCalories();

  console.info("🔥 Today's total calories:", total);
})();
