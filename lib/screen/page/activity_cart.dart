// ignore_for_file: avoid_print, use_build_context_synchronously, unrelated_type_equality_checks

import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';

import 'package:pickleapp/screen/class/add_activity_list.dart';
import 'package:pickleapp/screen/page/activity_edit_temporary.dart';
import 'package:pickleapp/theme.dart';

class ActivityCart extends StatefulWidget {
  final List<AddActivityList> temporaryAct;

  const ActivityCart({super.key, required this.temporaryAct});

  @override
  State<ActivityCart> createState() => _ActivityCartState();
}

class _ActivityCartState extends State<ActivityCart> {
  String startTimeAlgorithm = "";
  bool _isCheckedAlgorithm = false;
  bool _isStartExist = false;
  var logger = Logger();
  Map<String, String> firstKegiatanIdMap = {};
  bool isCollision = false;

  List<AddActivityList> scheduleList = [];
  List<AddActivityList> scheduleList2 = [];
  List<AddActivityList> temporaryActiv = [];
  List<AddActivityList> processedListWithStart = [];
  List<AddActivityList> processedListWithoutStart = [];
  List<AddActivityList> processedListFixed = [];
  List<AddActivityList> remainingList = [];

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // For determine priority high medium or so on
  String getPriority(important, urgent) {
    if (important == "Penting" && urgent == "Mendesak") {
      return "Bola Golf (Prioritas Utama)";
    } else if (important == "Penting" && urgent == "Tidak Mendesak") {
      return "Kerikil (Prioritas Tinggi)";
    } else if (important == "Tidak Penting" && urgent == "Mendesak") {
      return "Pasir (Prioritas Sedang)";
    } else {
      return "Air (Prioritas Rendah)";
    }
  }

  // For determine priority high medium or so on
  int getPriorityRank(String important, String urgent) {
    if (important == "Penting" && urgent == "Mendesak") {
      return 4;
    } else if (important == "Penting" && urgent == "Tidak Mendesak") {
      return 3;
    } else if (important == "Tidak Penting" && urgent == "Mendesak") {
      return 2;
    } else {
      return 1;
    }
  }

