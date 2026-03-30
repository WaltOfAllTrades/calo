// CalLogEvent domain object
export class CalLogEvent {
  CalValue: number;
  Direction: number;
  CreatedOn: Date;
  Name: string;

  constructor(CalValue: number, Direction: number, CreatedOn: Date, Name: string) {
    this.CalValue = CalValue;
    this.Direction = Direction;
    this.CreatedOn = CreatedOn;
    this.Name = Name;
  }

  logCalories() {
    const result = this.CalValue * this.Direction;
    // TODO: Write to Dexie DB
    // FIXME: Implement Dexie DB write logic here
    return result;
  }
}
