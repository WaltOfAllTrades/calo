import Dexie from "dexie";

export const db = new Dexie("calo-db");

db.version(2).stores({
  CaloriesLog: "++id,calValue,createdOn,name,notes,direction"
});

db.version(3).stores({
  CaloriesLog: "++id,calValue,createdOn,name,notes,direction",
  calLog: "++id, createdOn"
});

db.version(4).stores({
  CaloriesLog: "++id,calValue,createdOn,name,notes,direction",
  calLog: "++id, createdOn",
  userSettings: "key"
});
