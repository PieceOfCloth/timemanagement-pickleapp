import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';

class AddActivityList {
  String userID;
  String title;
  String? impType;
  String? urgType;
  String date;
  DateTime? strTime;
  DateTime? endTime;
  int duration;
  List<Tasks>? tasks;
  String? cat;
  String? rptIntv;
  int? rptDur;
  bool isFixed;
  List<Notifications>? notif;
  List<Locations>? locations;
  List<Files>? files;

  AddActivityList({
    required this.userID,
    required this.title,
    required this.impType,
    required this.urgType,
    required this.date,
    required this.isFixed,
    this.strTime,
    this.endTime,
    required this.duration,
    this.tasks,
    this.cat,
    this.rptIntv,
    this.rptDur,
    this.notif,
    this.locations,
    this.files,
  });

  @override
  String toString() {
    return '{"title": $title, "important_type": $impType, "urgent_type": $urgType, "isFixed:" $isFixed, "date": $date, "start_time": $strTime, "duration": $duration, "task": $tasks, "category": $cat, "repeat_interval": $rptIntv, "repeat_duration": $rptDur, "notification": $notif, "location": $locations, "files": $files}';
  }

  // factory AddActivityList.fromJson(Map<String, dynamic> json) {
  //   return AddActivityList(
  //     title: json['title'] as String,
  //     impType: json['important_type'] as String,
  //     urgType: json['urgent_type'] as String,
  //     date: json['date'] as String,
  //     strTime: json['start_time'] as String?,
  //     duration: json['duration'] as int,
  //     tasks: json['tasks'],
  //     cat: json['category'] as String?,
  //     rptIntv: json['repeat_interval'] as String?,
  //     rptDur: json['repeat_duration'] as int?,
  //     notif: json['notification'],
  //     locations: json['locations'],
  //     files: json['files'],
  //   );
  // }
}
