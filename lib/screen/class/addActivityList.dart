import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';

class AddActivityList {
  String userID;
  String title;
  String? imp_type;
  String? urg_type;
  String date;
  String? str_time;
  int duration;
  List<Tasks>? tasks;
  String? cat;
  String? rpt_intv;
  int? rpt_dur;
  String timezone;
  List<Notifications>? notif;
  List<Locations>? locations;
  List<Files>? files;

  AddActivityList({
    required this.userID,
    required this.title,
    required this.imp_type,
    required this.urg_type,
    required this.date,
    required this.str_time,
    required this.duration,
    required this.timezone,
    this.tasks,
    this.cat,
    this.rpt_intv,
    this.rpt_dur,
    this.notif,
    this.locations,
    this.files,
  });

  @override
  String toString() {
    return '{"title": "$title", "important_type": "$imp_type", "urgent_type": "$urg_type", "date": "$date", "start_time": "$str_time", "duration": $duration, "task": $tasks, "category": "$cat", "repeat_interval": "$rpt_intv", "repeat_duration": $rpt_dur, "notification": $notif, "location": $locations, "files": $files, "timezone": $timezone}';
  }

  // factory AddActivityList.fromJson(Map<String, dynamic> json) {
  //   return AddActivityList(
  //     title: json['title'] as String,
  //     imp_type: json['important_type'] as String,
  //     urg_type: json['urgent_type'] as String,
  //     date: json['date'] as String,
  //     str_time: json['start_time'] as String?,
  //     duration: json['duration'] as int,
  //     tasks: json['tasks'],
  //     cat: json['category'] as String?,
  //     rpt_intv: json['repeat_interval'] as String?,
  //     rpt_dur: json['repeat_duration'] as int?,
  //     notif: json['notification'],
  //     locations: json['locations'],
  //     files: json['files'],
  //   );
  // }
}
