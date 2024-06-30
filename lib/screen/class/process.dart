class Process {
  final String name;
  final int startTime;
  final int burstTime;
  final int priority;

  Process(this.name, this.startTime, this.burstTime, this.priority);

  @override
  String toString() {
    return 'Process{name: $name, startTime: $startTime, burstTime: $burstTime, priority: $priority}';
  }
}