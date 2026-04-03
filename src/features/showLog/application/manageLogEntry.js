import { CalLogRepository } from "../../calories/infrastructure/CalLogRepository.js";

const repo = new CalLogRepository();

export async function deleteLogEntry(id) {
  return repo.deleteById(id);
}

export async function updateLogEntry(id, { calories, name, description }) {
  return repo.updateById(id, { calories, name, description });
}
