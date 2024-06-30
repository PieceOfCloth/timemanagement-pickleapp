// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/page/activity_edit_detail.dart';
import 'package:pickleapp/theme.dart';
import 'package:intl/intl.dart';

import 'package:pickleapp/screen/class/activity_detail.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailActivity extends StatefulWidget {
  final String scheduledID;
  const DetailActivity({super.key, required this.scheduledID});

  @override
  State<DetailActivity> createState() => _DetailActivityState();
}

class _DetailActivityState extends State<DetailActivity> {
  late Future<DetailActivities?> detailAct;
  Color? colorTheme;

  /* ------------------------------------------------------------------------------------------------------------------- */

  // Get Priority from important n urgent
  String formattedPriority(String impt, String urgt) {
    if (impt == "Important" && urgt == "Urgent") {
      return "Critical";
    } else if (impt == "Important" && urgt == "Not Urgent") {
      return "High";
    } else if (impt == "Not Important" && urgt == "Urgent") {
      return "Medium";
    } else {
      return "Low";
    }
  }

  Color getPriorityColor(String important, String urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return Colors.red;
    } else if (important == "Important" && urgent == "Not Urgent") {
      return Colors.yellow;
    } else if (important == "Not Important" && urgent == "Urgent") {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  // Image for priority type to use it in containers
  String getPriorityImage(important, urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return 'assets/golfBall_1.png';
    } else if (important == "Important" && urgent == "Not Urgent") {
      return 'assets/pebbles_1.png';
    } else if (important == "Not Important" && urgent == "Urgent") {
      return 'assets/sand_1.png';
    } else {
      return 'assets/water_1.png';
    }
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(String inptTime) {
    DateTime time = DateTime.parse(inptTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityDateOnly(String inptTime) {
    DateTime time = DateTime.parse(inptTime);

    String formattedTime = DateFormat("dd MMM yyyy").format(time);

    return formattedTime;
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Future<DetailActivities?> getDetailActivity(String id) async {
    try {
      final schDoc = await FirebaseFirestore.instance
          .collection('scheduled_activities')
          .doc(id)
          .get();

      if (schDoc.exists) {
        final actID = schDoc['activities_id'];

        Timestamp startTime = schDoc['actual_start_time'];
        DateTime dateTimeStr = startTime.toDate();
        String strTime = dateTimeStr.toString();

        Timestamp endTime = schDoc['actual_end_time'];
        DateTime dateTimeEnd = endTime.toDate();
        String endTimes = dateTimeEnd.toString();

        final actDoc = await FirebaseFirestore.instance
            .collection('activities')
            .doc(actID)
            .get();

        String catID = actDoc['categories_id'];

        DocumentSnapshot? catDoc;
        if (catID.isNotEmpty) {
          catDoc = await FirebaseFirestore.instance
              .collection('categories')
              .doc(catID)
              .get();
        }

        final fileQuery = await FirebaseFirestore.instance
            .collection('files')
            .where('activities_id', isEqualTo: actID)
            .get();
        List<Files> files = [];
        if (fileQuery.docs.isNotEmpty) {
          for (var doc in fileQuery.docs) {
            files.add(Files(
              name: doc['title'],
              path: doc['path'],
            ));
          }
        }

        QuerySnapshot locQuery = await FirebaseFirestore.instance
            .collection('locations')
            .where('activities_id', isEqualTo: actID)
            .get();
        List<Locations> locs = [];
        for (var doc in locQuery.docs) {
          locs.add(Locations(
            address: doc['address'],
            latitude: doc['latitude'],
            longitude: doc['longitude'],
          ));
        }

        QuerySnapshot notifQuery = await FirebaseFirestore.instance
            .collection('notifications')
            .where('scheduled_activities_id', isEqualTo: id)
            .get();
        List<Notifications>? notifs = [];
        for (var doc in notifQuery.docs) {
          notifs.add(Notifications(
            minute: doc['minutes_before'],
          ));
        }

        final taskQuery = await FirebaseFirestore.instance
            .collection('tasks')
            .where('activities_id', isEqualTo: actID)
            .get();
        List<Tasks> tasks = [];
        for (var doc in taskQuery.docs) {
          tasks.add(Tasks(task: doc['title'], status: doc['status']));
        }

        return DetailActivities(
          idAct: schDoc['activities_id'],
          idSch: id,
          title: actDoc['title'],
          impType: actDoc['important_type'],
          urgType: actDoc['urgent_type'],
          rptFreq: actDoc['repeat_interval'],
          rptDur: actDoc['repeat_duration'],
          catName: catDoc == null ? "" : catDoc['title'],
          idCat: catID == "" ? null : catID,
          clrA: catDoc == null ? null : catDoc['color_a'],
          clrR: catDoc == null ? null : catDoc['color_r'],
          clrG: catDoc == null ? null : catDoc['color_g'],
          clrB: catDoc == null ? null : catDoc['color_b'],
          strTime: strTime,
          endTime: endTimes,
          tasks: tasks,
          files: files,
          locations: locs,
          notif: notifs,
        );
      }
      return null;
    } catch (e) {
      print("Error di getDetailActivity: $e");
    }
    return null;
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  void openFile(String path) {
    OpenFile.open(path);
  }

  Future<void> fileDownloadOpen(String path, String name) async {
    try {
      String url = await FirebaseStorage.instance.ref(path).getDownloadURL();

      // Download the file to a local path
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$name');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await tempFile.create();
      final http.Client httpClient = http.Client();
      final http.Response response = await httpClient.get(Uri.parse(url));
      await tempFile.writeAsBytes(response.bodyBytes);

      // Open the file
      await OpenFile.open(tempFile.path);
    } catch (e) {
      print(e);
    }
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Future<void> deleteScheduledActivity(
      String scheduleID, String activityID) async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('scheduled_activities')
        .where('activities_id', isEqualTo: activityID)
        .get();

    int count = querySnapshot.docs.length;

    DocumentReference schedRef = FirebaseFirestore.instance
        .collection('scheduled_activities')
        .doc(scheduleID);

    DocumentReference actRef =
        FirebaseFirestore.instance.collection('activities').doc(activityID);

    DocumentSnapshot schedSnap = await schedRef.get();

    if (schedSnap.exists && schedSnap['activities_id'] == activityID) {
      if (count == 1) {
        await actRef.delete();
        await schedRef.delete();

        QuerySnapshot taskSnap = await FirebaseFirestore.instance
            .collection('tasks')
            .where('activities_id', isEqualTo: activityID)
            .get();

        for (DocumentSnapshot doc in taskSnap.docs) {
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(doc.id)
              .delete();
        }

        QuerySnapshot notifSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('scheduled_activities_id', isEqualTo: scheduleID)
            .get();

        for (DocumentSnapshot doc in notifSnap.docs) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .delete();
        }

        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where('activities_id', isEqualTo: activityID)
            .get();

        for (DocumentSnapshot doc in logSnap.docs) {
          await FirebaseFirestore.instance
              .collection('logs')
              .doc(doc.id)
              .delete();
        }

        QuerySnapshot locSnap = await FirebaseFirestore.instance
            .collection('locations')
            .where('activities_id', isEqualTo: activityID)
            .get();

        for (DocumentSnapshot doc in locSnap.docs) {
          await FirebaseFirestore.instance
              .collection('locations')
              .doc(doc.id)
              .delete();
        }

        QuerySnapshot fileSnap = await FirebaseFirestore.instance
            .collection('files')
            .where('activities_id', isEqualTo: activityID)
            .get();

        for (DocumentSnapshot doc in fileSnap.docs) {
          await FirebaseStorage.instance.ref(doc['path']).delete();

          await FirebaseFirestore.instance
              .collection('files')
              .doc(doc.id)
              .delete();
        }

        ListResult listFile = await FirebaseStorage.instance
            .ref("user_files/$activityID")
            .listAll();

        for (Reference file in listFile.items) {
          await file.delete();
        }
      } else {
        QuerySnapshot notifSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('scheduled_activities_id', isEqualTo: scheduleID)
            .get();

        for (DocumentSnapshot doc in notifSnap.docs) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .delete();

          await AwesomeNotifications().cancel(doc.id.hashCode);
        }

        await schedRef.delete();
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
        context: context,
        title: "Deleted Successfully",
        message: "The schedule has been successfully deleted",
      );
    } else {
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
        context: context,
        title: "Unsuccessfully Deleted",
        message: "Document not found or activities_id does not match",
      );
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    setState(() {
      detailAct = getDetailActivity(widget.scheduledID);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 66),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 3, 0, 66),
        title: Text(
          'Detail Activity',
          style: subHeaderStyleBoldWhite,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<DetailActivities?>(
        future: detailAct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No Detail Found',
                style: textStyleBoldWhite,
              ),
            );
          } else {
            DetailActivities detail = snapshot.data!;
            colorTheme = getPriorityColor(detail.impType, detail.urgType);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Title activity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        getPriorityImage(detail.impType, detail.urgType),
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.width * 0.1,
                      ),
                      Text(
                        detail.title,
                        style: screenTitleStyleWhite,
                      ),
                      Text(
                        formattedActivityDateOnly(detail.strTime),
                        style: subHeaderStyleGrey,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: colorTheme,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Start time, end time, priority, total task, category, repeat
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.blue,
                                            ),
                                            child: Icon(
                                              Icons.timer,
                                              color: Colors.blue[900],
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Start",
                                                style: textStyleGrey,
                                              ),
                                              Text(
                                                formattedActivityTimeOnly(
                                                    detail.strTime),
                                                style: textStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    // Priority
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.red,
                                            ),
                                            child: Icon(
                                              Icons.priority_high,
                                              color: Colors.red[900],
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Priority",
                                                style: textStyleGrey,
                                              ),
                                              Text(
                                                formattedPriority(
                                                    detail.impType,
                                                    detail.urgType),
                                                style: textStyle,
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
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.purple[400],
                                            ),
                                            child: Icon(
                                              Icons.category_rounded,
                                              color: Colors.purple[900],
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Category",
                                                style: textStyleGrey,
                                              ),
                                              Text(
                                                detail.catName == ""
                                                    ? "Uknown"
                                                    : detail.catName,
                                                style: textStyle,
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
                                    // End time
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.yellow,
                                            ),
                                            child: Icon(
                                              Icons.timelapse,
                                              color: Colors.yellow[900],
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "End time",
                                                style: textStyleGrey,
                                              ),
                                              Text(
                                                formattedActivityTimeOnly(
                                                    detail.endTime),
                                                style: textStyle,
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
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.green[100],
                                            ),
                                            child: Icon(
                                              Icons.task_outlined,
                                              color: Colors.green[700],
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Total task",
                                                style: textStyleGrey,
                                              ),
                                              Text(
                                                "${detail.tasks?.length ?? 0} Tasks",
                                                style: textStyle,
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
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.cyan,
                                            ),
                                            child: Icon(
                                              Icons.repeat,
                                              color: Colors.cyan[900],
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Repeat",
                                                style: textStyleGrey,
                                              ),
                                              Text(
                                                detail.rptFreq == "Never"
                                                    ? detail.rptFreq
                                                    : "${detail.rptFreq} ${detail.rptDur}X",
                                                style: textStyle,
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
                          // Wrap with SingleChildScrollView
                          child: detail.files!.isNotEmpty
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: detail.files!.map((file) {
                                      return GestureDetector(
                                        onTap: () {
                                          fileDownloadOpen(
                                              file.path, file.name);
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          margin:
                                              const EdgeInsets.only(right: 5),
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                flex: 2,
                                                child: Icon(
                                                  Icons.file_present_rounded,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 6,
                                                child: Text(
                                                  file.name,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(), // Corrected here
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    "There are no files added",
                                    style: textStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                        // Task Activity - Title
                        Container(
                          margin: const EdgeInsets.only(
                            top: 10,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Tasks activity",
                            style: textStyleBold,
                          ),
                        ),
                        // Task Activity - Content
                        SizedBox(
                          width: double.infinity,
                          child: detail.tasks!.isNotEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.topLeft,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    children: detail.tasks!.map(
                                      (task) {
                                        // Task
                                        return Text(
                                          "- ${task.task}",
                                          style: textStyle,
                                        );
                                      },
                                    ).toList(),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    "There are no tasks added",
                                    style: textStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                        // Location Activity - Title
                        Container(
                          margin: const EdgeInsets.only(
                            top: 10,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Locations",
                            style: textStyleBold,
                          ),
                        ),
                        // Location Activity - Content
                        SizedBox(
                          width: double.infinity,
                          child: detail.locations!.isNotEmpty
                              ? Column(
                                  children: detail.locations!.map(
                                    (location) {
                                      // Address
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        margin: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Colors.white,
                                        ),
                                        child: GestureDetector(
                                          // Link to open gmap and location address
                                          onTap: () {
                                            openGoogleMaps(location.latitude,
                                                location.longitude);
                                          },
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                flex: 2,
                                                child: Icon(
                                                  Icons.location_on_sharp,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                flex: 6,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      location.address,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                )
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    "There are no locations added",
                                    style: textStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                        // Notifications - Title
                        Container(
                          margin: const EdgeInsets.only(
                            top: 10,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Notifications",
                            style: textStyleBold,
                          ),
                        ),
                        // Notifications - Content
                        SizedBox(
                          width: double.infinity,
                          child: detail.notif!.isNotEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.topLeft,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    children: detail.notif!.map(
                                      (notif) {
                                        // Task
                                        return Text(
                                          "- Set a reminder ${notif.minute} minutes before",
                                          style: textStyle,
                                        );
                                      },
                                    ).toList(),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    "There are no Reminder added",
                                    style: textStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                            "Confirm Delete",
                                            style: subHeaderStyleBold,
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete this activity?',
                                            style: textStyle,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancel',
                                                  style: textStyleBold),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                deleteScheduledActivity(
                                                    widget.scheduledID,
                                                    detail.idAct);
                                              },
                                              child: Text(
                                                'Yes',
                                                style: textStyleBold,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      border: Border.all(
                                        width: 1,
                                        color:
                                            const Color.fromARGB(255, 3, 0, 66),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.delete,
                                          color: Colors.black,
                                        ),
                                        Text(
                                          "Delete",
                                          style: textStyleBold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: ((context) =>
                                                ActivityEditDetails(
                                                  actDetail: detail,
                                                ))));
                                    setState(() {
                                      detailAct =
                                          getDetailActivity(widget.scheduledID);
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color:
                                          const Color.fromARGB(255, 3, 0, 66),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          "Edit Activity",
                                          style: textStyleBoldWhite,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

/*
click gmaps link -> buka app gmap -> ke alamat yg sesuai
Buat halaman edit
Buat delete activity when fab delete cliked
open file pdf -> coba2
*/