class Weekday {
  final String name;
  final String shortName;
  final String shortestName;

  const Weekday({
    required this.name,
    required this.shortName,
    required this.shortestName,
  });
}

const List<Weekday> weekdays = [
  Weekday(name: 'Monday', shortName: 'Mon', shortestName: "M"),
  Weekday(name: 'Tuesday', shortName: 'Tue', shortestName: "T"),
  Weekday(name: 'Wednesday', shortName: 'Wed', shortestName: "W"),
  Weekday(name: 'Thursday', shortName: 'Thu', shortestName: "T"),
  Weekday(name: 'Friday', shortName: 'Fri', shortestName: "F"),
  Weekday(name: 'Saturday', shortName: 'Sat', shortestName: "S"),
  Weekday(name: 'Sunday', shortName: 'Sun', shortestName: "S"),
];
