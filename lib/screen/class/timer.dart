class TimerList {
  String idActivity;
  String title;
  String startTime;
  String endTime;
  String importantType;
  String urgentType;
  bool status;

  TimerList({
    required this.idActivity,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.importantType,
    required this.urgentType,
    required this.status,
  });

  factory TimerList.fromJson(Map<String, dynamic> json) {
    return TimerList(
      idActivity: json['idActivity'] as String,
      title: json['title'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      importantType: json['importantType'] as String,
      urgentType: json['urgentType'] as String,
      status: json['status'] as bool,
    );
  }

  @override
  String toString() {
    return 'TimerList: {status: $status, idActivity: $idActivity, title: $title, startTime: $startTime, endTime: $endTime, importantType: $importantType, urgentType: $urgentType}';
  }
}
