import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/theme.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late Future<Map<String, dynamic>> data;

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

  Future<Map<String, dynamic>> getDetailActivity() async {
    final schDoc = await FirebaseFirestore.instance
        .collection('scheduled_activities')
        .doc(widget.scheduledID)
        .get();

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

    String? catID = actDoc['categories_id'];

    DocumentSnapshot? catDoc;
    if (catID != null && catID.isNotEmpty) {
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

    final locQuery = await FirebaseFirestore.instance
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

    final notifQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .where('scheduled_activities_id', isEqualTo: widget.scheduledID)
        .get();
    List<Notifications> notifs = [];
    for (var doc in notifQuery.docs) {
      notifs.add(Notifications(minute: doc['minutes_before']));
    }

    final taskQuery = await FirebaseFirestore.instance
        .collection('tasks')
        .where('activities_id', isEqualTo: actID)
        .get();
    List<Tasks> tasks = [];
    for (var doc in taskQuery.docs) {
      tasks.add(Tasks(task: doc['title'], status: doc['status']));
    }

    return {
      'activity': DetailActivities(
        id_act: schDoc['activities_id'],
        id_sch: widget.scheduledID,
        title: actDoc['title'],
        imp_type: actDoc['important_type'],
        urg_type: actDoc['urgent_type'],
        rpt_freq: actDoc['repeat_interval'],
        rpt_dur: actDoc['repeat_duration'],
        cat_name: catDoc == null ? null : catDoc['title'],
        clr_a: catDoc == null ? null : catDoc['color_a'],
        clr_r: catDoc == null ? null : catDoc['color_r'],
        clr_g: catDoc == null ? null : catDoc['color_g'],
        clr_b: catDoc == null ? null : catDoc['color_b'],
        str_time: strTime,
        end_time: endTimes,
        tasks: tasks,
        files: files,
        locations: locs,
      ),
    };
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

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

  void deleteSchedule(String scheduleID, String activityID) async {
    DocumentReference scheduleDocRef = FirebaseFirestore.instance
        .collection('scheduled_activities')
        .doc(scheduleID);

    DocumentSnapshot scheduleDocSnapshot = await scheduleDocRef.get();

    // Check if the document exists and the activities_id field matches the one you provided
    if (scheduleDocSnapshot.exists &&
        scheduleDocSnapshot['activities_id'] == activityID) {
      // If the activities_id matches, delete the document
      await scheduleDocRef.delete();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The schedule activity has been successfully deleted'),
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The schedule activity unsuccessfully deleted'),
        ),
      );
      // ignore: avoid_print
      print('Document not found or activities_id does not match');
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Widget formattedActivityDetail() {
    return FutureBuilder<Map<String, dynamic>>(
        future: getDetailActivity(),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Align(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<Tasks> tasks = snapshot.data!['activity'].tasks;
            List<Files> files = snapshot.data!['activity'].files;
            List<Locations> locs = snapshot.data!['activity'].locations;

            return Column(
              children: <Widget>[
                // Title activity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 255, 170,
                        0), // Change the color with activity color
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        snapshot.data!['activity'].title,
                        style: screenTitleStyle,
                      ),
                      Text(
                        formattedActivityDateOnly(
                            snapshot.data!['activity'].str_time),
                        style: subHeaderStyleGrey,
                      ),
                    ],
                  ),
                ),
                // Start time, end time, priority, total task, category, repeat
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(
                    top: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 255, 170,
                        0), // Change the color with activity color
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.blue[100],
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.blue[700],
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
                                        "Start time",
                                        style: textStyleGrey,
                                      ),
                                      Text(
                                        formattedActivityTimeOnly(snapshot
                                            .data!['activity'].str_time),
                                        style: subHeaderStyle,
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.orange[100],
                                    ),
                                    child: Icon(
                                      Icons.local_parking_rounded,
                                      color: Colors.orange[700],
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
                                            snapshot.data!['activity'].imp_type,
                                            snapshot
                                                .data!['activity'].urg_type),
                                        style: subHeaderStyle,
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.purple[100],
                                    ),
                                    child: Icon(
                                      Icons.category_rounded,
                                      color: Colors.purple[700],
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
                                        snapshot.data!['activity'].cat_name ??
                                            "Uknown",
                                        style: subHeaderStyle,
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.purple[100],
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.purple[700],
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
                                        formattedActivityTimeOnly(snapshot
                                            .data!['activity'].end_time),
                                        style: subHeaderStyle,
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
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
                                        "${tasks.isNotEmpty ? tasks.length : 0} Tasks",
                                        style: subHeaderStyle,
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.blue[100],
                                    ),
                                    child: Icon(
                                      Icons.repeat,
                                      color: Colors.blue[700],
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
                                        snapshot.data!['activity'].rpt_freq ==
                                                "Never"
                                            ? snapshot
                                                .data!['activity'].rpt_freq
                                            : "${snapshot.data!['activity'].rpt_freq} ${snapshot.data!['activity'].rpt_dur}X",
                                        style: subHeaderStyle,
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
                    top: 10,
                  ),
                  width: double.infinity,
                  child: Text(
                    "Attachment Files",
                    style: headerStyle,
                  ),
                ),
                // Attachment Files - Content
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  // Wrap with SingleChildScrollView
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: files.isNotEmpty
                          ? files.map((file) {
                              return GestureDetector(
                                onTap: () {
                                  // Handle onTap
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  margin: const EdgeInsets.only(right: 5),
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color:
                                        const Color.fromARGB(255, 255, 170, 0),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.purple[100],
                                          ),
                                          child: Icon(
                                            Icons.file_present_rounded,
                                            color: Colors.purple[700],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 6,
                                        child: Text(
                                          file.name,
                                          style: subHeaderStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList()
                          : [
                              const Text("There is no files"),
                            ], // Corrected here
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
                    style: headerStyle,
                  ),
                ),
                // Task Activity - Content
                SizedBox(
                  width: double.infinity,
                  child: tasks.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.topLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 255, 170, 0),
                          ),
                          child: Column(
                            children: tasks.map(
                              (task) {
                                // Task
                                return Text(
                                  "- ${task.task}",
                                  style: GoogleFonts.fredoka(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        )
                      : const Text("There is no tasks"),
                ),
                // Location Activity - Title
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Locations",
                    style: headerStyle,
                  ),
                ),
                // Location Activity - Content
                SizedBox(
                  width: double.infinity,
                  child: locs.isNotEmpty
                      ? Column(
                          children: locs.map(
                            (location) {
                              // Address
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(
                                  bottom: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color.fromARGB(255, 255, 170, 0),
                                ),
                                child: GestureDetector(
                                  // Link to open gmap and location address
                                  onTap: () {
                                    openGoogleMaps(
                                        location.latitude, location.longitude);
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.orange[100],
                                          ),
                                          child: Icon(
                                            Icons.location_on_sharp,
                                            color: Colors.orange[700],
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
                                              location.address,
                                              style: subHeaderStyle,
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
                      : const Text("There is no locations"),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color.fromARGB(255, 166, 204, 255),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Colors.black,
                                ),
                                Text(
                                  "Delete",
                                  style: subHeaderStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color.fromARGB(255, 166, 204, 255),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                Text(
                                  "Edit Activity",
                                  style: subHeaderStyle,
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
            );
          }
        });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    data = getDetailActivity();
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
            255, 3, 0, 66), // Change the color with activity color
        title: Text(
          'Detail Activity',
          style: screenTitleStyleWhite,
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        height: double.infinity,
        width: double.infinity,
        child: SingleChildScrollView(
          child: formattedActivityDetail(),
        ),
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