// CalLogEvent domain object
export class CalLogEvent {
  constructor(calValue, direction, createdOn, name, notes) {
    this.calValue = calValue;
    this.direction = direction; // "add" | "subtract"
    this.createdOn = createdOn;
    this.name = name;
    this.notes = notes;
  }

  signedCalories() {
    return this.calValue * (this.direction === "add" ? 1 : -1);
  }
}
