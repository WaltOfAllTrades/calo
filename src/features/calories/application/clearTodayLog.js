import { CalLogRepository } from "../infrastructure/CalLogRepository.js";

const repo = new CalLogRepository();

export async function clearTodayLog() {
  return repo.clearToday();
}

export async function hasTodayEntries() {
  const rows = await repo.getToday();
  return rows.length > 0;
}
