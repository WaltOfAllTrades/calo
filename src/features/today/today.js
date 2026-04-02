const listeners = new Set();

let currentDate = formatDate(new Date());

function formatDate(date) {
  return date.toLocaleDateString(undefined, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone
  });
}

function msUntilMidnight() {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(24, 0, 0, 0);
  return midnight - now;
}

function tick() {
  const next = formatDate(new Date());
  if (next !== currentDate) {
    currentDate = next;
    listeners.forEach(fn => fn(currentDate));
  }
  setTimeout(tick, msUntilMidnight() + 50);
}

setTimeout(tick, msUntilMidnight() + 50);

export function getTodayDate() {
  return currentDate;
}

export function onDateChange(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}
