class AlgorithmSchedule {
  String title;
  String impt;
  String urgnt;
  String date;
  DateTime start;
  DateTime end;

  AlgorithmSchedule(
      {required this.title,
      required this.start,
      required this.end,
      required this.date,
      required this.impt,
      required this.urgnt});

  @override
  String toString() {
    return 'AlgorithmSchedule{title: $title, start: $start, end: $end, $impt, $urgnt, $date}';
  }
}