  // Get priority color based on important und urgent level
  Color getPriorityColor(important, urgent) {
    if (important == "Penting" && urgent == "Mendesak") {
      return Colors.red[600] ?? Colors.red;
    } else if (important == "Penting" && urgent == "Tidak Mendesak") {
      return Colors.yellow[600] ?? Colors.yellow;
    } else if (important == "Tidak Penting" && urgent == "Mendesak") {
      return Colors.green[600] ?? Colors.green;
    } else {
      return Colors.blue[600] ?? Colors.blue;
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  void removeTempAct(int index) {
    setState(() {
      widget.temporaryAct.removeAt(index);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Show theory infographic in a alertdialog
  void _showInfoDialogPriority(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Informasi Tingkat Kepentingan dan Mendesak",
            style: subHeaderStyleBold,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.1,
              maxScale: 5.0,
              child: Image.asset(
                'assets/Pickle Infographic.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Tutup",
                style: textStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  String formatDate(String dateStr) {
    // Parse the input date string
    DateTime dateTime = DateTime.parse(dateStr);

    // Format the date using DateFormat
    DateFormat formatter = DateFormat.yMMMMd('id'); // "March 24, 2024"
    String formattedDate = formatter.format(dateTime);

    return formattedDate;
  }

  // Change format time to hh:mm PM/AM
  DateTime formattedActivityTimeOnly(String inptTime) {
    DateTime formattedTime = DateFormat("hh:mm a").parse(inptTime);

    return formattedTime;
  }

  String formattedTimes(DateTime datetime) {
    DateTime dateTime = DateTime.parse(datetime.toString());
    String formattedTime = DateFormat('hh:mm a').format(dateTime);
    return formattedTime;
  }

  String formattedTimesEnd(DateTime datetime, int dur) {
    DateTime dateTime = DateTime.parse(datetime.toString());
    String formattedTime =
        DateFormat('hh:mm a').format(dateTime.add(Duration(minutes: dur)));
    return formattedTime;
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityEndTimeOnly(String inptTime, int dur) {
    DateTime formattedTime = DateFormat("hh:mm a").parse(inptTime);

    String time =
        DateFormat("hh:mm a").format(formattedTime.add(Duration(minutes: dur)));

    return time;
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  Future<void> openGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Tidak dapat meluncurkan: $url';
    }
  }

  void openFile(String path) {
    OpenFile.open(path);
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Read Category Data
  Future<String> getCategoryData(String? catID) async {
    DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore
        .instance
        .collection('kategoris')
        .doc(catID)
        .get();

    if (data.exists) {
      return data['nama'];
    } else {
      return 'Tidak ada';
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  Future<void> beneranTestAlgoritma() async {
    var groupDate =
        groupBy(widget.temporaryAct, (AddActivityList activ) => activ.date);

    for (var data in groupDate.entries) {
      var aktivitas = data.value;

      setState(() {
        scheduleList.clear();
        processedListWithStart.clear();
        processedListFixed.clear();
        processedListWithoutStart.clear();
        remainingList.clear();
        temporaryActiv.clear();

        for (var s in aktivitas) {
          temporaryActiv.add(AddActivityList(
            userID: userID,
            title: s.title,
            impType: s.impType,
            urgType: s.urgType,
            rptIntv: s.rptIntv,
            rptDur: s.rptDur,
            cat: s.cat,
            date: s.date,
            strTime: s.strTime,
            duration: s.duration,
            isFixed: s.isFixed,
          ));
        }

        processedListWithStart = temporaryActiv
            .where((element) =>
                element.strTime != null && element.isFixed == false)
            .toList();
        processedListWithoutStart =
            temporaryActiv.where((element) => element.strTime == null).toList();
        processedListFixed = temporaryActiv
            .where(
                (element) => element.strTime != null && element.isFixed == true)
            .toList();

        // print(processedListWithStart);
        // print(processedListWithoutStart);

        if (processedListWithStart.isEmpty || processedListWithStart == []) {
          _isStartExist = false;
        } else {
          _isStartExist = true;
        }
      });

      if (_isStartExist == true) {
        await testAlgoritma("");
      } else {
        await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((selectedTime) {
          if (selectedTime != null) {
            setState(() {
              String period = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';

              int hours = selectedTime.hourOfPeriod;
              int minutes = selectedTime.minute;

              String formattedTime =
                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';

              startTimeAlgorithm = formattedTime;

              testAlgoritma(startTimeAlgorithm);

              print(startTimeAlgorithm);
            });
          }
        });
      }
    }
  }

  Future<void> testAlgoritma(String startInput) async {
    AddActivityList? currentSchedule;

    remainingList.addAll(processedListWithoutStart);

    processedListWithStart.sort((a, b) => (a.strTime!).compareTo(b.strTime!));

    DateTime date =
        DateFormat("yyyy-MM-dd").parse(processedListWithStart.first.date);

    DateTime currentTime = processedListWithStart.isNotEmpty
        ? DateTime(
            date.year,
            date.month,
            date.day,
            processedListWithStart.first.strTime!.hour,
            processedListWithStart.first.strTime!.minute,
          )
        : DateTime(
            date.year,
            date.month,
            date.day,
            formattedActivityTimeOnly(startInput).hour,
            formattedActivityTimeOnly(startInput).minute,
          );

    for (var fix in processedListFixed) {
      DateTime tanggal = DateFormat("yyyy-MM-dd").parse(fix.date);

      DateTime waktuMulai = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
        fix.strTime!.hour,
        fix.strTime!.minute,
      );

      scheduleList2.add(AddActivityList(
        userID: userID,
        impType: fix.impType,
        urgType: fix.urgType,
        isFixed: fix.isFixed,
        duration: fix.duration,
        cat: fix.cat,
        title: fix.title,
        strTime: waktuMulai,
        endTime: waktuMulai.add(Duration(minutes: fix.duration)),
        date: fix.date,
      ));
    }

    while (processedListWithStart.isNotEmpty) {
      AddActivityList currentActivity = processedListWithStart.removeAt(0);

      DateTime date2 = DateFormat("yyyy-MM-dd").parse(currentActivity.date);
      DateTime currentStartAct = DateTime(
        date2.year,
        date2.month,
        date2.day,
        currentActivity.strTime!.hour,
        currentActivity.strTime!.minute,
      );

      DateTime? processedStartAct;
      if (processedListWithStart.isNotEmpty) {
        DateTime date3 =
            DateFormat("yyyy-MM-dd").parse(processedListWithStart.first.date);
        processedStartAct = DateTime(
          date3.year,
          date3.month,
          date3.day,
          processedListWithStart.first.strTime!.hour,
          processedListWithStart.first.strTime!.minute,
        );
      }

      if (currentTime.isBefore(currentStartAct) ||
          currentTime.isAtSameMomentAs(currentStartAct)) {
        isCollision = false;
        while (currentActivity.duration > 0) {
          //
          // Check if currentTime overlaps with any fixed activity in scheduleList2
          AddActivityList? overlappingFixedActivity =
              scheduleList2.firstWhereOrNull((fixedActivity) {
            return fixedActivity.strTime == currentTime;
          });

          if (overlappingFixedActivity != null) {
            currentTime = overlappingFixedActivity.endTime!;
            isCollision = true;
          }
          //
          if (processedListWithStart.isNotEmpty &&
              processedStartAct != null &&
              (processedStartAct
                      .isBefore(currentTime.add(const Duration(minutes: 1))) ||
                  processedStartAct.isAtSameMomentAs(
                      currentTime.add(const Duration(minutes: 1))))) {
            AddActivityList nextActivity = processedListWithStart.first;
            if (overlappingFixedActivity != null) {
              currentTime = overlappingFixedActivity.endTime!;
            } else if (getPriorityRank(
                    nextActivity.impType!, nextActivity.urgType!) >
                getPriorityRank(
                    currentActivity.impType!, currentActivity.urgType!)) {
              if (!isCollision) {
                scheduleList.add(AddActivityList(
                  userID: userID,
                  impType: currentActivity.impType,
                  urgType: currentActivity.urgType,
                  isFixed: currentActivity.isFixed,
                  cat: currentActivity.cat,
                  duration: 0,
                  title: currentActivity.title,
                  strTime: currentTime,
                  endTime: currentTime.add(const Duration(minutes: 1)),
                  date: DateFormat('yyyy-MM-dd').format(currentTime),
                ));
              }
              remainingList.add(AddActivityList(
                userID: userID,
                isFixed: currentActivity.isFixed,
                title: currentActivity.title,
                cat: currentActivity.cat,
                impType: currentActivity.impType,
                urgType: currentActivity.urgType,
                date: DateFormat('yyyy-MM-dd').format(currentTime),
                duration: currentActivity.duration - 1,
              ));
              print(currentTime);
              if (!isCollision) {
                currentTime = currentTime.add(const Duration(minutes: 1));
              }
              break;
            } else {
              currentActivity.duration -= 1;
              scheduleList.add(AddActivityList(
                  userID: userID,
                  isFixed: currentActivity.isFixed,
                  title: currentActivity.title,
                  cat: currentActivity.cat,
                  impType: currentActivity.impType,
                  urgType: currentActivity.urgType,
                  date: DateFormat('yyyy-MM-dd').format(currentTime),
                  duration: 0,
                  strTime: currentTime,
                  endTime: currentTime.add(const Duration(minutes: 1))));
              print(currentTime);
              currentTime = currentTime.add(const Duration(minutes: 1));
            }
          } else {
            currentActivity.duration -= 1;
            scheduleList.add(AddActivityList(
                userID: userID,
                isFixed: currentActivity.isFixed,
                cat: currentActivity.cat,
                title: currentActivity.title,
                impType: currentActivity.impType,
                urgType: currentActivity.urgType,
                date: DateFormat('yyyy-MM-dd').format(currentTime),
                duration: 0,
                strTime: currentTime,
                endTime: currentTime.add(const Duration(minutes: 1))));
            print(currentTime);
            currentTime = currentTime.add(const Duration(minutes: 1));
          }
        }
      } else {
        remainingList.add(AddActivityList(
          userID: userID,
          title: currentActivity.title,
          isFixed: currentActivity.isFixed,
          cat: currentActivity.cat,
          impType: currentActivity.impType,
          urgType: currentActivity.urgType,
          date: DateFormat('yyyy-MM-dd').format(currentTime),
          duration: currentActivity.duration,
        ));
      }
    }

    while (remainingList.isNotEmpty) {
      remainingList.sort((a, b) => getPriorityRank(b.impType!, b.urgType!)
          .compareTo(getPriorityRank(a.impType!, a.urgType!)));
      AddActivityList currentActivity = remainingList.removeAt(0);
      while (currentActivity.duration > 0) {
        currentActivity.duration -= 1;
        scheduleList.add(AddActivityList(
            userID: userID,
            isFixed: currentActivity.isFixed,
            cat: currentActivity.cat,
            title: currentActivity.title,
            impType: currentActivity.impType,
            urgType: currentActivity.urgType,
            date: DateFormat('yyyy-MM-dd').format(currentTime),
            duration: 0,
            strTime: currentTime,
            endTime: currentTime.add(const Duration(minutes: 1))));
        currentTime = currentTime.add(const Duration(minutes: 1));
      }
    }

    for (var s in scheduleList) {
      print("Schedule: $s");
    }

    for (var schedule in scheduleList) {
      if (currentSchedule == null) {
        currentSchedule = schedule;
      } else {
        if (currentSchedule.title == schedule.title &&
            currentSchedule.date == schedule.date &&
            currentSchedule.endTime == schedule.strTime) {
          currentSchedule = AddActivityList(
              cat: currentSchedule.cat,
              rptIntv: currentSchedule.rptIntv,
              rptDur: currentSchedule.rptDur,
              userID: userID,
              isFixed: currentSchedule.isFixed,
              title: currentSchedule.title,
              impType: currentSchedule.impType,
              urgType: currentSchedule.urgType,
              date: currentSchedule.date,
              duration: 0,
              strTime: currentSchedule.strTime,
              endTime: schedule.endTime);
        } else {
          scheduleList2.add(currentSchedule);
          currentSchedule = schedule;
        }
      }
    }

    if (currentSchedule != null) {
      scheduleList2.add(currentSchedule);
    }

    for (var sa in scheduleList2) {
      print("$sa");
    }
  }

  // Change format time to yyyy-MM-dd
  String formattedActivityDateOnly(DateTime inptTime) {
    try {
      DateTime time = inptTime;

      DateFormat formatter = DateFormat("yyyy-MM-dd");

      String formattedTime = formatter.format(time);

      return formattedTime;
    } catch (e) {
      print("Error ketika melakukan format tanggal: $e");
      return "";
    }
  }

  Future<void> setToFirestoreWithAlgorithm() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      for (var act in scheduleList2) {
        for (var i = 0; i < (act.rptDur ?? 1); i++) {
          DateTime startTime = act.strTime!;
          DateTime endTime = act.endTime!;
          DateTime startTimeReal;
          DateTime endTimeReal;
          if (act.rptIntv == "Harian") {
            startTimeReal = startTime.add(Duration(days: i));
            endTimeReal = endTime.add(Duration(days: i));
          } else if (act.rptIntv == "Mingguan") {
            startTimeReal = startTime.add(Duration(days: 7 * i));
            endTimeReal = endTime.add(Duration(days: 7 * i));
          } else if (act.rptIntv == "Bulanan") {
            startTimeReal = startTime.add(Duration(days: 30 * i));
            endTimeReal = endTime.add(Duration(days: 7 * i));
          } else if (act.rptIntv == "Tahunan") {
            startTimeReal = startTime.add(Duration(days: 365 * i));
            endTimeReal = endTime.add(Duration(days: 7 * i));
          } else {
            startTimeReal = startTime;
            endTimeReal = endTime;
          }

          DateTime start = startTimeReal;
          DateTime startDate = DateFormat("yyyy-MM-dd")
              .parse(formattedActivityDateOnly((startTimeReal)));
          DateTime end = endTimeReal;

          QuerySnapshot dailyActivities = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('waktu_mulai',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('waktu_mulai',
                  isLessThan: Timestamp.fromDate(
                      startDate.add(const Duration(days: 1))))
              .get();

          for (var activityDoc in dailyActivities.docs) {
            DateTime activityStart =
                (activityDoc['waktu_mulai'] as Timestamp).toDate();
            DateTime activityEnd =
                (activityDoc['waktu_akhir'] as Timestamp).toDate();

            if (start.isBefore(activityEnd) && end.isAfter(activityStart)) {
              if (activityDoc['fixed'] == false) {
                if (activityStart.isBefore(start)) {
                  // Adjust start time if the activity starts before the new activity
                  DateTime newActivityStart =
                      start.subtract(activityEnd.difference(activityStart));
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(newActivityStart),
                    "waktu_akhir": Timestamp.fromDate(newActivityStart
                        .add(activityEnd.difference(activityStart))),
                  });
                } else {
                  // Adjust end time if the activity starts after the new activity
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(end),
                    "waktu_akhir": Timestamp.fromDate(
                        end.add(activityEnd.difference(activityStart))),
                  });
                }
              }
            }
          }

          DocumentReference actID;

          String? existingId = firstKegiatanIdMap[act.title];

          if (existingId == null) {
            // Belum ada ID dokumen untuk title ini, tambahkan dokumen baru dan simpan ID-nya
            actID =
                await FirebaseFirestore.instance.collection('kegiatans').add({
              'nama': act.title,
              'tipe_kepentingan': act.impType,
              'tipe_mendesak': act.urgType,
              'waktu_mulai': Timestamp.fromDate(startTimeReal),
              'waktu_akhir': Timestamp.fromDate(endTimeReal),
              'interval_pengulangan': act.rptIntv ?? "Tidak",
              'durasi_pengulangan': act.rptDur ?? 0,
              'kategoris_id': act.cat,
              'users_id': act.userID,
              'status': false,
              'fixed': act.isFixed,
            });

            // Simpan ID dokumen pertama dengan title ini
            firstKegiatanIdMap[act.title] = actID.id;

            // Perbarui dokumen dengan ID pertama
            await actID.update({'kegiatans_id': actID.id});
          } else {
            // Sudah ada ID dokumen untuk title ini, tambahkan dokumen baru dengan ID pertama
            actID =
                await FirebaseFirestore.instance.collection('kegiatans').add({
              'nama': act.title,
              'tipe_kepentingan': act.impType,
              'tipe_mendesak': act.urgType,
              'waktu_mulai': Timestamp.fromDate(startTimeReal),
              'waktu_akhir': Timestamp.fromDate(endTimeReal),
              'interval_pengulangan': act.rptIntv,
              'durasi_pengulangan': act.rptDur ?? 0,
              'kategoris_id': act.cat,
              'users_id': act.userID,
              'status': false,
              'fixed': act.isFixed,
              'kegiatans_id': existingId,
            });
          }

          for (Notifications notif in act.notif ?? []) {
            DocumentReference notifRef =
                await FirebaseFirestore.instance.collection('notifikasis').add({
              'menit_sebelum': notif.minute,
              'kegiatans_id': actID.id,
            });

            DateTime notifTime =
                startTimeReal.subtract(Duration(minutes: notif.minute));

            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: notifRef.id.hashCode,
                channelKey: 'activity_reminder',
                title: "Kegiatan Selanjutnya - ${act.title}",
                body:
                    "Kegiatanmu akan dimulai pada ${formattedTimes(startTimeReal)}",
                backgroundColor: const Color.fromARGB(255, 255, 170, 0),
                notificationLayout: NotificationLayout.BigText,
                criticalAlert: true,
                wakeUpScreen: true,
                category: NotificationCategory.Reminder,
              ),
              schedule: NotificationCalendar.fromDate(
                date: notifTime,
                preciseAlarm: true,
                allowWhileIdle: true,
              ),
            );
          }

          for (Locations loc in act.locations ?? []) {
            await FirebaseFirestore.instance.collection('lokasis').add({
              'alamat': loc.address,
              'latitude': loc.latitude,
              'longitude': loc.longitude,
              'kegiatans_id': actID.id,
            });
          }

          for (Tasks task in act.tasks ?? []) {
            await FirebaseFirestore.instance.collection('subtugass').add({
              'nama': task.task,
              'status': task.status,
              'kegiatans_id': actID.id,
            });
          }

          for (Files file in act.files ?? []) {
            String folder = "user_files/$userID/${actID.id}";
            String filePath = "$folder/${file.name}";
            await FirebaseFirestore.instance.collection('files').add({
              'nama': file.name,
              'path': "$folder/${file.name}",
              'kegiatans_id': actID.id,
            });
            await FirebaseStorage.instance
                .ref(filePath)
                .putFile(File(file.path));
          }
        }
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
          context: context,
          title: "Kegiatanmu Berhasil Dijadwalkan",
          message:
              "Seluruh Kegiatan kamu telah berhasil dijadwalkan. Terima kasih.");
    } catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
        context: context,
        title: "Error",
        message: "$e",
      );
    }
  }

