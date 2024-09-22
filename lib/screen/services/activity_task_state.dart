import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/class/timer.dart';

class ActivityTaskToday extends ChangeNotifier {
  String? scheduleId;
  DateTime todayDate = DateTime.now();
  List<TimerList> todayActivities = [];
  List<Tasks> tasks = [];
  List<Files> files = [];
  bool _dataLoaded = false;

  String timestampToTimeString(Timestamp timestamp) {
    // Convert the Timestamp to a DateTime object
    DateTime date = timestamp.toDate();

    // Format the DateTime object to "hh:mm a"
    DateFormat formatter = DateFormat('hh:mm a');
    return formatter.format(date);
  }

  Future<void> getListOfTodayActivities() async {
    if (_dataLoaded) return;

    todayActivities.clear();

    final today = DateTime.now();
    final startTime = DateTime(today.year, today.month, today.day);
    final endTime = DateTime(today.year, today.month, today.day, 23, 59, 59);

    if (startTime.isAfter(todayDate)) {
      todayActivities.clear();
    }
    todayDate = startTime;

    final schQuery = await FirebaseFirestore.instance
        .collection('kegiatans')
        .where('waktu_mulai', isGreaterThanOrEqualTo: startTime)
        .where('waktu_mulai', isLessThan: endTime)
        .where('users_id', isEqualTo: userID)
        .get();

    if (schQuery.docs.isNotEmpty) {
      for (var doc in schQuery.docs) {
        todayActivities.add(TimerList(
            status: doc['status'],
            idActivity: doc.id,
            title: doc['nama'],
            startTime: timestampToTimeString(doc['waktu_mulai']),
            endTime: timestampToTimeString(doc['waktu_akhir']),
            importantType: doc['tipe_kepentingan'],
            urgentType: doc['tipe_mendesak']));
      }
    }

    _dataLoaded = true;
    notifyListeners();
  }

  Future<void> getTaskListOfTodayActivities() async {
    tasks.clear();

    final taskQuery = await FirebaseFirestore.instance
        .collection('subtugass')
        .where('kegiatans_id', isEqualTo: scheduleId)
        .get();
    if (taskQuery.docs.isNotEmpty) {
      for (var doc in taskQuery.docs) {
        tasks.add(Tasks(
          id: doc.id,
          task: doc['nama'],
          status: doc['status'],
        ));
      }
    }
    notifyListeners();
  }

  Future<void> getFileListOfTodayActivities() async {
    files.clear();

    final fileSnap = await FirebaseFirestore.instance
        .collection('files')
        .where('kegiatans_id', isEqualTo: scheduleId)
        .get();
    if (fileSnap.docs.isNotEmpty) {
      for (var doc in fileSnap.docs) {
        files.add(Files(
          name: doc['nama'],
          path: doc['path'],
        ));
      }
    }
    notifyListeners();
  }

  void updateStatusTask(String? id, bool? status) async {
    await FirebaseFirestore.instance
        .collection('subtugass')
        .doc(id)
        .update({'status': status});
    notifyListeners();
  }

  void selectSchedule(String? scheduleID) {
    scheduleId = scheduleID;
    notifyListeners();
  }

  void updateStatusKegiatans(String id, bool status) async {
    await FirebaseFirestore.instance
        .collection('kegiatans')
        .doc(id)
        .update({'status': status});
    notifyListeners();
  }

  Future<void> addActivityLog(int timeTotal) async {
    QuerySnapshot checkLog = await FirebaseFirestore.instance
        .collection('logs')
        .where('kegiatans_id', isEqualTo: scheduleId)
        .get();

    // final logSnap = await checkLog.get();

    if (checkLog.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('logs').add({
        'kegiatans_id': scheduleId,
        'waktu_asli_penggunaan': timeTotal,
      });
    } else {
      final logDoc = checkLog.docs.first;
      await FirebaseFirestore.instance
          .collection('logs')
          .doc(logDoc.id)
          .update({'waktu_asli_penggunaan': FieldValue.increment(timeTotal)});
    }
  }

  void resetDataLoaded() {
    _dataLoaded = false;
  }
}
