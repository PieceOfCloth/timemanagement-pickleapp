class PriorityLog {
  String type;
  int timeSpent;

  PriorityLog({
    required this.type,
    required this.timeSpent,
  });

  factory PriorityLog.fromJson(Map<String, dynamic> json) {
    return PriorityLog(
      type: json['type'] as String,
      timeSpent: json['timeSpent'] as int,
    );
  }

  @override
  String toString() {
    return 'PriorityLog Priority: {type: $type, timeSpent: $timeSpent,}';
  }
}