  // Save temporary activities to the firestore database
  Future<void> setToFirestoreWithoutAlogirhtm(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      for (var act in widget.temporaryAct) {
        if (act.strTime == null || act.strTime == "") {
          Navigator.of(context).pop();
          AlertInformation.showDialogBox(
              context: context,
              title: "Tidak Dapat Menjadwalkan",
              message:
                  "Jika kamu tidak menggunakan FITUR REKOMENDASI, Mohon untuk memastikan semua kegiatan memiliki waktu mulai. Terima kasih.");
          return;
        }
      }

      for (var act in widget.temporaryAct) {
        for (var i = 0; i < (act.rptDur ?? 1); i++) {
          DateTime startTime = act.strTime!;
          DateTime startTimeReal;
          if (act.rptIntv == "Harian") {
            startTimeReal = startTime.add(Duration(days: i));
          } else if (act.rptIntv == "Mingguan") {
            startTimeReal = startTime.add(Duration(days: 7 * i));
          } else if (act.rptIntv == "Bulanan") {
            startTimeReal = startTime.add(Duration(days: 30 * i));
          } else if (act.rptIntv == "Tahunan") {
            startTimeReal = startTime.add(Duration(days: 365 * i));
          } else {
            startTimeReal = startTime;
          }

          DateTime endTime = startTimeReal.add(Duration(minutes: act.duration));

          DateTime start = startTimeReal;
          DateTime startDate = DateFormat("yyyy-MM-dd")
              .parse(formattedActivityDateOnly((startTimeReal)));
          DateTime end = endTime;

          QuerySnapshot dailyActivities = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('waktu_mulai',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('waktu_mulai',
                  isLessThan: Timestamp.fromDate(
                      startDate.add(const Duration(days: 1))))
              .get();

          for (var activityDoc in dailyActivities.docs) {
            DateTime activityStart =
                (activityDoc['waktu_mulai'] as Timestamp).toDate();
            DateTime activityEnd =
                (activityDoc['waktu_akhir'] as Timestamp).toDate();

            if (start.isBefore(activityEnd) && end.isAfter(activityStart)) {
              if (activityDoc['fixed'] == false) {
                if (activityStart.isBefore(start)) {
                  // Adjust start time if the activity starts before the new activity
                  DateTime newActivityStart =
                      start.subtract(activityEnd.difference(activityStart));
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(newActivityStart),
                    "waktu_akhir": Timestamp.fromDate(newActivityStart
                        .add(activityEnd.difference(activityStart))),
                  });
                } else {
                  // Adjust end time if the activity starts after the new activity
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(end),
                    "waktu_akhir": Timestamp.fromDate(
                        end.add(activityEnd.difference(activityStart))),
                  });
                }
              }
            }
          }
          int remainingMinutes = 0;

