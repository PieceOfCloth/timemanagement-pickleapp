class Tasks {
  String task;
  bool? status;

  Tasks({
    required this.task,
    required this.status,
  });

  @override
  String toString() {
    return '{"task": "$task", "status": $status}';
  }
}
