class ActivityLog {
  String? title;
  String? type;
  int? timeSpent;
  DateTime? startTime;
  DateTime? endTime;
  int? timePlan;

  ActivityLog({
    this.title,
    this.type,
    this.timePlan,
    this.timeSpent,
    this.startTime,
    this.endTime,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      title: json['title'] as String,
      type: json['type'] as String,
      timePlan: json['timePlan'] as int,
      timeSpent: json['timeSpent'] as int,
      startTime: json['startTime'] as DateTime,
      endTime: json['endTime'] as DateTime,
    );
  }

  @override
  String toString() {
    return 'ActivityLog Priority: {title: $title, type: $type, timePlan: $timePlan, timeSpent: $timeSpent,}';
  }
}