          DocumentReference actID;

          String? existingId = firstKegiatanIdMap[act.title];

          while (endTime.isAfter(DateTime(startTimeReal.year,
              startTimeReal.month, startTimeReal.day, 23, 59))) {
            DateTime endOfDay = DateTime(startTimeReal.year,
                startTimeReal.month, startTimeReal.day + 1, 0, 0);
            remainingMinutes = endTime.difference(endOfDay).inMinutes;

            if (existingId == null) {
              // Belum ada ID dokumen untuk title ini, tambahkan dokumen baru dan simpan ID-nya
              actID =
                  await FirebaseFirestore.instance.collection('kegiatans').add({
                'nama': act.title,
                'tipe_kepentingan': act.impType,
                'tipe_mendesak': act.urgType,
                'waktu_mulai': Timestamp.fromDate(startTimeReal),
                'waktu_akhir': Timestamp.fromDate(endOfDay),
                'interval_pengulangan': act.rptIntv,
                'durasi_pengulangan': act.rptDur ?? 0,
                'kategoris_id': act.cat,
                'users_id': act.userID,
                'status': false,
                'fixed': act.isFixed,
              });

              // Simpan ID dokumen pertama dengan title ini
              firstKegiatanIdMap[act.title] = actID.id;

              // Perbarui dokumen dengan ID pertama
              await actID.update({'kegiatans_id': actID.id});
            } else {
              // Sudah ada ID dokumen untuk title ini, tambahkan dokumen baru dengan ID pertama
              actID =
                  await FirebaseFirestore.instance.collection('kegiatans').add({
                'nama': act.title,
                'tipe_kepentingan': act.impType,
                'tipe_mendesak': act.urgType,
                'waktu_mulai': Timestamp.fromDate(startTimeReal),
                'waktu_akhir': Timestamp.fromDate(endOfDay),
                'interval_pengulangan': act.rptIntv,
                'durasi_pengulangan': act.rptDur ?? 0,
                'kategoris_id': act.cat,
                'users_id': act.userID,
                'status': false,
                'fixed': act.isFixed,
                'kegiatans_id': existingId,
              });
            }

            for (Notifications notif in act.notif ?? []) {
              DocumentReference notify = await FirebaseFirestore.instance
                  .collection('notifikasis')
                  .add({
                'menit_sebelum': notif.minute,
                'kegiatans_id': actID.id,
              });

              DateTime notiftime =
                  startTimeReal.subtract(Duration(minutes: notif.minute));

              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: notify.id.hashCode,
                  channelKey: 'activity_reminder',
                  title: "Kegiatan Selanjutnya - ${act.title}",
                  body:
                      "Kegiatanmu akan dimulai pada ${formattedTimes(startTimeReal)}",
                  notificationLayout: NotificationLayout.BigText,
                  criticalAlert: true,
                  wakeUpScreen: true,
                  category: NotificationCategory.Reminder,
                ),
                schedule: NotificationCalendar.fromDate(
                  date: notiftime,
                  preciseAlarm: true,
                  allowWhileIdle: true,
                ),
              );
            }

            for (Files file in act.files ?? []) {
              String folder = "user_files/$userID/${actID.id}";
              String filePath = "$folder/${file.name}";
              await FirebaseFirestore.instance.collection('files').add({
                'nama': file.name,
                'path': "$folder/${file.name}",
                'kegiatans_id': actID.id,
              });
              await FirebaseStorage.instance
                  .ref(filePath)
                  .putFile(File(file.path));
            }

            for (Locations loc in act.locations ?? []) {
              await FirebaseFirestore.instance.collection('lokasis').add({
                'alamat': loc.address,
                'latitude': loc.latitude,
                'longitude': loc.longitude,
                'kegiatans_id': actID.id,
              });
            }

            for (Tasks task in act.tasks ?? []) {
              await FirebaseFirestore.instance.collection('subtugass').add({
                'nama': task.task,
                'status': task.status,
                'kegiatans_id': actID.id,
              });
            }

            startTimeReal = DateTime(startTimeReal.year, startTimeReal.month,
                startTimeReal.day + 1, 0, 0);
            endTime = startTimeReal.add(Duration(minutes: remainingMinutes));
          }

          if (existingId == null) {
            // Belum ada ID dokumen untuk title ini, tambahkan dokumen baru dan simpan ID-nya
            actID =
                await FirebaseFirestore.instance.collection('kegiatans').add({
              'nama': act.title,
              'tipe_kepentingan': act.impType,
              'tipe_mendesak': act.urgType,
              'waktu_mulai': Timestamp.fromDate(startTimeReal),
              'waktu_akhir': Timestamp.fromDate(endTime),
              'interval_pengulangan': act.rptIntv,
              'durasi_pengulangan': act.rptDur ?? 0,
              'kategoris_id': act.cat,
              'users_id': act.userID,
              'status': false,
              'fixed': act.isFixed,
            });

            // Simpan ID dokumen pertama dengan title ini
            firstKegiatanIdMap[act.title] = actID.id;

            // Perbarui dokumen dengan ID pertama
            await actID.update({'kegiatans_id': actID.id});
          } else {
            // Sudah ada ID dokumen untuk title ini, tambahkan dokumen baru dengan ID pertama
            actID =
                await FirebaseFirestore.instance.collection('kegiatans').add({
              'nama': act.title,
              'tipe_kepentingan': act.impType,
              'tipe_mendesak': act.urgType,
              'waktu_mulai': Timestamp.fromDate(startTimeReal),
              'waktu_akhir': Timestamp.fromDate(endTime),
              'interval_pengulangan': act.rptIntv,
              'durasi_pengulangan': act.rptDur ?? 0,
              'kategoris_id': act.cat,
              'users_id': act.userID,
              'status': false,
              'fixed': act.isFixed,
              'kegiatans_id': existingId,
            });
          }

          for (Notifications notif in act.notif ?? []) {
            DocumentReference notify =
                await FirebaseFirestore.instance.collection('notifikasis').add({
              'menit_sebelum': notif.minute,
              'kegiatans_id': actID.id,
            });

            DateTime notiftime =
                startTimeReal.subtract(Duration(minutes: notif.minute));

            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: notify.id.hashCode,
                channelKey: 'activity_reminder',
                title: "Kegiatan Selanjutnya - ${act.title}",
                body:
                    "Kegiatanmu akan dimulai pada ${formattedTimes(startTimeReal)}",
                notificationLayout: NotificationLayout.BigText,
                criticalAlert: true,
                wakeUpScreen: true,
                category: NotificationCategory.Reminder,
              ),
              schedule: NotificationCalendar.fromDate(
                date: notiftime,
                preciseAlarm: true,
                allowWhileIdle: true,
              ),
            );
          }

          for (Files file in act.files ?? []) {
            String folder = "user_files/$userID/${actID.id}";
            String filePath = "$folder/${file.name}";
            await FirebaseFirestore.instance.collection('files').add({
              'nama': file.name,
              'path': "$folder/${file.name}",
              'kegiatans_id': actID.id,
            });
            await FirebaseStorage.instance
                .ref(filePath)
                .putFile(File(file.path));
          }

          for (Locations loc in act.locations ?? []) {
            await FirebaseFirestore.instance.collection('lokasis').add({
              'alamat': loc.address,
              'latitude': loc.latitude,
              'longitude': loc.longitude,
              'kegiatans_id': actID.id,
            });
          }

          for (Tasks task in act.tasks ?? []) {
            await FirebaseFirestore.instance.collection('subtugass').add({
              'nama': task.task,
              'status': task.status,
              'kegiatans_id': actID.id,
            });
          }
        }
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
        context: context,
        title: "Kegiatan Telah Sukses Dijadwalkan",
        message:
            "Semua kegiatan kamu telah berhasil untuk dijadwalkan. Terima kasih.",
      );
    } catch (e) {
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
        context: context,
        title: "Error",
        message: "$e",
      );
    }
  }

  void tabAlgorithm() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Jadwal Rekomendasi", style: subHeaderStyleBold),
            content: SizedBox(
              width: double.minPositive,
              height: MediaQuery.of(context).size.height * 0.5,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      tabs: [
                        Tab(
                          child: Text(
                            "Sebelum",
                            style: textStyleBold,
                          ),
                        ),
                        Tab(
                          child: Text(
                            "Sesudah",
                            style: textStyleBold,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          scheduleBefore(),
                          scheduleAfter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  setToFirestoreWithAlgorithm();
                },
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  child: // Space between icon and text
                      Text(
                    'Jadwalkan',
                    style: textStyleBoldWhite,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    // currentSchedule == null;
                    scheduleList.clear();
                    scheduleList2.clear();
                    processedListWithStart.clear();
                    processedListWithoutStart.clear();
                    processedListFixed.clear();
                    remainingList.clear();
                    temporaryActiv.clear();
                  });
                  print(scheduleList2);
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 5),
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      width: 1,
                      color: const Color.fromARGB(255, 3, 0, 66),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: textStyleBold,
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget scheduleBefore() {
    return SingleChildScrollView(
      child: Column(
        children: widget.temporaryAct.map(
          (act) {
            return Container(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: 10,
                top: 10,
              ),
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: getPriorityColor(act.impType, act.urgType),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    act.title,
                    style: subHeaderStyleBold,
                  ),
                  Text(
                    act.date,
                    style: textStyleBold,
                  ),
                  act.strTime == null
                      ? Text(
                          "Tidak ada",
                          style: textStyle,
                        )
                      : Text(
                          "${formattedTimes(act.strTime!)} - ${formattedTimesEnd(act.strTime!, act.duration)}",
                          style: textStyle,
                        ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget scheduleAfter() {
    return ListView.builder(
      itemCount: scheduleList2.length,
      itemBuilder: (context, index) {
        AddActivityList sch = scheduleList2[index];
        return Container(
          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: 10,
            top: 10,
          ),
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: getPriorityColor(sch.impType, sch.urgType),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                sch.title,
                style: subHeaderStyleBold,
                textAlign: TextAlign.center,
              ),
              Text(
                sch.date,
                style: textStyle,
              ),
              Text(
                "${formattedTimes(sch.strTime!)} - ${formattedTimes(sch.endTime!)}",
                style: textStyleBold,
              ),
            ],
          ),
        );
      },
    );
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    print("Temporary Activity: ${widget.temporaryAct}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Rencana Kegiatan',
          style: subHeaderStyleBold,
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        alignment: Alignment.centerLeft,
        height: double.infinity,
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // List of new activity
              SizedBox(
                width: double.infinity,
                child: widget.temporaryAct.isEmpty
                    ? Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15)),
                        child: Text(
                          "Belum ada rencana kegiatan",
                          style: textStyleBold,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            widget.temporaryAct.length,
                            (index) {
                              final catId = widget.temporaryAct[index].cat;
                              return FutureBuilder<String>(
                                future: catId != null
                                    ? getCategoryData(catId)
                                    : Future.value('Tidak ada'),
                                builder: (context, snapshot) => Row(
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.75,
                                      margin: const EdgeInsets.only(right: 5),
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: getPriorityColor(
                                            widget.temporaryAct[index].impType,
                                            widget.temporaryAct[index].urgType,
                                          ),
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color: const Color.fromARGB(
                                                        255, 3, 0, 66),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 5,
                                                    bottom: 5,
                                                    left: 15,
                                                    right: 15,
                                                  ),
                                                  child: Text(
                                                    formatDate(widget
                                                        .temporaryAct[index]
                                                        .date),
                                                    style: textStyleBoldWhite,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                        icon: const Icon(
                                                            Icons.edit),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  ActivityEditTemporaries(
                                                                activity: widget
                                                                        .temporaryAct[
                                                                    index],
                                                              ),
                                                            ),
                                                          ).then((value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                widget.temporaryAct[
                                                                        index] =
                                                                    value;
                                                              });
                                                            }
                                                          });
                                                        }),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete),
                                                      onPressed: () =>
                                                          removeTempAct(index),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              widget.temporaryAct[index].title,
                                              style: screenTitleStyle,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.only(
                                                  top: 5,
                                                  bottom: 5,
                                                  left: 15,
                                                  right: 15,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: getPriorityColor(
                                                    widget.temporaryAct[index]
                                                        .impType,
                                                    widget.temporaryAct[index]
                                                        .urgType,
                                                  ),
                                                ),
                                                child: Text(
                                                  getPriority(
                                                      widget.temporaryAct[index]
                                                          .impType,
                                                      widget.temporaryAct[index]
                                                          .urgType),
                                                  style: textStyleBold,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _showInfoDialogPriority(
                                                      context);
                                                },
                                                child: const Icon(
                                                  Icons.info,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Start time, end time, priority, total task, category, repeat
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color.fromARGB(
                                                  255,
                                                  3,
                                                  0,
                                                  66), // Change the color with activity color
                                            ),
                                            // Left side and right side
                                            child: Row(
                                              children: [
                                                // Left
                                                Expanded(
                                                  flex: 5,
                                                  child: Column(
                                                    children: [
                                                      // Start time
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                    .blue[100],
                                                              ),
                                                              child: Icon(
                                                                Icons.timer,
                                                                color: Colors
                                                                    .blue[700],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "Waktu mulai",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  widget.temporaryAct[index].strTime !=
                                                                          null
                                                                      ? formattedTimes(widget
                                                                              .temporaryAct[index]
                                                                              .strTime!)
                                                                          .toString()
                                                                      : "Tidak ada",
                                                                  style:
                                                                      textStyleWhite,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Category
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                        .purple[
                                                                    100],
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .category_rounded,
                                                                color: Colors
                                                                        .purple[
                                                                    700],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "Kategori",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  snapshot.data ??
                                                                      'Tunggu...',
                                                                  style:
                                                                      textStyleWhite,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Right
                                                Expanded(
                                                  flex: 5,
                                                  child: Column(
                                                    children: [
                                                      // Duration
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                        .purple[
                                                                    100],
                                                              ),
                                                              child: Icon(
                                                                Icons.timelapse,
                                                                color: Colors
                                                                        .purple[
                                                                    700],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "Durasi",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  "${widget.temporaryAct[index].duration.toString()} menit",
                                                                  style:
                                                                      textStyleWhite,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Total task
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                    .green[100],
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .task_outlined,
                                                                color: Colors
                                                                    .green[700],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "Total tugas",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  "${widget.temporaryAct[index].tasks?.length.toString() ?? 0} tugas",
                                                                  style:
                                                                      textStyleWhite,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Repeat (daily, never, etc)
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                    .blue[100],
                                                              ),
                                                              child: Icon(
                                                                Icons.repeat,
                                                                color: Colors
                                                                    .blue[700],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "Ulangi",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                widget.temporaryAct[index]
                                                                            .rptIntv ==
                                                                        "Tidak"
                                                                    ? Text(
                                                                        widget.temporaryAct[index].rptIntv ??
                                                                            'Tidak',
                                                                        style:
                                                                            textStyleWhite,
                                                                      )
                                                                    : Text(
                                                                        "${widget.temporaryAct[index].rptIntv ?? 'Tidak'} ${widget.temporaryAct[index].rptDur ?? 0}X",
                                                                        style:
                                                                            textStyleWhite,
                                                                      ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Attachment Files - Title
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            width: double.infinity,
                                            child: Text(
                                              "File kegiatan",
                                              style: textStyleBold,
                                            ),
                                          ),
                                          // Attachment Files - Content
                                          SizedBox(
                                            width: double.infinity,
                                            child: widget.temporaryAct[index]
                                                        .files?.isEmpty ??
                                                    true
                                                ? Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 5,
                                                      bottom: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: Text(
                                                      "Tidak ada file yang ditambahkan",
                                                      style: textStyle,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  )
                                                : Column(
                                                    children: (widget
                                                                .temporaryAct[
                                                                    index]
                                                                .files ??
                                                            [])
                                                        .map((file) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          openFile(file.path);
                                                        },
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 5),
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                            color: Colors
                                                                .grey[200],
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Expanded(
                                                                flex: 2,
                                                                child: Icon(
                                                                  Icons
                                                                      .file_present_rounded,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                flex: 7,
                                                                child: Text(
                                                                  file.name,
                                                                  style:
                                                                      textStyle,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                          // Tasks - Title
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            width: double.infinity,
                                            child: Text(
                                              "Sub tugas",
                                              style: textStyleBold,
                                            ),
                                          ),
                                          // Tasks - Content
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                              right: 10,
                                              top: 5,
                                              bottom: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              color: Colors.grey[200],
                                            ),
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .tasks?.isEmpty ??
                                                    true
                                                ? Text(
                                                    "Tidak ada sub tugas yang ditambahkan",
                                                    style: textStyle,
                                                    textAlign: TextAlign.center,
                                                  )
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: (widget
                                                                .temporaryAct[
                                                                    index]
                                                                .tasks ??
                                                            [])
                                                        .map((task) {
                                                      return Text(
                                                        "- ${task.task}",
                                                        style: textStyle,
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                          // Locations - Title
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            width: double.infinity,
                                            child: Text(
                                              "Lokasi",
                                              style: textStyleBold,
                                            ),
                                          ),
                                          // Locations - Content
                                          SizedBox(
                                            width: double.infinity,
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .locations?.isEmpty ??
                                                    true
                                                ? Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 5,
                                                      bottom: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: Text(
                                                      "Tidak ada lokasi yang ditambahkan",
                                                      style: textStyle,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  )
                                                : Column(
                                                    children: (widget
                                                                .temporaryAct[
                                                                    index]
                                                                .locations ??
                                                            [])
                                                        .map((location) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          // Open the address
                                                          openGoogleMaps(
                                                            location.latitude,
                                                            location.longitude,
                                                          );
                                                        },
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 5),
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            top: 5,
                                                            bottom: 5,
                                                            right: 10,
                                                            left: 10,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                            color: Colors
                                                                .grey[200],
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Expanded(
                                                                flex: 1,
                                                                child: Icon(
                                                                    Icons
                                                                        .location_on,
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                flex: 8,
                                                                child: Text(
                                                                  location
                                                                      .address,
                                                                  style:
                                                                      textStyle,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                          // Notifications - Title
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            width: double.infinity,
                                            child: Text(
                                              "Pengingat kegiatan",
                                              style: textStyleBold,
                                            ),
                                          ),
                                          // Notifications - Content
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                              right: 10,
                                              top: 5,
                                              bottom: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              color: Colors.grey[200],
                                            ),
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .notif?.isEmpty ??
                                                    true
                                                ? Text(
                                                    "Tidak ada pengingat waktu yang ditambahkan",
                                                    style: textStyle,
                                                    textAlign: TextAlign.center,
                                                  )
                                                : Column(
                                                    children: (widget
                                                                .temporaryAct[
                                                                    index]
                                                                .notif ??
                                                            [])
                                                        .map((notif) {
                                                      return Text(
                                                        "- Pengingat waktu ${notif.minute} menit",
                                                        style: textStyle,
                                                        textAlign:
                                                            TextAlign.left,
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Checkbox algorithm
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCheckedAlgorithm = !_isCheckedAlgorithm;
                    logger.i("Checkbox algorithm: $_isCheckedAlgorithm");
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _isCheckedAlgorithm,
                      onChanged: (value) {
                        setState(() {
                          _isCheckedAlgorithm = value!;
                        });
                      },
                    ),
                    Text(
                      'Gunakan algoritma rekomendasi jadwal',
                      style: textStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Button AlgorithmSchedule
              GestureDetector(
                onTap: () async {
                  if (_isCheckedAlgorithm == true) {
                    await beneranTestAlgoritma();
                    tabAlgorithm();
                  } else {
                    setToFirestoreWithoutAlogirhtm(context);
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.playlist_add_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Buat Jadwal Kegiatan",
                        style: textStyleBoldWhite,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
