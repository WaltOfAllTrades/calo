import Dexie from "dexie";

export const db = new Dexie("calo-db");

db.version(2).stores({
  CaloriesLog: "++id,calValue,createdOn,name,notes,direction"
});
