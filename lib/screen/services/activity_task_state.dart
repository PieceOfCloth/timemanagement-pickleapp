import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/task.dart';

class ActivityTaskToday extends ChangeNotifier {
  String? activityId;
  DateTime todayDate = DateTime.now();
  List<Map<String, dynamic>> todayActivities = [];
  List<Tasks> tasks = [];
  bool _dataLoaded = false;

  Future<void> getListOfTodayActivities() async {
    if (_dataLoaded) return;

    todayActivities.clear();

    final today = DateTime.now();
    final startTime = DateTime(today.year, today.month, today.day);
    final endTime = DateTime(today.year, today.month, today.day, 23, 59, 59);

    Set<String> uniqueID = <String>{};

    if (startTime.isAfter(todayDate)) {
      todayActivities.clear();
    }
    todayDate = startTime;

    final schQuery = await FirebaseFirestore.instance
        .collection('scheduled_activities')
        .where('actual_start_time', isGreaterThanOrEqualTo: startTime)
        .where('actual_start_time', isLessThan: endTime)
        .get();

    if (schQuery.docs.isNotEmpty) {
      for (var doc in schQuery.docs) {
        var actID = doc['activities_id'];
        if (!uniqueID.contains(actID)) {
          final actDoc = await FirebaseFirestore.instance
              .collection('activities')
              .doc(actID)
              .get();
          if (actDoc.exists) {
            if (actDoc.data()!['user_id'] == userID) {
              var actData = actDoc.data()!;

              actData['id'] = actID;

              uniqueID.add(actID);
              todayActivities.add(actData);
            }
          }
        }
      }
    }
    _dataLoaded = true;
    notifyListeners();
  }

  Future<void> getTaskListOfTodayActivities() async {
    tasks.clear();

    final taskQuery = await FirebaseFirestore.instance
        .collection('tasks')
        .where('activities_id', isEqualTo: activityId)
        .get();
    if (taskQuery.docs.isNotEmpty) {
      for (var doc in taskQuery.docs) {
        tasks.add(Tasks(
          id: doc.id,
          task: doc['title'],
          status: doc['status'],
        ));
      }
    }
    notifyListeners();
  }

  void updateStatusTask(String? id, bool? status) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(id)
        .update({'status': status});
    notifyListeners();
  }

  void selectActivity(String? activityID) {
    activityId = activityID;
    notifyListeners();
  }

  Future<void> addActivityLog(int timeTotal) async {
    QuerySnapshot checkLog = await FirebaseFirestore.instance
        .collection('logs')
        .where('activities_id', isEqualTo: activityId)
        .get();

    // final logSnap = await checkLog.get();

    if (checkLog.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('logs').add({
        'activities_id': activityId,
        'actual_time_spent': timeTotal,
      });
    } else {
      final logDoc = checkLog.docs.first;
      await FirebaseFirestore.instance
          .collection('logs')
          .doc(logDoc.id)
          .update({'actual_time_spent': FieldValue.increment(timeTotal)});
    }
  }

  void resetDataLoaded() {
    _dataLoaded = false;
  }
}
