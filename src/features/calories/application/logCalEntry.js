import { CalLogRepository } from "../infrastructure/index.js";

export async function logCalEntry(calories, name, description) {
  const repo = new CalLogRepository();
  return repo.add({ calories, name, description });
}
