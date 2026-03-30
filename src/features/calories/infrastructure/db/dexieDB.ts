// DexieDB setup for CalorieLog
import Dexie, { Table } from 'dexie';

export interface CalorieLog {
  id?: number; // Auto-incremented
  CalCount: number;
  Name: string;
  CreatedOn: Date;
}

export class CalorieDexieDB extends Dexie {
  CalorieLog!: Table<CalorieLog, number>;

  constructor() {
    super('CalorieDexieDB');
    this.version(1).stores({
      CalorieLog: '++id,CalCount,Name,CreatedOn',
    });
  }
}

export const db = new CalorieDexieDB();
