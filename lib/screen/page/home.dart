import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:pickleapp/main.dart';
import 'package:http/http.dart' as http;
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/page/detailActivity.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/theme.dart';
import 'package:pickleapp/screen/class/activityList.dart';
import 'package:pickleapp/screen/fabexpandable/add_activities.dart';
import 'package:pickleapp/screen/fabexpandable/edit_activities.dart';
import 'package:pickleapp/screen/fabexpandable/delete_activities.dart';
import 'package:pickleapp/screen/page/profile.dart';

final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _key = GlobalKey<ExpandableFabState>();
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final String _todayDate =
      DateFormat("dd MMM yyyy").format(DateTime.now()).toString();

  String message = "";
  String scheduledID = "";

  List<ActivityList> ALs = [];
  List<ActivityList> actList = [];
  ActivityList? ALs2;
  Timer? _timer;

  @override
  void dispose() {
    // Cancel the timer in the dispose method
    _timer?.cancel();
    super.dispose();
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

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(String activityTime) {
    DateTime time = DateTime.parse(activityTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
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

  // Update only current activity to show
  void updateCurrentActivity() {
    DateTime now = DateTime.now();
    String currentTime = now.toString();

    for (var act in ALs) {
      if (currentTime.compareTo(act.start_time) >= 0 &&
          currentTime.compareTo(act.end_time) < 0) {
        setState(() {
          scheduledID = act.id_scheduled;
        });
        break;
      }
    }
  }

  // Get data current activity from database
  Future<String> fetchCurrentDataActivity() async {
    final response2 = await http.post(
        Uri.parse("http://192.168.1.12:8012/picklePHP/currentActivity.php"),
        body: {
          'email': active_user,
          'start_time': '%${_selectedDate}%',
          'sch_id': scheduledID.toString(),
        });
    if (response2.statusCode == 200) {
      return response2.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  // Convert it from JSON to list of ActivityList
  bacaDataCurrent() {
    fetchCurrentDataActivity().then((v) {
      Map json2 = jsonDecode(v);
      ALs2 = ActivityList.fromJson(json2['dataActivity']);
      setState(() {});
    });
  }

  // Get data from database
  Future<String> fetchData() async {
    final response = await http.post(
      Uri.parse("http://192.168.1.12:8012/picklePHP/activityList.php"),
      body: {
        'email': active_user,
        'start_time': '%${_selectedDate}%',
      }, // Untuk mengirim data (form) yang akan dibaca di PHP dengan $_POST
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  // Convert it from JSON to list of ActivityList
  bacaData() {
    ALs.clear();
    Future<String> dataActivity = fetchData();
    dataActivity.then((value) {
      setState(() {
        Map json = jsonDecode(value);
        if (json['dataActivity'] != null || json['dataActivity'].length > 0) {
          for (var activity in json['dataActivity']) {
            ActivityList al = ActivityList.fromJson(activity);
            ALs.add(al);
          }
        }
      });
    });
  }

  //Current Locations Activity
  Widget formattedCurrentLocations() {
    if (ALs2?.locations?.isEmpty ?? true) {
      // List is empty
      return const Text("Wherever you want :)");
    } else {
      //List is not empty
      return Column(
        children: (ALs2?.locations ?? [])
            .map(
              (location) {
                return Text(
                  "- ${location.address}",
                  style: textStyleGrey,
                );
              },
            )
            .whereType<Widget>()
            .toList(),
      );
    }
  }

  Future<void> getActivityList() async {
    try {
      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_id', isEqualTo: userID)
          .get();

      for (QueryDocumentSnapshot activity in actSnap.docs) {
        QuerySnapshot schSnap = await FirebaseFirestore.instance
            .collection('scheduled_activities')
            .where('activities_id', isEqualTo: activity.id)
            .where('actual_start_time',
                isEqualTo: Timestamp.fromDate(DateTime.parse(_selectedDate)))
            .get();

        for (QueryDocumentSnapshot activitySch in schSnap.docs) {
          Map<String, dynamic> actSch =
              activitySch.data() as Map<String, dynamic>;
          String activitiesId = actSch['activities_id'];

          DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
              .collection('activities')
              .doc(activitiesId)
              .get();
          if (activitySnapshot.exists) {
            Map<String, dynamic> activityData =
                activitySnapshot.data() as Map<String, dynamic>;

            // Fetch locations for this activity
            QuerySnapshot locationsSnapshot = await FirebaseFirestore.instance
                .collection('locations')
                .where('activities_id', isEqualTo: activitySnapshot.id)
                .get();

            List<Locations> locationsList = [];
            for (QueryDocumentSnapshot locationDoc in locationsSnapshot.docs) {
              Map<String, dynamic> locationData =
                  locationDoc.data() as Map<String, dynamic>;
              Locations location = Locations(
                address: locationData['address'],
                latitude: locationData['latitude'],
                longitude: locationData['longitude'],
              );
              locationsList.add(location);
            }

            int? color_a;
            int? color_r;
            int? color_g;
            int? color_b;
            DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
                .collection('categories')
                .doc(activityData['categories_id'])
                .get();
            if (categorySnapshot.exists) {
              Map<String, dynamic> categoryData =
                  categorySnapshot.data() as Map<String, dynamic>;
              color_a = categoryData['color_a'];
              color_r = categoryData['color_r'];
              color_g = categoryData['color_g'];
              color_b = categoryData['color_b'];
            }

            // Create ActivityList object
            ActivityList activity = ActivityList(
              id_activity: activitySnapshot.id,
              id_scheduled: activitySch.id,
              title: activityData['title'],
              start_time: actSch['actual_start_time'],
              end_time: actSch['actual_end_time'],
              important_type: activityData['important_type'],
              urgent_type: activityData['urgent_type'],
              color_a: color_a ?? 0,
              color_r: color_r ?? 0,
              color_g: color_g ?? 0,
              color_b: color_b ?? 0,
              timezone: activityData['important_type'],
            );

            actList.add(activity);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
      print('Error: $e');
    }
  }

  // Activity List
  Widget formattedListOfActivities() {
    if (actList.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        color: Colors.white,
        child: Text(
          "You're free on this day, Enjoy :)",
          style: headerStyle,
        ),
      );
    } else {
      return ListView.builder(
        itemCount: actList.length,
        itemBuilder: (BuildContext ctxt, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailActivity(
                    activityID: actList[index].id_scheduled,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                // Left (number) n Right (container)
                Row(
                  children: [
                    // Left
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "${index + 1}",
                          style: headerStyle,
                        ),
                      ),
                    ),
                    // Right
                    Expanded(
                      flex: 9,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(
                            actList[index].color_a,
                            actList[index].color_r,
                            actList[index].color_g,
                            actList[index].color_b,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: getPriorityColor(
                                        actList[index].important_type,
                                        actList[index].urgent_type,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      getPriority(
                                        actList[index].important_type,
                                        actList[index].urgent_type,
                                      ),
                                      style: textStyle,
                                    ),
                                  ),
                                  Text(
                                    actList[index].title,
                                    style: headerStyle,
                                  ),
                                  Text(
                                    "Do your activity at: ",
                                    style: textStyleGrey,
                                  ),
                                  Container(
                                    alignment: Alignment.topLeft,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          actList[index].locations?.length,
                                      itemBuilder:
                                          (BuildContext ctxt, int indx) {
                                        if (actList[index].locations?.length ==
                                            0) {
                                          // Still didn't show???
                                          return Text(
                                            "Wherever you want :)",
                                            style: textStyleGrey,
                                          );
                                        } else {
                                          return Text(
                                            "- ${actList[index].locations?[indx].address}",
                                            style: textStyleGrey,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    "${formattedActivityTimeOnly(actList[index].start_time)} - ${formattedActivityTimeOnly(ALs[index].end_time)}",
                                    style: subHeaderStyle,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                child: Image.asset(getPriorityImage(
                                    actList[index].important_type,
                                    actList[index].urgent_type)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    bacaData();
    print(_selectedDate);
    getActivityList();

    // Periodically check and update current activity
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      updateCurrentActivity();
      bacaDataCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(
          top: 40,
          left: 20,
          right: 20,
        ),
        child: Column(
          children: <Widget>[
            // Header Profile
            Row(
              /* profil alignment kanan*/
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/Default_Photo_Profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "Hello, ...",
                          style: subHeaderStyle,
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "Today, ${_todayDate}",
                          style: textStyleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Current activity - Title
            Container(
              margin: EdgeInsets.only(
                top: 15,
                bottom: 5,
              ),
              width: double.infinity,
              child: Text(
                "Current Task",
                style: headerStyle,
              ),
            ),
            // Curent Activity - Content
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailActivity(
                      activityID: ALs2!.id_scheduled,
                    ),
                  ),
                );
              },
              child: ALs2 == null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Text(
                        "You're free for now :)",
                        style: headerStyle,
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color.fromARGB(
                          ALs2?.color_a ?? 255,
                          ALs2?.color_r ?? 166,
                          ALs2?.color_g ?? 255,
                          ALs2?.color_b ?? 204,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: getPriorityColor(
                                      ALs2!.important_type,
                                      ALs2!.urgent_type,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    getPriority(
                                      ALs2!.important_type,
                                      ALs2!.urgent_type,
                                    ),
                                    style: textStyle,
                                  ),
                                ),
                                Text(
                                  ALs2!.title,
                                  style: screenTitleStyle,
                                ),
                                Text(
                                  "Do your activity at Place",
                                  style: textStyleGrey,
                                ),
                                Container(
                                  alignment: Alignment.topLeft,
                                  child: formattedCurrentLocations(),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "${formattedActivityTimeOnly(ALs2!.start_time)} - ${formattedActivityTimeOnly(ALs2!.end_time)}",
                                  style: subHeaderStyle,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              child: Image.asset(getPriorityImage(
                                  ALs2!.important_type, ALs2!.urgent_type)),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Date Calendar List
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: DatePicker(
                DateTime.now(),
                height: 90,
                width: 60,
                initialSelectedDate: DateTime.now(),
                selectionColor: Color.fromARGB(255, 166, 204, 255),
                selectedTextColor: Colors.black,
                dayTextStyle: GoogleFonts.fredoka(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                dateTextStyle: GoogleFonts.fredoka(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                monthTextStyle: GoogleFonts.fredoka(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                onDateChange: (date) {
                  _selectedDate = DateFormat('yyyy-MM-dd').format(date);
                  bacaData();
                  getActivityList();
                  print(_selectedDate);
                },
              ),
            ),
            // Activity list - Title
            Container(
              margin: const EdgeInsets.only(
                top: 10,
              ),
              width: double.infinity,
              child: Text(
                "Your Activity List",
                style: headerStyle,
              ),
            ),
            // Activity List - Content
            Expanded(
              child: formattedListOfActivities(),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        overlayStyle: ExpandableFabOverlayStyle(
          blur: 3,
        ),
        children: [
          FloatingActionButton.small(
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => AddActivities())));
            },
          ),
          FloatingActionButton.small(
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EditActivities())));
            },
          ),
          FloatingActionButton.small(
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.delete),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => DeleteActivities())));
            },
          ),
        ],
      ),
    );
  }
}
