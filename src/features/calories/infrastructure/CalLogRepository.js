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

  async clearToday() {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).toISOString();

    const todayIds = await db
      .table("calLog")
      .where("createdOn")
      .between(startOfDay, endOfDay)
      .primaryKeys();

    return db.table("calLog").bulkDelete(todayIds);
  }

  async deleteById(id) {
    return db.table("calLog").delete(id);
  }

  async updateById(id, fields) {
    const updatedFields = { ...fields, updatedOn: new Date().toISOString() };
    return db.table("calLog").update(id, updatedFields);
  }
}
