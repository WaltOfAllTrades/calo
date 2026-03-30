import { CalLogEvent } from "../domain";
import { CaloriesLogRepository } from "../infrastructure";

export async function logCalorieEvent(
  calValue,
  direction,
  name,
  notes
) {
  const event = new CalLogEvent(
    calValue,
    direction,
    new Date(),
    name,
    notes
  );

  const repo = new CaloriesLogRepository();
  await repo.add(event);

  return event;
}