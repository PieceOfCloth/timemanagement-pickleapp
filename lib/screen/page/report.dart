// ignore_for_file: avoid_print, avoid_types_as_parameter_names

import 'dart:core';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/activity_log.dart';
import 'package:pickleapp/screen/class/log.dart';
import 'package:pickleapp/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  ReportState createState() => ReportState();
}

class ReportState extends State<Report> {
  String timeFrame = "Semua";
  String month1 = "Juli";
  int year1 = DateTime.now().year;
  int touchedIndex = 0;
  String week1 = "Minggu 1";
  // String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime theDay = DateTime.now();

  CalendarFormat calendarFormat = CalendarFormat.week;

  List<ActivityLog> logActivity = [];
  List<PriorityLog> logPriority = [];

  List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  List<String> weeks = [
    'Minggu 1',
    'Minggu 2',
    'Minggu 3',
    'Minggu 4',
    'Minggu 5'
  ];

  List<int> years = List.generate(5, (index) => DateTime.now().year - index);

  String getPriorityCategory(String importance, String urgent) {
    if (importance == "Penting" && urgent == "Mendesak") {
      return "Bola Golf";
    } else if (importance == "Penting" && urgent == "Tidak Mendesak") {
      return "Kerikil";
    } else if (importance == "Tidak Penting" && urgent == "Mendesak") {
      return "Pasir";
    } else {
      return "Air";
    }
  }

