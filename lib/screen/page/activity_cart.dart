// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/algorithm_schedule.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:provider/provider.dart';
// import 'package:pickleapp/screen/page/home.dart';
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

  List<AlgorithmSchedule> scheduleList = [];
  List<AlgorithmSchedule> scheduleList2 = [];
  List<AddActivityList> temporaryActiv = [];
  List<AddActivityList> processedListWithStart = [];
  List<AddActivityList> processedListWithoutStart = [];
  List<AddActivityList> remainingList = [];
  Map<String, List<AlgorithmSchedule>> groupedSchedule = {};

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // For determine priority high medium or so on
  String getPriority(important, urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return "Golf (Critical Priority)";
    } else if (important == "Important" && urgent == "Not Urgent") {
      return "Pebble (High Priority)";
    } else if (important == "Not Important" && urgent == "Urgent") {
      return "Sand (Medium Priority)";
    } else {
      return "Water (Low Priority)";
    }
  }

  // For determine priority high medium or so on
  int getPriorityRank(String important, String urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return 4;
    } else if (important == "Important" && urgent == "Not Urgent") {
      return 3;
    } else if (important == "Not Important" && urgent == "Urgent") {
      return 2;
    } else {
      return 1;
    }
  }

  // Get priority color based on important und urgent level
  Color getPriorityColor(important, urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return Colors.red[600] ?? Colors.red;
    } else if (important == "Important" && urgent == "Not Urgent") {
      return Colors.yellow[600] ?? Colors.yellow;
    } else if (important == "Not Important" && urgent == "Urgent") {
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
            "Importance and Urgency Info",
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
                "Close",
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
    DateFormat formatter = DateFormat.yMMMMd(); // "March 24, 2024"
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
      throw 'Could not launch $url';
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
        .collection('categories')
        .doc(catID)
        .get();

    if (data.exists) {
      return data['title'];
    } else {
      return 'Unknown';
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Function to convert repeat interval to days
  int intervalToDays(String repeatInterval) {
    switch (repeatInterval) {
      case 'Daily':
        return 1;
      case 'Weekly':
        return 7;
      case 'Monthly':
        return 30;
      default:
        return 1;
    }
  }

  Future<void> beneranTestAlgoritma() async {
    var groupDate =
        groupBy(widget.temporaryAct, (AddActivityList activ) => activ.date);

    for (var data in groupDate.entries) {
      var aktivitas = data.value;

      setState(() {
        scheduleList.clear();
        processedListWithStart.clear();
        processedListWithoutStart.clear();
        remainingList.clear();
        temporaryActiv.clear();

        for (var s in aktivitas) {
          temporaryActiv.add(AddActivityList(
            userID: userID,
            title: s.title,
            impType: s.impType,
            urgType: s.urgType,
            date: s.date,
            strTime: s.strTime,
            duration: s.duration,
          ));
        }

        processedListWithStart =
            temporaryActiv.where((element) => element.strTime != null).toList();
        processedListWithoutStart =
            temporaryActiv.where((element) => element.strTime == null).toList();

        print(processedListWithStart);
        print(processedListWithoutStart);

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
    AlgorithmSchedule? currentSchedule;

    remainingList.addAll(processedListWithoutStart);

    processedListWithStart.sort((a, b) =>
        formattedActivityTimeOnly(a.strTime ?? "")
            .compareTo(formattedActivityTimeOnly(b.strTime ?? "")));

    DateTime date =
        DateFormat("yyyy-MM-dd").parse(processedListWithStart.first.date);

    DateTime currentTime = processedListWithStart.isNotEmpty
        ? DateTime(
            date.year,
            date.month,
            date.day,
            formattedActivityTimeOnly(
                    processedListWithStart.first.strTime ?? "")
                .hour,
            formattedActivityTimeOnly(
                    processedListWithStart.first.strTime ?? "")
                .minute,
          )
        : DateTime(
            date.year,
            date.month,
            date.day,
            formattedActivityTimeOnly(startInput).hour,
            formattedActivityTimeOnly(startInput).minute,
          );

    while (processedListWithStart.isNotEmpty) {
      AddActivityList currentActivity = processedListWithStart.removeAt(0);

      DateTime date2 = DateFormat("yyyy-MM-dd").parse(currentActivity.date);
      DateTime currentStartAct = DateTime(
        date2.year,
        date2.month,
        date2.day,
        formattedActivityTimeOnly(
                currentActivity.strTime ?? currentTime.toString())
            .hour,
        formattedActivityTimeOnly(
                currentActivity.strTime ?? currentTime.toString())
            .minute,
      );

      DateTime? processedStartAct;
      if (processedListWithStart.isNotEmpty) {
        DateTime date3 =
            DateFormat("yyyy-MM-dd").parse(processedListWithStart.first.date);
        processedStartAct = DateTime(
          date3.year,
          date3.month,
          date3.day,
          formattedActivityTimeOnly(processedListWithStart.first.strTime ??
                  currentTime.toString())
              .hour,
          formattedActivityTimeOnly(processedListWithStart.first.strTime ??
                  currentTime.toString())
              .minute,
        );
      }
      if (currentTime.isBefore(currentStartAct) ||
          currentTime.isAtSameMomentAs(currentStartAct)) {
        while (currentActivity.duration > 0) {
          if (processedListWithStart.isNotEmpty &&
              processedStartAct != null &&
              (processedStartAct
                      .isBefore(currentTime.add(const Duration(minutes: 1))) ||
                  processedStartAct.isAtSameMomentAs(
                      currentTime.add(const Duration(minutes: 1))))) {
            AddActivityList nextActivity = processedListWithStart.first;

            if (getPriorityRank(nextActivity.impType!, nextActivity.urgType!) >
                getPriorityRank(
                    currentActivity.impType!, currentActivity.urgType!)) {
              scheduleList.add(AlgorithmSchedule(
                title: currentActivity.title,
                impt: currentActivity.impType ?? "",
                urgnt: currentActivity.urgType ?? "",
                start: currentTime,
                date: DateFormat('yyyy-MM-dd').format(currentTime),
                end: currentTime.add(const Duration(minutes: 1)),
              ));
              remainingList.add(AddActivityList(
                userID: userID,
                title: currentActivity.title,
                impType: currentActivity.impType,
                urgType: currentActivity.urgType,
                date: DateFormat('yyyy-MM-dd').format(currentTime),
                duration: currentActivity.duration - 1,
              ));
              currentTime = currentTime.add(const Duration(minutes: 1));
              break;
            } else {
              currentActivity.duration -= 1;
              scheduleList.add(AlgorithmSchedule(
                  title: currentActivity.title,
                  impt: currentActivity.impType ?? "",
                  urgnt: currentActivity.urgType ?? "",
                  date: DateFormat('yyyy-MM-dd').format(currentTime),
                  start: currentTime,
                  end: currentTime.add(const Duration(minutes: 1))));
              currentTime = currentTime.add(const Duration(minutes: 1));
            }
          } else {
            currentActivity.duration -= 1;
            scheduleList.add(AlgorithmSchedule(
                impt: currentActivity.impType ?? "",
                urgnt: currentActivity.urgType ?? "",
                title: currentActivity.title,
                date: DateFormat('yyyy-MM-dd').format(currentTime),
                start: currentTime,
                end: currentTime.add(const Duration(minutes: 1))));
            currentTime = currentTime.add(const Duration(minutes: 1));
          }
        }
      } else {
        remainingList.add(AddActivityList(
          userID: userID,
          title: currentActivity.title,
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
        scheduleList.add(AlgorithmSchedule(
            title: currentActivity.title,
            impt: currentActivity.impType ?? "",
            urgnt: currentActivity.urgType ?? "",
            date: DateFormat('yyyy-MM-dd').format(currentTime),
            start: currentTime,
            end: currentTime.add(const Duration(minutes: 1))));
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
            currentSchedule.end == schedule.start) {
          currentSchedule = AlgorithmSchedule(
            title: currentSchedule.title,
            start: currentSchedule.start,
            impt: currentSchedule.impt,
            urgnt: currentSchedule.urgnt,
            end: schedule.end,
            date: currentSchedule.date,
          );
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

  Future<void> setToFirestoreWithAlgorithm() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      for (var act in widget.temporaryAct) {
        DocumentReference actID =
            await FirebaseFirestore.instance.collection('activities').add({
          'title': act.title,
          'important_type': act.impType,
          'urgent_type': act.urgType,
          'date': act.date,
          'start_time': act.strTime,
          'duration': act.duration,
          'repeat_interval': act.rptIntv,
          'repeat_duration': act.rptDur ?? 0,
          'categories_id': act.cat ?? "",
          'user_id': act.userID,
        });

        for (Locations loc in act.locations ?? []) {
          await FirebaseFirestore.instance.collection('locations').add({
            'address': loc.address,
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'activities_id': actID.id,
          });
        }

        for (Tasks task in act.tasks ?? []) {
          await FirebaseFirestore.instance.collection('tasks').add({
            'title': task.task,
            'status': task.status,
            'activities_id': actID.id,
          });
        }

        for (Files file in act.files ?? []) {
          String folder = "user_files/$userID/${actID.id}";
          String filePath = "$folder/${file.name}";
          await FirebaseFirestore.instance.collection('files').add({
            'title': file.name,
            'path': "$folder/${file.name}",
            'activities_id': actID.id,
          });
          await FirebaseStorage.instance.ref(filePath).putFile(File(file.path));
        }

        for (var sch in scheduleList2) {
          if (act.title == sch.title &&
              act.urgType == sch.urgnt &&
              act.impType == sch.impt) {
            for (var i = 0; i < (act.rptDur ?? 1); i++) {
              DateTime startTime = DateFormat("yyyy-MM-dd hh:mm a")
                  .parse("${sch.date} ${formattedTimes(sch.start)}");
              DateTime endTime = DateFormat("yyyy-MM-dd hh:mm a")
                  .parse("${sch.date} ${formattedTimes(sch.end)}");
              DateTime startTimeReal;
              DateTime endTimeReal;
              if (act.rptIntv == "Daily") {
                startTimeReal = startTime.add(Duration(days: i));
                endTimeReal = endTime.add(Duration(days: i));
              } else if (act.rptIntv == "Weekly") {
                startTimeReal = startTime.add(Duration(days: 7 * i));
                endTimeReal = endTime.add(Duration(days: 7 * i));
              } else if (act.rptIntv == "Monthly") {
                startTimeReal = startTime.add(Duration(days: 30 * i));
                endTimeReal = endTime.add(Duration(days: 7 * i));
              } else if (act.rptIntv == "Yearly") {
                startTimeReal = startTime.add(Duration(days: 365 * i));
                endTimeReal = endTime.add(Duration(days: 7 * i));
              } else {
                startTimeReal = startTime;
                endTimeReal = endTime;
              }

              DocumentReference schID = await FirebaseFirestore.instance
                  .collection('scheduled_activities')
                  .add({
                'actual_start_time': Timestamp.fromDate(startTimeReal),
                'actual_end_time': Timestamp.fromDate(endTimeReal),
                'activities_id': actID.id,
              });
              for (Notifications notif in act.notif ?? []) {
                DocumentReference notifRef = await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                  'minutes_before': notif.minute,
                  'scheduled_activities_id': schID.id,
                });

                DateTime notifTime =
                    startTimeReal.subtract(Duration(minutes: notif.minute));

                await AwesomeNotifications().createNotification(
                  content: NotificationContent(
                    id: notifRef.id.hashCode,
                    channelKey: 'activity_reminder',
                    title: "Upcoming Activity - ${act.title}",
                    body:
                        "You have an activity starting soon at $startTimeReal",
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
            }
          }
        }
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
          context: context,
          title: "Successfully Scheduled",
          message: "All of your activities successfully scheduled.");
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
          showInfoDialog("Can't Schedule",
              "If you are NOT USING the schedule RECOMMENDATION FEATURE, please ensure  all activities have a start time.");
          return;
        }
      }

      for (var act in widget.temporaryAct) {
        DocumentReference actID =
            await FirebaseFirestore.instance.collection('activities').add({
          'title': act.title,
          'important_type': act.impType,
          'urgent_type': act.urgType,
          'date': act.date,
          'start_time': act.strTime,
          'duration': act.duration,
          'repeat_interval': act.rptIntv,
          'repeat_duration': act.rptDur ?? 0,
          'categories_id': act.cat ?? "",
          'user_id': act.userID,
        });

        for (Locations loc in act.locations ?? []) {
          await FirebaseFirestore.instance.collection('locations').add({
            'address': loc.address,
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'activities_id': actID.id,
          });
        }

        for (Tasks task in act.tasks ?? []) {
          await FirebaseFirestore.instance.collection('tasks').add({
            'title': task.task,
            'status': task.status,
            'activities_id': actID.id,
          });
        }

        for (Files file in act.files ?? []) {
          String folder = "user_files/$userID/${actID.id}";
          String filePath = "$folder/${file.name}";
          await FirebaseFirestore.instance.collection('files').add({
            'title': file.name,
            'path': "$folder/${file.name}",
            'activities_id': actID.id,
          });
          await FirebaseStorage.instance.ref(filePath).putFile(File(file.path));
        }

        for (var i = 0; i < (act.rptDur ?? 1); i++) {
          DateTime startTime = DateFormat("yyyy-MM-dd hh:mm a")
              .parse("${act.date} ${act.strTime ?? '12:00 AM'}");
          DateTime startTimeReal;
          if (act.rptIntv == "Daily") {
            startTimeReal = startTime.add(Duration(days: i));
          } else if (act.rptIntv == "Weekly") {
            startTimeReal = startTime.add(Duration(days: 7 * i));
          } else if (act.rptIntv == "Monthly") {
            startTimeReal = startTime.add(Duration(days: 30 * i));
          } else if (act.rptIntv == "Yearly") {
            startTimeReal = startTime.add(Duration(days: 365 * i));
          } else {
            startTimeReal = startTime;
          }

          DateTime endTime = startTimeReal.add(Duration(minutes: act.duration));

          while (endTime.isAfter(DateTime(startTimeReal.year,
              startTimeReal.month, startTimeReal.day, 23, 59))) {
            DateTime endOfDay = DateTime(startTimeReal.year,
                startTimeReal.month, startTimeReal.day, 23, 59);
            int remainingMinutes = endTime.difference(endOfDay).inMinutes;

            DocumentReference schID = await FirebaseFirestore.instance
                .collection('scheduled_activities')
                .add({
              'actual_start_time': Timestamp.fromDate(startTimeReal),
              'actual_end_time': Timestamp.fromDate(endOfDay),
              'activities_id': actID.id,
            });

            for (Notifications notif in act.notif ?? []) {
              DocumentReference notify = await FirebaseFirestore.instance
                  .collection('notifications')
                  .add({
                'minutes_before': notif.minute,
                'scheduled_activities_id': schID.id,
              });

              DateTime notiftime =
                  startTimeReal.subtract(Duration(minutes: notif.minute));

              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: notify.id.hashCode,
                  channelKey: 'activity_reminder',
                  title: "Upcoming Activity - ${act.title}",
                  body: "You have an activity starting soon at $startTime",
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

            startTimeReal = DateTime(startTimeReal.year, startTimeReal.month,
                startTimeReal.day + 1, 0, 0);
            endTime = startTimeReal.add(Duration(minutes: remainingMinutes));
          }
          DocumentReference schID = await FirebaseFirestore.instance
              .collection('scheduled_activities')
              .add({
            'actual_start_time': Timestamp.fromDate(startTimeReal),
            'actual_end_time': Timestamp.fromDate(endTime),
            'activities_id': actID.id,
          });
          for (Notifications notif in act.notif ?? []) {
            DocumentReference notifRef = await FirebaseFirestore.instance
                .collection('notifications')
                .add({
              'minutes_before': notif.minute,
              'scheduled_activities_id': schID.id,
            });

            DateTime notifTime =
                startTimeReal.subtract(Duration(minutes: notif.minute));

            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: notifRef.id.hashCode,
                channelKey: 'activity_reminder',
                title: "Upcoming Activity - ${act.title}",
                body: "You have an activity starting soon at $startTimeReal",
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
        }
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
        context: context,
        title: "Successfully Scheduled",
        message: "All of your activities successfully scheduled.",
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

  void showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctxt) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: subHeaderStyleBold,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(ctxt).pop();
                },
              ),
            ],
          ),
          content: Text(
            message,
            style: textStyle,
          ),
        );
      },
    );
  }

  void tabAlgorithm() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Recommended Schedule", style: subHeaderStyleBold),
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
                            "Before",
                            style: textStyleBold,
                          ),
                        ),
                        Tab(
                          child: Text(
                            "After",
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
                    'Schedule it',
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
                    remainingList.clear();
                    temporaryActiv.clear();
                    groupedSchedule.clear();
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
                    'Cancel',
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
                          "Not Decided",
                          style: textStyle,
                        )
                      : Text(
                          "${act.strTime ?? 0} - ${formattedActivityEndTimeOnly(act.strTime ?? "", act.duration)}",
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
        AlgorithmSchedule sch = scheduleList2[index];
        return Container(
          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: 10,
            top: 10,
          ),
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: getPriorityColor(sch.impt, sch.urgnt),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sch.title,
                      style: subHeaderStyleBold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     IconButton(
                  //       icon: const Icon(
                  //         Icons.edit,
                  //         color: Colors.black,
                  //       ),
                  //       onPressed: () {
                  //         editSchedule(index);
                  //       },
                  //     ),
                  //     IconButton(
                  //       icon: const Icon(
                  //         Icons.delete,
                  //         color: Colors.black,
                  //       ),
                  //       onPressed: () {
                  //         setState(() {
                  //           deleteSchedule(index);
                  //         });
                  //       },
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              Text(
                sch.date,
                style: textStyleBold,
              ),
              Text(
                "${formattedTimes(sch.start)} - ${formattedTimes(sch.end)}",
                style: textStyleBold,
              ),
            ],
          ),
        );
      },
    );
  }

  // void deleteSchedule(int index) {
  //   setState(() {
  //     scheduleList2.removeAt(index);
  //   });
  // }

  // void editSchedule(int index) {
  //   final schedule = scheduleList2[index];
  //   final startController =
  //       TextEditingController(text: formattedTimes(schedule.start));
  //   final endController =
  //       TextEditingController(text: formattedTimes(schedule.end));

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Edit Schedule'),
  //         content: Form(
  //           key: _formKey,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               GestureDetector(
  //                 onTap: () {
  //                   showTimePicker(
  //                     context: context,
  //                     initialTime: TimeOfDay.now(),
  //                   ).then((selectedTime) {
  //                     if (selectedTime != null) {
  //                       setState(() {
  //                         // Convert selectedTime to AM/PM format
  //                         String period =
  //                             selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
  //                         // Extract hours and minutes
  //                         int hours = selectedTime.hourOfPeriod;
  //                         int minutes = selectedTime.minute;
  //                         // Format the time as a string
  //                         String formattedTime =
  //                             '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
  //                         // Update the text field with the selected time
  //                         startController.text = formattedTime;

  //                         print(startController.text);
  //                       });
  //                     }
  //                   });
  //                 },
  //                 child: Container(
  //                   padding: const EdgeInsets.only(
  //                     left: 10,
  //                     right: 10,
  //                   ),
  //                   alignment: Alignment.centerLeft,
  //                   height: 50,
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                     border: Border.all(
  //                       color: Colors.grey,
  //                       width: 1.0,
  //                     ),
  //                     borderRadius: BorderRadius.circular(15),
  //                   ),
  //                   child: Row(
  //                     children: [
  //                       Expanded(
  //                         flex: 6,
  //                         child: TextFormField(
  //                           autofocus: false,
  //                           readOnly: true,
  //                           keyboardType: TextInputType.text,
  //                           textCapitalization: TextCapitalization.sentences,
  //                           decoration: InputDecoration(
  //                             hintText: "When do you want to start?",
  //                             hintStyle: textStyleGrey,
  //                           ),
  //                           validator: (v) {
  //                             if (v == null || v.isEmpty) {
  //                               return 'Opps, You need to fill this';
  //                             } else {
  //                               return null;
  //                             }
  //                           },
  //                           controller: startController,
  //                         ),
  //                       ),
  //                       const SizedBox(
  //                         width: 5,
  //                       ),
  //                       const Expanded(
  //                         flex: 2,
  //                         child: Icon(
  //                           Icons.access_time,
  //                           color: Colors.grey,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               GestureDetector(
  //                 onTap: () {
  //                   showTimePicker(
  //                     context: context,
  //                     initialTime: TimeOfDay.now(),
  //                   ).then((selectedTime) {
  //                     if (selectedTime != null) {
  //                       setState(() {
  //                         // Convert selectedTime to AM/PM format
  //                         String period =
  //                             selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
  //                         // Extract hours and minutes
  //                         int hours = selectedTime.hourOfPeriod;
  //                         int minutes = selectedTime.minute;
  //                         // Format the time as a string
  //                         String formattedTime =
  //                             '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
  //                         // Update the text field with the selected time
  //                         endController.text = formattedTime;

  //                         print(endController.text);
  //                       });
  //                     }
  //                   });
  //                 },
  //                 child: Container(
  //                   padding: const EdgeInsets.only(
  //                     left: 10,
  //                     right: 10,
  //                   ),
  //                   alignment: Alignment.centerLeft,
  //                   height: 50,
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                     border: Border.all(
  //                       color: Colors.grey,
  //                       width: 1.0,
  //                     ),
  //                     borderRadius: BorderRadius.circular(15),
  //                   ),
  //                   child: Row(
  //                     children: [
  //                       Expanded(
  //                         flex: 6,
  //                         child: TextFormField(
  //                           autofocus: false,
  //                           readOnly: true,
  //                           keyboardType: TextInputType.text,
  //                           textCapitalization: TextCapitalization.sentences,
  //                           decoration: InputDecoration(
  //                             hintText: "When do you want to end?",
  //                             hintStyle: textStyleGrey,
  //                           ),
  //                           validator: (v) {
  //                             if (v == null || v.isEmpty) {
  //                               return 'Opps, You need to fill this';
  //                             } else {
  //                               return null;
  //                             }
  //                           },
  //                           controller: endController,
  //                         ),
  //                       ),
  //                       const SizedBox(
  //                         width: 5,
  //                       ),
  //                       const Expanded(
  //                         flex: 2,
  //                         child: Icon(
  //                           Icons.access_time,
  //                           color: Colors.grey,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               if (_formKey.currentState != null &&
  //                   !_formKey.currentState!.validate()) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(
  //                     content: Text("Kindly complete all mandatory fields."),
  //                   ),
  //                 );
  //                 FocusScope.of(context).unfocus();
  //               } else {
  //                 setState(() {
  //                   scheduleList2[index] = AlgorithmSchedule(
  //                     title: schedule.title,
  //                     start: DateFormat('hh:mm a').parse(startController.text),
  //                     end: DateFormat('hh:mm a').parse(endController.text),
  //                     date: schedule.date,
  //                     impt: schedule.impt,
  //                     urgnt: schedule.urgnt,
  //                   );
  //                   scheduleAfter();
  //                 });
  //                 Navigator.of(context).pop();
  //               }
  //             },
  //             child: Text('Save'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
          'Activities Cart',
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
                          "There is no activity yet",
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
                                    : Future.value('Not Decided'),
                                builder: (context, snapshot) => Row(
                                  children: [
                                    Container(
                                      width: 350,
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
                                                                  "Start",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  widget.temporaryAct[index]
                                                                          .strTime ??
                                                                      'Not Decided',
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
                                                                  "Category",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  snapshot.data ??
                                                                      'Wait...',
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
                                                                  "Duration",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  "${widget.temporaryAct[index].duration.toString()} minutes",
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
                                                                  "Total task",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  "${widget.temporaryAct[index].tasks?.length.toString() ?? 0} Tasks",
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
                                                                  "Repeat",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  "${widget.temporaryAct[index].rptIntv ?? 'Never'} ${widget.temporaryAct[index].rptDur ?? 0}X",
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
                                              "Attachment Files",
                                              style: textStyleBold,
                                            ),
                                          ),
                                          // Attachment Files - Content
                                          SizedBox(
                                            width: double.infinity,
                                            //Listbuilder bellow
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
                                                      "There are no files added",
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
                                              "Tasks",
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
                                                    "There are no tasks added",
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
                                              "Locations",
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
                                                      "There are no locations added",
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
                                              "Notifications",
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
                                                    "There are no reminder added",
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
                                                        "- Set a reminder ${notif.minute} minutes before",
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
                      'Set activity schedules using algorithms',
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
                        "Make a Schedule",
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
