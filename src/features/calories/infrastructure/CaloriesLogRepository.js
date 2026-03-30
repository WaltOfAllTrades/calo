import { db } from "./db/dexieDb";
import { CalLogEvent } from "../domain/CalLogEvent";

export class CaloriesLogRepository {
  async add(event) {
    await db.table("CaloriesLog").add({
      calValue: event.calValue,
      direction: event.direction,
      createdOn: event.createdOn.toISOString(),
      name: event.name,
      notes: event.notes
    });
  }

  async getAll() {
    const rows = await db.table("CaloriesLog").toArray();

    return rows.map(
      row =>
        new CalLogEvent(
          row.calValue,
          row.direction,
          new Date(row.createdOn),
          row.name,
          row.notes
        )
    );


  }

  // Get only today's events
  async getToday() {
    const start = new Date();
    start.setHours(0, 0, 0, 0);

    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const rows = await db
      .table("CaloriesLog")
      .where("createdOn")
      .between(start.toISOString(), end.toISOString())
      .toArray();

    return rows.map(
      row =>
        new CalLogEvent(
          row.calValue,
          row.direction,
          new Date(row.createdOn),
          row.name,
          row.notes
        )
    );
  }
}
