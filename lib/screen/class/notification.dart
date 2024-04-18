class Notifications {
  int minute;

  Notifications({
    required this.minute,
  });

  @override
  String toString() {
    return '{"minute_before": $minute}';
  }
}
