import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:pickleapp/screen/class/activity_detail.dart';

class DetailActivity extends StatefulWidget {
  final String activityID;
  DetailActivity({super.key, required this.activityID});

  @override
  State<DetailActivity> createState() => _DetailActivityState();
}

class _DetailActivityState extends State<DetailActivity> {
  final _key = GlobalKey<ExpandableFabState>();
  bool _isChecked = false;
  DetailActivities? DAs;

  @override
  void initState() {
    super.initState();
    bacaData();
    print(widget.activityID.toString());
  }

  // Get Priority from important n urgent
  String formattedPriority(String impt, String urgt) {
    if (impt == "Important" && urgt == "Urgent") {
      return "Golf (Critical)";
    } else if (impt == "Important" && urgt == "Not Urgent") {
      return "Pebbles (High)";
    } else if (impt == "Not Important" && urgt == "Urgent") {
      return "Sand (Medium)";
    } else {
      return "Water (Low)";
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

  Future<String> fetchData() async {
    final response = await http.post(
        Uri.parse("http://192.168.1.12:8012/picklePHP/detailActivity.php"),
        body: {'sch_id': widget.activityID.toString()});
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  bacaData() {
    fetchData().then((value) {
      Map json = jsonDecode(value);
      DAs = DetailActivities.fromJson(json['dataDetail']);
      setState(() {});
    });
  }

  Widget formattedListOfFiles() {
    if (DAs?.files?.isEmpty ?? true) {
      // List is empty
      return const Text("There is no files");
    } else {
      // List isn't empty
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: DAs?.files?.length,
        itemBuilder: (BuildContext ctxt, int index) {
          return GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => DetailActivity(
              //       activityID: ALs[index].id_scheduled,
              //     ),
              //     // DetailMovie2(movieID: PMs[index].id),
              //   ),
              // );
            },
            child: Row(
              children: [
                // file
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  margin: const EdgeInsets.only(
                    right: 5,
                  ),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Row(
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
                            Icons.file_present_rounded,
                            color: Colors.purple[700],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          DAs?.files?[index]['url'],
                          style: subHeaderStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget formattedListOfTasks() {
    if (DAs?.tasks?.isEmpty ?? true) {
      // List is empty
      return const Text("There is no tasks");
    } else {
      //List is not empty
      return Column(
        children: DAs?.tasks?.map(
              (task) {
                // Task
                return Container(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Checkbox(
                          // not yet implemented with status in activity_tasks table
                          value: _isChecked,
                          onChanged: (bool? v) {
                            setState(() {
                              _isChecked = v!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          task['task'],
                          style: GoogleFonts.fredoka(
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: _isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ).toList() ??
            [],
      );
    }
  }

  Widget formattedListOfLocations() {
    if (DAs?.locations?.isEmpty ?? true) {
      // List is empty
      return const Text("There is no locations");
    } else {
      //List is not empty
      return Column(
        children: DAs?.locations?.map(
              (location) {
                // Address
                return Container(
                  child: GestureDetector(
                    // Link to open gmap and location address
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => DetailActivity()),
                      // );
                    },
                    child: Row(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location["address"],
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
            ).toList() ??
            [],
      );
    }
  }

  Widget tampilData() {
    if (DAs == null) {
      return Column(
        children: [
          // Show circular progress indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            alignment: Alignment.topCenter,
            child: const CircularProgressIndicator(),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          // Title activity
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white, // Change the color with activity color
            ),
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Text(
                  DAs!.title,
                  style: screenTitleStyle,
                ),
                Text(
                  formattedActivityDateOnly(DAs!.str_time),
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
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white, // Change the color with activity color
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start time",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  formattedActivityTimeOnly(DAs!.str_time),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Priority",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  formattedPriority(
                                      DAs!.imp_type, DAs!.urg_type),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Category",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  DAs?.cat_name ?? "Uknown",
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "End time",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  formattedActivityTimeOnly(DAs!.end_time),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total task",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  "${DAs?.tasks?.length.toString() ?? 0} Tasks",
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Repeat",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  "${DAs!.rpt_freq} ${DAs?.rpt_int ?? 0}X",
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
              left: 20,
              right: 20,
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
            margin: const EdgeInsets.only(
              top: 5,
              left: 20,
            ),
            alignment: Alignment.center,
            //Listbuilder bellow
            child: formattedListOfFiles(),
          ),
          // Task n Location
          SingleChildScrollView(
            child: Column(
              children: [
                // Task Activity - Title
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 20,
                    right: 20,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tasks activity",
                    style: headerStyle,
                  ),
                ),
                // Task Activity - Content
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    top: 5,
                    left: 20,
                    right: 20,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: formattedListOfTasks(),
                ),
                // Location Activity - Title
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 20,
                    right: 20,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Locations",
                    style: headerStyle,
                  ),
                ),
                // Location Activity - Content
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    top: 5,
                    left: 20,
                    right: 20,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: formattedListOfLocations(),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(
            255, 166, 204, 255), // Change the color with activity color
        title: Text(
          'Detail Activity',
          style: screenTitleStyle,
        ),
      ),
      body: tampilData(),
      // FAB Edit, Delete
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        overlayStyle: ExpandableFabOverlayStyle(
          // Color based category activity
          // color: Colors.black,
          blur: 3,
        ),
        children: [
          FloatingActionButton.large(
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.edit_note_rounded),
            onPressed: () {
              // Navigator.of(context).push(
              //   MaterialPageRoute(builder: ((context) => DetailActivity())),
              // );
            },
          ),
          FloatingActionButton.large(
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.delete_forever_rounded),
            onPressed: () {
              // Navigator.of(context).push(
              //   MaterialPageRoute(builder: ((context) => DetailActivity())),
              // );
            },
          ),
        ],
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