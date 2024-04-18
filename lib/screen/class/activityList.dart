import 'package:pickleapp/screen/class/location.dart';

class ActivityList {
  String id_activity;
  String id_scheduled;
  String title;
  String start_time;
  String end_time;
  String important_type;
  String urgent_type;
  int color_a;
  int color_r;
  int color_g;
  int color_b;
  String timezone;
  List<Locations>? locations;

  ActivityList({
    required this.id_activity,
    required this.id_scheduled,
    required this.title,
    required this.start_time,
    required this.end_time,
    required this.important_type,
    required this.urgent_type,
    required this.color_a,
    required this.color_r,
    required this.color_g,
    required this.color_b,
    required this.timezone,
    this.locations,
  });

  factory ActivityList.fromJson(Map<String, dynamic> json) {
    return ActivityList(
      id_activity: json['id_activity'] as String,
      id_scheduled: json['id_scheduled'] as String,
      title: json['title'] as String,
      start_time: json['start_time'] as String,
      end_time: json['end_time'] as String,
      important_type: json['important_type'] as String,
      urgent_type: json['urgent_type'] as String,
      color_a: json['color_a'] as int,
      color_r: json['color_r'] as int,
      color_g: json['color_g'] as int,
      color_b: json['color_b'] as int,
      timezone: json['timezone'] as String,
      locations: json['address'],
    );
  }
}
