import { CalLogRepository } from "../../calories/infrastructure/CalLogRepository.js";

const repo = new CalLogRepository();

export async function getTodayLog() {
  const rows = await repo.getToday();

  const hasName = rows.some((r) => r.name && r.name.trim() !== "");
  const hasDescription = rows.some(
    (r) => r.description && r.description.trim() !== ""
  );

  return { rows, hasName, hasDescription };
}
