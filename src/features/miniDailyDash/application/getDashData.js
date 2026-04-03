import { CalLogRepository } from "../../calories/infrastructure/CalLogRepository.js";
import { loadSettings } from "../../settings/application/settingsService.js";

const repo = new CalLogRepository();

export async function getTodayDashData() {
  const [rows, settings] = await Promise.all([
    repo.getToday(),
    loadSettings()
  ]);

  const logged = rows.reduce((sum, r) => sum + r.calories, 0);
  const remaining = settings.dailyTarget - logged;

  return { logged, remaining };
}
