import { db } from "../../calories/infrastructure/db/dexieDb.js";

export class SettingsRepository {
  async get(key, fallback) {
    const row = await db.table("userSettings").get(key);
    return row ? row.value : fallback;
  }

  async set(key, value) {
    await db.table("userSettings").put({ key, value });
  }

  async getAll(defaults) {
    const result = { ...defaults };
    const rows = await db.table("userSettings").toArray();
    for (const row of rows) {
      if (row.key in result) result[row.key] = row.value;
    }
    return result;
  }
}
