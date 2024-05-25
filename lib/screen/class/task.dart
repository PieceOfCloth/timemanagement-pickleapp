class Tasks {
  String? id;
  String task;
  bool? status;

  Tasks({
    required this.task,
    required this.status,
    this.id,
  });

  @override
  String toString() {
    return '{"id": $id, "task": $task, "status": $status}';
  }
}
