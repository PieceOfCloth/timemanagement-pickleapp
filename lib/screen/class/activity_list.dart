import 'package:pickleapp/screen/class/location.dart';

class ActivityList {
  String idActivity;
  // String idScheduled;
  String title;
  String startTime;
  String endTime;
  String importantType;
  String urgentType;
  int colorA;
  int colorR;
  int colorG;
  int colorB;
  List<Locations>? locations;

  ActivityList({
    required this.idActivity,
    // required this.idScheduled,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.importantType,
    required this.urgentType,
    required this.colorA,
    required this.colorR,
    required this.colorG,
    required this.colorB,
    this.locations,
  });

  factory ActivityList.fromJson(Map<String, dynamic> json) {
    return ActivityList(
      idActivity: json['idActivity'] as String,
      // idScheduled: json['idScheduled'] as String,
      title: json['title'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      importantType: json['importantType'] as String,
      urgentType: json['urgent_tTe'] as String,
      colorA: json['colorA'] as int,
      colorR: json['colorR'] as int,
      colorG: json['colorG'] as int,
      colorB: json['colorB'] as int,
      locations: json['locations'],
    );
  }

  @override
  String toString() {
    return 'ActivityList: {idActivity: $idActivity, title: $title, startTime: $startTime, endTime: $endTime, importantType: $importantType, urgentType: $urgentType, colorA: $colorA, colorR: $colorR, colorG: $colorG, colorB: $colorB, locations: $locations}';
  }
}
