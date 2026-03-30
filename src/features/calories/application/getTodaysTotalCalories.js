import { CaloriesLogRepository } from "../infrastructure";

export async function getTodaysTotalCalories() {
  const repo = new CaloriesLogRepository();
  const events = await repo.getToday();

  return events.reduce(
    (total, event) => total + event.signedCalories(),
    0
  );
}