  Color getPriorityColor(String priorityType) {
    if (priorityType == 'Bola Golf') {
      return Colors.red;
    } else if (priorityType == 'Kerikil') {
      return Colors.yellow;
    } else if (priorityType == 'Pasir') {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  Color? getPriorityColorBurem(String priorityType) {
    if (priorityType == 'Bola Golf') {
      return Colors.red[200];
    } else if (priorityType == 'Kerikil') {
      return Colors.yellow[200];
    } else if (priorityType == 'Pasir') {
      return Colors.green[200];
    } else {
      return Colors.blue[200];
    }
  }

  String getPriorityScale(String priority) {
    if (priority == 'Bola Golf') {
      return "Prioritas Utama";
    } else if (priority == 'Kerikil') {
      return "Prioritas Tinggi";
    } else if (priority == 'Pasir') {
      return "Prioritas Sedang";
    } else {
      return "Prioritas Rendah";
    }
  }

  Future<List<ActivityLog>> getActivityDailyLog() async {
    logActivity.clear();

    if (timeFrame == "Semua") {
      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .get();
      for (var act in actSnap.docs) {
        var actID = act.id;
        var impt = act['tipe_kepentingan'];
        var urgnt = act['tipe_mendesak'];

        final schedSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .doc(actID)
            .get();

        var start = (schedSnap.data()?['waktu_mulai'] as Timestamp).toDate();
        var end = (schedSnap.data()?['waktu_akhir'] as Timestamp).toDate();

        int totalPlannedTime = end.difference(start).inSeconds;

        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where('kegiatans_id', isEqualTo: actID)
            .get();

        for (var i in logSnap.docs) {
          logActivity.add(ActivityLog(
            title: act['nama'],
            timePlan: totalPlannedTime,
            timeSpent: i['waktu_asli_penggunaan'],
            type: getPriorityCategory(impt, urgnt),
            startTime: start,
            endTime: end,
          ));
        }
      }
    } else if (timeFrame == "Harian") {
      DateTime startOfDay = DateTime(theDay.year, theDay.month, theDay.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      for (var act in actSnap.docs) {
        var actID = act.id;
        var impt = act['tipe_kepentingan'];
        var urgnt = act['tipe_mendesak'];

        final docSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .doc(actID)
            .get();
        if (docSnap.exists) {
          DateTime startTime =
              (docSnap.data()?['waktu_mulai'] as Timestamp).toDate();
          DateTime endTime =
              (docSnap.data()?['waktu_akhir'] as Timestamp).toDate();

          int totalPlannedTime = endTime.difference(startTime).inSeconds;

          QuerySnapshot logSnap = await FirebaseFirestore.instance
              .collection('logs')
              .where('kegiatans_id', isEqualTo: actID)
              .get();

          for (var i in logSnap.docs) {
            logActivity.add(ActivityLog(
              title: act['nama'],
              timePlan: totalPlannedTime,
              timeSpent: i['waktu_asli_penggunaan'],
              type: getPriorityCategory(impt, urgnt),
              startTime: startTime,
              endTime: endTime,
            ));
          }
        }
      }
    } else if (timeFrame == "Mingguan") {
      int weekNum;
      if (week1 == "Minggu 1") {
        weekNum = 1;
      } else if (week1 == "Minggu 2") {
        weekNum = 2;
      } else if (week1 == "Minggu 3") {
        weekNum = 3;
      } else {
        weekNum = 4;
      }

      DateTime firstDayOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      DateTime startOfWeek = firstDayOfMonth;
      while (startOfWeek.weekday != DateTime.monday) {
        startOfWeek = startOfWeek.subtract(const Duration(days: 1));
      }
      startOfWeek = startOfWeek.add(Duration(days: 7 * (weekNum - 1)));

      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfWeek))
          .get();

      for (var act in actSnap.docs) {
        var actID = act.id;
        var impt = act['tipe_kepentingan'];
        var urgnt = act['tipe_mendesak'];

        final docSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .doc(actID)
            .get();
        if (docSnap.exists) {
          DateTime startTime =
              (docSnap.data()?['waktu_mulai'] as Timestamp).toDate();
          DateTime endTime =
              (docSnap.data()?['waktu_akhir'] as Timestamp).toDate();

          int totalPlannedTime = endTime.difference(startTime).inSeconds;

          QuerySnapshot logSnap = await FirebaseFirestore.instance
              .collection('logs')
              .where('kegiatans_id', isEqualTo: actID)
              .get();

          for (var i in logSnap.docs) {
            logActivity.add(ActivityLog(
              title: act['nama'],
              timePlan: totalPlannedTime,
              timeSpent: i['waktu_asli_penggunaan'],
              type: getPriorityCategory(impt, urgnt),
              startTime: startTime,
              endTime: endTime,
            ));
          }
        }
      }
    } else {
      DateTime firstDayOfMonth = DateTime(year1, months.indexOf(month1) + 1, 1);
      DateTime lastDayOfMonth = DateTime(year1, months.indexOf(month1) + 2, 0);

      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(lastDayOfMonth))
          .get();

      for (var act in actSnap.docs) {
        var actID = act.id;
        var impt = act['tipe_kepentingan'];
        var urgnt = act['tipe_mendesak'];

        final docSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .doc(actID)
            .get();
        if (docSnap.exists) {
          DateTime startTime =
              (docSnap.data()?['waktu_mulai'] as Timestamp).toDate();
          DateTime endTime =
              (docSnap.data()?['waktu_akhir'] as Timestamp).toDate();

          int totalPlannedTime = endTime.difference(startTime).inSeconds;

          QuerySnapshot logSnap = await FirebaseFirestore.instance
              .collection('logs')
              .where('kegiatans_id', isEqualTo: actID)
              .get();

          for (var i in logSnap.docs) {
            logActivity.add(ActivityLog(
              title: act['nama'],
              timePlan: totalPlannedTime,
              timeSpent: i['waktu_asli_penggunaan'],
              type: getPriorityCategory(impt, urgnt),
              startTime: startTime,
              endTime: endTime,
            ));
          }
        }
      }
    }

    return logActivity;
  }

