import { db } from "./db/dexieDb.js";

export class CalLogRepository {
  async add({ calories, name, description }) {
    const now = new Date().toISOString();
    return db.table("calLog").add({
      calories,
      name: name || "",
      description: description || "",
      createdOn: now,
      updatedOn: now
    });
  }

  async getToday() {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).toISOString();

    return db
      .table("calLog")
      .where("createdOn")
      .between(startOfDay, endOfDay)
      .toArray();
  }
}
