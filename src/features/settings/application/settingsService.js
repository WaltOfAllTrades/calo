import { SettingsRepository } from "../infrastructure/index.js";
import { SETTINGS_DEFAULTS } from "../domain/index.js";

const repo = new SettingsRepository();

export async function loadSettings() {
  return repo.getAll(SETTINGS_DEFAULTS);
}

export async function saveSetting(key, value) {
  await repo.set(key, value);
}