  Future<List<PriorityLog>> getPriorityLog() async {
    logPriority.clear();

    logPriority = [
      PriorityLog(type: 'Bola Golf', timeSpent: 0),
      PriorityLog(type: 'Kerikil', timeSpent: 0),
      PriorityLog(type: 'Pasir', timeSpent: 0),
      PriorityLog(type: 'Air', timeSpent: 0),
    ];

    if (timeFrame == "Semua") {
      QuerySnapshot logSnap =
          await FirebaseFirestore.instance.collection('logs').get();
      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .get();

// Membuat peta aktivitas berdasarkan ID dokumen
      Map<String, Map<String, String>> activityMap = {};
      for (var doc in actSnap.docs) {
        activityMap[doc.id] = {
          'important_type': doc['tipe_kepentingan'],
          'urgent_type': doc['tipe_mendesak'],
        };
      }

      for (var logDoc in logSnap.docs) {
        String scheduledId1 = logDoc['kegiatans_id'];
        int actualTimeSpent = logDoc['waktu_asli_penggunaan'];

        // Mendapatkan dokumen berdasarkan ID yang dijadwalkan
        final schedDoc1 = await FirebaseFirestore.instance
            .collection('kegiatans')
            .doc(scheduledId1)
            .get();

        if (schedDoc1.exists) {
          // Memeriksa apakah peta aktivitas berisi ID dokumen
          if (activityMap.containsKey(scheduledId1)) {
            String importantType =
                activityMap[scheduledId1]!['important_type']!;
            String urgentType = activityMap[scheduledId1]!['urgent_type']!;
            String priorityCategory =
                getPriorityCategory(importantType, urgentType);

            for (var priorityLog in logPriority) {
              if (priorityLog.type == priorityCategory) {
                priorityLog.timeSpent += actualTimeSpent;
              }
            }
          }
        }
      }
    } else if (timeFrame == "Harian") {
      DateTime startOfDay = DateTime(theDay.year, theDay.month, theDay.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot schedSnap2 = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfDay))
          .where('users_id', isEqualTo: userID)
          .get();

      for (var doc1 in schedSnap2.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where("kegiatans_id", isEqualTo: doc1.id)
            .get();
        QuerySnapshot actSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .where('users_id', isEqualTo: userID)
            .get();

        Map<String, Map<String, String>> activityMap = {};
        for (var doc in actSnap.docs) {
          activityMap[doc.id] = {
            'tipe_kepentingan': doc['tipe_kepentingan'],
            'tipe_mendesak': doc['tipe_mendesak'],
          };
        }

        for (var logDoc in logSnap.docs) {
          String scheduledId1 = logDoc['kegiatans_id'];
          int actualTimeSpent = logDoc['waktu_asli_penggunaan'];

          final schedDoc1 = await FirebaseFirestore.instance
              .collection('kegiatans')
              .doc(scheduledId1)
              .get();
          if (schedDoc1.exists) {
            if (activityMap.containsKey(scheduledId1)) {
              String importantType =
                  activityMap[scheduledId1]!['tipe_kepentingan']!;
              String urgentType = activityMap[scheduledId1]!['tipe_mendesak']!;
              String priorityCategory =
                  getPriorityCategory(importantType, urgentType);

              for (var priorityLog in logPriority) {
                if (priorityLog.type == priorityCategory) {
                  priorityLog.timeSpent += actualTimeSpent;
                }
              }
            }
          }
        }
      }
    } else if (timeFrame == "Mingguan") {
      int weekNum;
      if (week1 == "Minggu 1") {
        weekNum = 1;
      } else if (week1 == "Minggu 2") {
        weekNum = 2;
      } else if (week1 == "Minggu 3") {
        weekNum = 3;
      } else {
        weekNum = 4;
      }

      DateTime firstDayOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      DateTime startOfWeek = firstDayOfMonth;
      while (startOfWeek.weekday != DateTime.monday) {
        startOfWeek = startOfWeek.subtract(const Duration(days: 1));
      }
      startOfWeek = startOfWeek.add(Duration(days: 7 * (weekNum - 1)));

      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

      QuerySnapshot schedSnap2 = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfWeek))
          .where('users_id', isEqualTo: userID)
          .get();

      for (var doc1 in schedSnap2.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where("kegiatans_id", isEqualTo: doc1.id)
            .get();
        QuerySnapshot actSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .where('users_id', isEqualTo: userID)
            .get();

        Map<String, Map<String, String>> activityMap = {};
        for (var doc in actSnap.docs) {
          activityMap[doc.id] = {
            'tipe_kepentingan': doc['tipe_kepentingan'],
            'tipe_mendesak': doc['tipe_mendesak'],
          };
        }

        for (var logDoc in logSnap.docs) {
          String scheduledId1 = logDoc['kegiatans_id'];
          int actualTimeSpent = logDoc['waktu_asli_penggunaan'];

          final schedDoc1 = await FirebaseFirestore.instance
              .collection('kegiatans')
              .doc(scheduledId1)
              .get();
          if (schedDoc1.exists) {
            if (activityMap.containsKey(scheduledId1)) {
              String importantType =
                  activityMap[scheduledId1]!['tipe_kepentingan']!;
              String urgentType = activityMap[scheduledId1]!['tipe_mendesak']!;
              String priorityCategory =
                  getPriorityCategory(importantType, urgentType);

              for (var priorityLog in logPriority) {
                if (priorityLog.type == priorityCategory) {
                  priorityLog.timeSpent += actualTimeSpent;
                }
              }
            }
          }
        }
      }
    } else {
      DateTime firstDayOfMonth = DateTime(year1, months.indexOf(month1) + 1, 1);
      DateTime lastDayOfMonth = DateTime(year1, months.indexOf(month1) + 2, 0);

      QuerySnapshot schedSnap2 = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(lastDayOfMonth))
          .where('users_id', isEqualTo: userID)
          .get();

      for (var doc1 in schedSnap2.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where("kegiatans_id", isEqualTo: doc1.id)
            .get();
        QuerySnapshot actSnap = await FirebaseFirestore.instance
            .collection('kegiatans')
            .where('users_id', isEqualTo: userID)
            .get();

        Map<String, Map<String, String>> activityMap = {};
        for (var doc in actSnap.docs) {
          activityMap[doc.id] = {
            'tipe_kepentingan': doc['tipe_kepentingan'],
            'tipe_mendesak': doc['tipe_mendesak'],
          };
        }

        for (var logDoc in logSnap.docs) {
          String scheduledId1 = logDoc['kegiatans_id'];
          int actualTimeSpent = logDoc['waktu_asli_penggunaan'];

          final schedDoc1 = await FirebaseFirestore.instance
              .collection('kegiatans')
              .doc(scheduledId1)
              .get();
          if (schedDoc1.exists) {
            if (activityMap.containsKey(scheduledId1)) {
              String importantType =
                  activityMap[scheduledId1]!['tipe_kepentingan']!;
              String urgentType = activityMap[scheduledId1]!['tipe_mendesak']!;
              String priorityCategory =
                  getPriorityCategory(importantType, urgentType);

              for (var priorityLog in logPriority) {
                if (priorityLog.type == priorityCategory) {
                  priorityLog.timeSpent += actualTimeSpent;
                }
              }
            }
          }
        }
      }
    }
    return logPriority;
  }

  Future<int> getTotalKegiatanDone() async {
    QuerySnapshot kegiatanSnap;
    DateTime startOfDay = DateTime(theDay.year, theDay.month, theDay.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    if (timeFrame == "Semua") {
      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('status', isEqualTo: true)
          .where('users_id', isEqualTo: userID)
          .get();
    } else if (timeFrame == "Harian") {
      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('status', isEqualTo: true)
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
    } else if (timeFrame == "Mingguan") {
      int weekNum;
      if (week1 == "Minggu 1") {
        weekNum = 1;
      } else if (week1 == "Minggu 2") {
        weekNum = 2;
      } else if (week1 == "Minggu 3") {
        weekNum = 3;
      } else {
        weekNum = 4;
      }

      DateTime firstDayOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      DateTime startOfWeek = firstDayOfMonth;
      while (startOfWeek.weekday != DateTime.monday) {
        startOfWeek = startOfWeek.subtract(const Duration(days: 1));
      }
      startOfWeek = startOfWeek.add(Duration(days: 7 * (weekNum - 1)));

      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('status', isEqualTo: true)
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfWeek))
          .get();
    } else {
      DateTime firstDayOfMonth = DateTime(year1, months.indexOf(month1) + 1, 1);
      DateTime lastDayOfMonth = DateTime(year1, months.indexOf(month1) + 2, 0);

      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('status', isEqualTo: true)
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(lastDayOfMonth))
          .get();
    }

    return kegiatanSnap.docs.length;
  }

  Future<int> getTotalFokusTime() async {
    QuerySnapshot kegiatanSnap;
    DateTime startOfDay = DateTime(theDay.year, theDay.month, theDay.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    int totalWaktuAsliPenggunaan = 0;

    if (timeFrame == "Semua") {
      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .get();

      for (var i in kegiatanSnap.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where('kegiatans_id', isEqualTo: i.id)
            .get();

        for (var logDoc in logSnap.docs) {
          int waktuAsliPenggunaan = logDoc['waktu_asli_penggunaan'];
          totalWaktuAsliPenggunaan += waktuAsliPenggunaan;
        }
      }
    } else if (timeFrame == "Harian") {
      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var i in kegiatanSnap.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where('kegiatans_id', isEqualTo: i.id)
            .get();

        for (var logDoc in logSnap.docs) {
          int waktuAsliPenggunaan = logDoc['waktu_asli_penggunaan'];
          totalWaktuAsliPenggunaan += waktuAsliPenggunaan;
        }
      }
    } else if (timeFrame == "Mingguan") {
      int weekNum;
      if (week1 == "Minggu 1") {
        weekNum = 1;
      } else if (week1 == "Minggu 2") {
        weekNum = 2;
      } else if (week1 == "Minggu 3") {
        weekNum = 3;
      } else {
        weekNum = 4;
      }

      DateTime firstDayOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      DateTime startOfWeek = firstDayOfMonth;
      while (startOfWeek.weekday != DateTime.monday) {
        startOfWeek = startOfWeek.subtract(const Duration(days: 1));
      }
      startOfWeek = startOfWeek.add(Duration(days: 7 * (weekNum - 1)));

      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(endOfWeek))
          .get();

      for (var i in kegiatanSnap.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where('kegiatans_id', isEqualTo: i.id)
            .get();

        for (var logDoc in logSnap.docs) {
          int waktuAsliPenggunaan = logDoc['waktu_asli_penggunaan'];
          totalWaktuAsliPenggunaan += waktuAsliPenggunaan;
        }
      }
    } else {
      DateTime firstDayOfMonth = DateTime(year1, months.indexOf(month1) + 1, 1);
      DateTime lastDayOfMonth = DateTime(year1, months.indexOf(month1) + 2, 0);

      kegiatanSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('users_id', isEqualTo: userID)
          .where('waktu_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('waktu_akhir', isLessThan: Timestamp.fromDate(lastDayOfMonth))
          .get();

      for (var i in kegiatanSnap.docs) {
        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where('kegiatans_id', isEqualTo: i.id)
            .get();

        for (var logDoc in logSnap.docs) {
          int waktuAsliPenggunaan = logDoc['waktu_asli_penggunaan'];
          totalWaktuAsliPenggunaan += waktuAsliPenggunaan;
        }
      }
    }

    return totalWaktuAsliPenggunaan;
  }

  int calculateTotalTimeSpent(List<PriorityLog> logPriority) {
    int totalTimeSpent = 0;
    for (PriorityLog log in logPriority) {
      totalTimeSpent += log.timeSpent;
    }
    return totalTimeSpent;
  }

  String formatTime(int detik) {
    // int hour = detik ~/ 3600;
    int minute = detik ~/ 60;
    int second = detik % 60;

    // if (minute >= 60) {
    //   minute = minute % 60;
    // }

    return '${minute.toString().padLeft(2, '0')} m : ${second.toString().padLeft(2, '0')} s';
  }

  String formatSeconds(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    return '$minutes menit $seconds detik';
  }

  Widget totalKegiatanDone(BuildContext context) {
    return FutureBuilder<int>(
      future: getTotalKegiatanDone(),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("Kegiatan selesai:", style: textStyleBold),
              ),
              const SizedBox(
                height: 10,
              ),
              Text("${snapshot.data} Kegiatan", style: textStyle)
            ],
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pie_chart),
              Text("Tidak ada data", style: subHeaderStyle),
            ],
          );
        }
      },
    );
  }

  Widget totalTaskDone(BuildContext context) {
    return FutureBuilder<int>(
      future: getTotalFokusTime(),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("Waktu fokus: ", style: textStyleBold),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(formatSeconds(snapshot.data ?? 0), style: textStyle)
            ],
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pie_chart),
              Text("Tidak ada data", style: subHeaderStyle),
            ],
          );
        }
      },
    );
  }

  Widget radialChart(BuildContext context) {
    return FutureBuilder<List<PriorityLog>>(
        future: getPriorityLog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pie_chart),
                Text("Tidak ada data", style: subHeaderStyle),
              ],
            );
          } else {
            final logPri = snapshot.data!;
            print(logPri);
            int totalTime = calculateTotalTimeSpent(logPri);
            print("Total waktu: $totalTime");
            bool allZero = logPri.every((log) => log.timeSpent == 0);

            if (allZero) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pie_chart),
                  Text("Tidak ada data", style: subHeaderStyle),
                ],
              );
            } else {
              return Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.6,
                    child: PieChart(
                      PieChartData(
                        borderData: FlBorderData(
                          show: false,
                        ),
                        sectionsSpace: 0,
                        centerSpaceRadius: 0,
                        sections: logPri.map((log) {
                          return PieChartSectionData(
                            color: getPriorityColor(log.type),
                            value: log.timeSpent / totalTime * 100,
                            title:
                                '${(log.timeSpent / totalTime * 100).toStringAsFixed(1)}%',
                            titleStyle: textStyleBold,
                            radius: 100.0,
                            badgePositionPercentageOffset: 0.98,
                            badgeWidget: AnimatedContainer(
                              duration: PieChart.defaultDuration,
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.5),
                                    offset: const Offset(3, 3),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(40 * .15),
                              child: Center(
                                child: Image.asset(
                                  getPriorityImage(log.type),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      bottom: 5,
                    ),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: logPri.map((log) {
                          return Container(
                            margin: const EdgeInsets.only(
                              right: 5,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(10),
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: MediaQuery.of(context).size.width * 0.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: getPriorityColor(log.type),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    getPriorityImage(log.type),
                                  ),
                                ),
                                Text(
                                  "${log.type} (${getPriorityScale(log.type)})",
                                ),
                                Expanded(
                                  child: Text(
                                    formatTime(log.timeSpent),
                                    style: textStyleBold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }
          }
        });
  }

  Widget verticalBarChart(BuildContext context) {
    return FutureBuilder(
        future: getActivityDailyLog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == []) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pie_chart),
                Text("Tidak ada data", style: subHeaderStyle),
              ],
            );
          } else {
            final actPri = snapshot.data!;
            print(actPri);
            bool allZero = actPri.isEmpty;

            if (allZero) {
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.pie_chart),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text("Tidak ada data", style: subHeaderStyle),
                    ),
                  ],
                ),
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: actPri.length *
                      100.0, // Adjust the width based on the number of bars
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.white,
                          tooltipHorizontalAlignment:
                              FLHorizontalAlignment.right,
                          tooltipMargin: -10,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final act = actPri[groupIndex];
                            String tooltipText = '';

                            // Determine which bar was clicked based on rodIndex
                            if (rodIndex == 0) {
                              // First bar (timePlan)
                              tooltipText =
                                  'Waktu rencana:\n${formatTime(rod.toY.toInt())}';
                            } else if (rodIndex == 1) {
                              tooltipText =
                                  'Waktu aktual:\n${formatTime(rod.toY.toInt())}';
                            }
                            return BarTooltipItem(
                              '${act.title}\n',
                              textStyleBold,
                              children: <TextSpan>[
                                TextSpan(
                                  text: tooltipText,
                                  style: textStyle,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      alignment: BarChartAlignment.spaceBetween,
                      groupsSpace: 100.0,
                      borderData: FlBorderData(
                        show: true,
                        border: const Border.symmetric(
                          horizontal: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          drawBelowEverything: true,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 90,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                formatTime(value.toInt()),
                                textAlign: TextAlign.left,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          drawBelowEverything: false,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 80,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              );
                              Widget text;
                              if (value.toInt() >= 0 &&
                                  value.toInt() <= actPri.length) {
                                text = Transform.rotate(
                                  angle: 45 * (pi / 180),
                                  child: Text(
                                    "${actPri[value.toInt()].title!} (${DateFormat('d MMM').format(actPri[value.toInt()].startTime!)})",
                                    style: style,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              } else {
                                text = const Text("", style: style);
                              }
                              return SideTitleWidget(
                                axisSide: AxisSide.bottom,
                                space: 8,
                                child: text,
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 120,
                            getTitlesWidget: (value, meta) {
                              return const Text("");
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Colors.grey,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(
                        actPri.length,
                        (i) {
                          final act = actPri[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: act.timePlan!.toDouble(),
                                color: getPriorityColor(act.type ?? ""),
                                width: 15,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 20,
                                  color: Colors.yellow.withOpacity(0.3),
                                ),
                              ),
                              BarChartRodData(
                                toY: act.timeSpent!.toDouble(),
                                color: getPriorityColorBurem(act.type ?? ""),
                                width: 15,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 20,
                                  color: Colors.yellow.withOpacity(0.3),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        });
  }

  String getPriorityImage(String type) {
    if (type == 'Bola Golf') {
      return 'assets/golfBall_1.png';
    } else if (type == 'Kerikil') {
      return 'assets/pebbles_1.png';
    } else if (type == 'Pasir') {
      return 'assets/sand_1.png';
    } else {
      return 'assets/water_1.png';
    }
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    if (value.toInt() >= 0 && value.toInt() < logActivity.length) {
      text = Text(
        logActivity[value.toInt()].title ?? "",
        style: style,
      );
    } else {
      text = const Text("", style: style);
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: text,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 66),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            margin: const EdgeInsets.only(
              top: 10,
              left: 20,
              right: 20,
            ),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    child: Text(
                      "Laporan Kegiatan",
                      style: screenTitleStyleWhite,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                    ),
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    alignment: Alignment.centerLeft,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: DropdownButtonFormField(
                      isExpanded: true,
                      value: timeFrame,
                      hint: Text(
                        "Pilih salah satu waktu",
                        style: textStyleWhite,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: "Semua",
                          child: Text(
                            "Semua",
                            style: textStyle,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Bulanan",
                          child: Text(
                            "Bulanan",
                            style: textStyle,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Mingguan",
                          child: Text(
                            "Mingguan",
                            style: textStyle,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Harian",
                          child: Text(
                            "Harian",
                            style: textStyle,
                          ),
                        ),
                      ],
                      onChanged: (v) async {
                        setState(() {
                          timeFrame = v!;
                          theDay = DateTime.now();
                          print(timeFrame);
                        });
                      },
                    ),
                  ),
                  timeFrame == "Semua"
                      ? const SizedBox()
                      : timeFrame == "Harian"
                          ? Container(
                              margin:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: TableCalendar(
                                locale: 'id_ID',
                                focusedDay: _focusedDay,
                                firstDay: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDay: DateTime.now()
                                    .add(const Duration(days: 365)),
                                calendarFormat: calendarFormat,
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                    theDay = _selectedDay;
                                    // _selectedDate =
                                    //     DateFormat("yyyy-MM-dd").format(selectedDay);
                                    // getActivityDailyLog();
                                    // getPriorityLog();
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  defaultTextStyle: subHeaderStyleBoldWhite,
                                  weekendTextStyle: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  selectedTextStyle: subHeaderStyleBold,
                                  todayTextStyle: subHeaderStyleBold,
                                  todayDecoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                headerVisible: true,
                                headerStyle: HeaderStyle(
                                  titleCentered: true,
                                  titleTextStyle: subHeaderStyleBoldWhite,
                                  formatButtonVisible: false,
                                  formatButtonShowsNext: false,
                                ),
                              ),
                            )
                          : timeFrame == "Bulanan"
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        width: constraints.maxWidth,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Colors.white,
                                        ),
                                        child: DropdownButtonFormField(
                                          isExpanded: true,
                                          value: month1,
                                          hint: Text(
                                            "Pilih salah satu waktu",
                                            style: textStyleWhite,
                                          ),
                                          items: months
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: textStyle,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) async {
                                            setState(() {
                                              month1 = v!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        width: constraints.maxWidth,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Colors.white,
                                        ),
                                        child: DropdownButtonFormField(
                                          isExpanded: true,
                                          value: year1,
                                          hint: Text(
                                            "Pilih salah satu waktu",
                                            style: textStyleWhite,
                                          ),
                                          items: years
                                              .map<DropdownMenuItem<int>>(
                                                  (int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(
                                                value.toString(),
                                                style: textStyle,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (int? v) {
                                            setState(() {
                                              year1 = v!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  width: constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonFormField(
                                    isExpanded: true,
                                    value: week1,
                                    hint: Text(
                                      "Pilih salah satu waktu",
                                      style: textStyleWhite,
                                    ),
                                    items: weeks.map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child:
                                            Text(value, style: textStyleBold),
                                      );
                                    }).toList(),
                                    onChanged: (v) async {
                                      setState(() {
                                        week1 = v!;
                                      });
                                    },
                                  ),
                                ),
                  Container(
                    width: constraints.maxWidth,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth,
                          child: Text(
                            "Durasi Prioritas Kegiatan",
                            style: subHeaderStyleBold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width * 0.85,
                            child: radialChart(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          width: constraints.maxWidth,
                          height: MediaQuery.of(context).size.width * 0.2,
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: totalKegiatanDone(context),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Container(
                          width: constraints.maxWidth,
                          height: MediaQuery.of(context).size.width * 0.2,
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: totalTaskDone(context),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Perbandingan Waktu Rencana VS Aktual",
                      style: textStyleBoldWhite,
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth,
                    height: MediaQuery.of(context).size.height * 0.6,
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: verticalBarChart(context),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
