import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';

class DetailActivities {
  String idAct;
  String idAct2;
  String idCat;
  String title;
  String impType;
  String urgType;
  String rptFreq;
  int? rptDur;
  String catName;
  int clrA;
  int clrR;
  int clrG;
  int clrB;
  bool status;
  bool isFixed;
  DateTime strTime;
  DateTime endTime;
  List<Tasks>? tasks;
  List<Files>? files;
  List<Locations>? locations;
  List<Notifications>? notif;

  DetailActivities({
    required this.idAct,
    required this.idAct2,
    required this.idCat,
    required this.title,
    required this.impType,
    required this.urgType,
    required this.rptFreq,
    required this.status,
    required this.isFixed,
    this.rptDur,
    required this.catName,
    required this.clrA,
    required this.clrR,
    required this.clrG,
    required this.clrB,
    required this.strTime,
    required this.endTime,
    this.tasks,
    this.files,
    this.locations,
    this.notif,
  });

  factory DetailActivities.fromJson(Map<String, dynamic> json) {
    return DetailActivities(
      idAct: json['activity_id'] as String,
      idAct2: json['activity_id2'] as String,
      idCat: json['categories_id'] as String,
      title: json['title'] as String,
      impType: json['important_type'] as String,
      urgType: json['urgent_type'] as String,
      rptFreq: json['repeat_frequency'] as String,
      rptDur: json['repeat_interval'] as int?,
      catName: json['category_name'] as String,
      clrA: json['color_a'] as int,
      clrR: json['color_r'] as int,
      clrG: json['color_g'] as int,
      clrB: json['color_b'] as int,
      strTime: json['start_time'] as DateTime,
      endTime: json['endTime'] as DateTime,
      status: json['status'] as bool,
      isFixed: json['isFixed'] as bool,
      tasks: json['tasks'],
      files: json['files'],
      locations: json['address'],
      notif: json['notification'],
    );
  }

  @override
  String toString() {
    return 'DetailActivities(idAct: $idAct, idAct2: $idAct2, idCat: $idCat, title: $title, impType: $impType, urgType: $urgType, rptFreq: $rptFreq, rptDur: $rptDur, catName: $catName, clrA: $clrA, clrR: $clrR, clrG: $clrG, clrB: $clrB, strTime: $strTime, endTime: $endTime, tasks: $tasks, files: $files, locations: $locations, notif: $notif)';
  }
}
