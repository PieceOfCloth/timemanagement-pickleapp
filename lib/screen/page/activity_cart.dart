import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pickleapp/main.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/components/buttonCalmBlue.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:pickleapp/screen/class/addActivityList.dart';
import 'package:pickleapp/screen/page/activity_edit.dart';
import 'package:pickleapp/theme.dart';

class ActivityCart extends StatefulWidget {
  final List<AddActivityList> temporaryAct;

  const ActivityCart({super.key, required this.temporaryAct});

  @override
  State<ActivityCart> createState() => _ActivityCartState();
}

class _ActivityCartState extends State<ActivityCart> {
  bool _isCheckedAlgorithm = false;
  var logger = Logger();

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
            style: subHeaderStyle,
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
  int _intervalToDays(String repeatInterval) {
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

  // Save temporary activities to the firestore database
  void setTemporaryActivitiesToFirestore() async {
    List<Map<String, dynamic>> schedules = [];

    try {
      for (var act in widget.temporaryAct) {
        DocumentReference actID =
            await FirebaseFirestore.instance.collection('activities').add({
          'title': act.title,
          'important_type': act.imp_type,
          'urgent_type': act.urg_type,
          'date': act.date,
          'start_time': act.str_time,
          'duration': act.duration,
          'repeat_interval': act.rpt_intv,
          'repeat_duration': act.rpt_dur ?? 0,
          'timezones': act.timezone,
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
          await FirebaseFirestore.instance.collection('files').add({
            'title': file.name,
            'path': file.path,
            'activities_id': actID.id,
          });
        }

        if (_isCheckedAlgorithm == false) {
          for (var i = 0; i < (act.rpt_dur ?? 1); i++) {
            DateTime startTime = DateFormat("yyyy-MM-dd hh:mm a")
                .parse(act.date + " " + (act.str_time ?? "12:00 AM"));
            tz.Location timezone = tz.getLocation(act.timezone);
            startTime = tz.TZDateTime.from(startTime, timezone)
                .add(Duration(
                    days: i * _intervalToDays(act.rpt_intv ?? "Never")))
                .toUtc();

            DateTime endTime = startTime.add(Duration(minutes: act.duration));

            while (endTime.hour == 23 && endTime.minute > 59) {
              schedules.add({
                'start_time': Timestamp.fromDate(startTime),
                'end_time': Timestamp.fromDate(DateTime(
                    startTime.year, startTime.month, startTime.day, 23, 59)),
                'activity_id': actID.id,
              });

              int remainingMinutes = endTime
                  .difference(
                      DateTime(endTime.year, endTime.month, endTime.day, 0, 0))
                  .inMinutes;

              startTime = DateTime(
                  startTime.year, startTime.month, startTime.day + 1, 0, 0);
              startTime = tz.TZDateTime.from(startTime, timezone).toUtc();

              endTime = startTime.add(Duration(minutes: remainingMinutes));
            }

            schedules.add({
              'start_time': Timestamp.fromDate(startTime),
              'end_time': Timestamp.fromDate(endTime),
              'activity_id': actID.id,
            });
          }
        }

        for (var newSch in schedules) {
          DocumentReference schID = await FirebaseFirestore.instance
              .collection('scheduled_activities')
              .add({
            'actual_start_time': newSch['start_time'],
            'actual_end_time': newSch['end_time'],
            'activities_id': newSch['activity_id'],
          });

          for (Notifications notif in act.notif ?? []) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'minutes_before': notif.minute,
              'shceduled_activities_id': schID.id,
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your activities successfuly scheduled'),
          ),
        );

        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activities Cart',
          style: screenTitleStyle,
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
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          "There is no activity yet",
                          style: textStyle,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            widget.temporaryAct.length,
                            (index) {
                              final catId = widget.temporaryAct[index].cat;
                              return FutureBuilder<String>(
                                future: catId != null
                                    ? getCategoryData(catId)
                                    : Future.value('Unknown'),
                                builder: (context, snapshot) => Row(
                                  children: [
                                    Container(
                                      width: 350,
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: getPriorityColor(
                                            widget.temporaryAct[index].imp_type,
                                            widget.temporaryAct[index].urg_type,
                                          ),
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
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
                                                        255, 166, 204, 255),
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
                                                    style: textStyle,
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
                                                                  ActivityEdits(
                                                                activity: widget
                                                                        .temporaryAct[
                                                                    index],
                                                                userID: widget
                                                                    .temporaryAct[
                                                                        index]
                                                                    .userID,
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
                                            child: Expanded(
                                              child: Text(
                                                widget
                                                    .temporaryAct[index].title,
                                                style: headerStyle,
                                              ),
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
                                                        .imp_type,
                                                    widget.temporaryAct[index]
                                                        .urg_type,
                                                  ),
                                                ),
                                                child: Text(
                                                  getPriority(
                                                      widget.temporaryAct[index]
                                                          .imp_type,
                                                      widget.temporaryAct[index]
                                                          .urg_type),
                                                  style: textStyle,
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
                                              color: Colors.grey[
                                                  200], // Change the color with activity color
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
                                                                Icons
                                                                    .calendar_today_rounded,
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
                                                                  "Start time",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  widget.temporaryAct[index]
                                                                          .str_time ??
                                                                      'Unknown',
                                                                  style:
                                                                      textStyle,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Timezone
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
                                                                    .category_rounded,
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
                                                                  "Timezone",
                                                                  style:
                                                                      textStyleGrey,
                                                                ),
                                                                Text(
                                                                  widget
                                                                      .temporaryAct[
                                                                          index]
                                                                      .timezone,
                                                                  style:
                                                                      textStyle,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
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
                                                                      textStyle,
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
                                                                Icons
                                                                    .calendar_today_rounded,
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
                                                                      textStyle,
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
                                                                      textStyle,
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
                                                                  "${widget.temporaryAct[index].rpt_intv ?? 'Never'} ${widget.temporaryAct[index].rpt_dur ?? 0}X",
                                                                  style:
                                                                      textStyle,
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
                                              style: subHeaderStyle,
                                            ),
                                          ),
                                          // Attachment Files - Content
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                            ),
                                            alignment: Alignment.topLeft,
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .files?.isEmpty ??
                                                    true
                                                ? const Text(
                                                    "There are no files added")
                                                : Column(
                                                    children: (widget
                                                                .temporaryAct[
                                                                    index]
                                                                .files ??
                                                            [])
                                                        .map((file) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          // Open the file
                                                          OpenFile.open(
                                                              file.path);
                                                        },
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              width: double
                                                                  .infinity,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                    .grey[200],
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          10),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(10),
                                                                        color: Colors
                                                                            .purple[100],
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .file_present_rounded,
                                                                        color: Colors
                                                                            .purple[700],
                                                                      ),
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
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                          ],
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
                                              style: subHeaderStyle,
                                            ),
                                          ),
                                          // Tasks - Content
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                            ),
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .tasks?.isEmpty ??
                                                    true
                                                ? const Text(
                                                    "There are no tasks added")
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
                                                          style: textStyle);
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
                                              style: headerStyle,
                                            ),
                                          ),
                                          // Locations - Content
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                            ),
                                            alignment: Alignment.topLeft,
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .locations?.isEmpty ??
                                                    true
                                                ? const Text(
                                                    "There are no locations added")
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
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              width: double
                                                                  .infinity,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                    .grey[200],
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          10),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(10),
                                                                        color: Colors
                                                                            .blue[100],
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .location_on_outlined,
                                                                        color: Colors
                                                                            .blue[700],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 5,
                                                                  ),
                                                                  Expanded(
                                                                    flex: 7,
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
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                          ],
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
                                              style: subHeaderStyle,
                                            ),
                                          ),
                                          // Notifications - Content
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                            ),
                                            alignment: Alignment.topLeft,
                                            //Listbuilder bellow
                                            child: widget.temporaryAct[index]
                                                        .notif?.isEmpty ??
                                                    true
                                                ? const Text(
                                                    "There are no reminder added")
                                                : Column(
                                                    children: (widget
                                                                .temporaryAct[
                                                                    index]
                                                                .notif ??
                                                            [])
                                                        .map((notif) {
                                                      return Text(
                                                        "- Set reminder ${notif.minute} minutes before",
                                                        style: textStyle,
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
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
                      onChanged: (bool? value) {
                        setState(() {
                          _isCheckedAlgorithm = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text('Set activity schedules using algorithms',
                          style: textStyle),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Button Schedule
              MyButtonCalmBlue(
                label: "Schedule",
                onTap: () {
                  setTemporaryActivitiesToFirestore();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
