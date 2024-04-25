import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/page/detail_activity.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/theme.dart';
import 'package:pickleapp/screen/class/activity_list.dart';
import 'package:pickleapp/screen/fabexpandable/add_activities.dart';
import 'package:pickleapp/screen/fabexpandable/edit_activities.dart';
import 'package:pickleapp/screen/fabexpandable/delete_activities.dart';
import 'package:pickleapp/auth.dart';

final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

class Home extends StatefulWidget {
  const Home({super.key});

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

  List<ActivityList> actList = [];
  ActivityList? aLS2;
  late Future<List<ActivityList>> activityListFuture;
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
  // Color getPriorityColor(important, urgent) {
  //   if (important == "Important" && urgent == "Urgent") {
  //     return Colors.red[600] ?? Colors.red;
  //   } else if (important == "Important" && urgent == "Not Urgent") {
  //     return Colors.yellow[600] ?? Colors.yellow;
  //   } else if (important == "Not Important" && urgent == "Urgent") {
  //     return Colors.green[600] ?? Colors.green;
  //   } else {
  //     return Colors.blue[600] ?? Colors.blue;
  //   }
  // }

  // // Update only current activity to show
  // void updateCurrentActivity() {
  //   DateTime now = DateTime.now();
  //   String currentTime = now.toString();
  //   for (var act in ALs) {
  //     if (currentTime.compareTo(act.start_time) >= 0 &&
  //         currentTime.compareTo(act.end_time) < 0) {
  //       setState(() {
  //         scheduledID = act.id_scheduled;
  //       });
  //       break;
  //     }
  //   }
  // }
  // // Get data current activity from database
  // Future<String> fetchCurrentDataActivity() async {
  //   final response2 = await http.post(
  //       Uri.parse("http://192.168.1.12:8012/picklePHP/currentActivity.php"),
  //       body: {
  //         'email': active_user,
  //         'start_time': '%${_selectedDate}%',
  //         'sch_id': scheduledID.toString(),
  //       });
  //   if (response2.statusCode == 200) {
  //     return response2.body;
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }
  // // Convert it from JSON to list of ActivityList
  // bacaDataCurrent() {
  //   fetchCurrentDataActivity().then((v) {
  //     Map json2 = jsonDecode(v);
  //     aLS2 = ActivityList.fromJson(json2['dataActivity']);
  //     setState(() {});
  //   });
  // }
  // Get data from database
  // Future<String> fetchData() async {
  //   final response = await http.post(
  //     Uri.parse("http://192.168.1.12:8012/picklePHP/activityList.php"),
  //     body: {
  //       'email': active_user,
  //       'start_time': '%${_selectedDate}%',
  //     }, // Untuk mengirim data (form) yang akan dibaca di PHP dengan $_POST
  //   );
  //   if (response.statusCode == 200) {
  //     return response.body;
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }
  // Convert it from JSON to list of ActivityList
  // bacaData() {
  //   ALs.clear();
  //   Future<String> dataActivity = fetchData();
  //   dataActivity.then((value) {
  //     setState(() {
  //       Map json = jsonDecode(value);
  //       if (json['dataActivity'] != null || json['dataActivity'].length > 0) {
  //         for (var activity in json['dataActivity']) {
  //           ActivityList al = ActivityList.fromJson(activity);
  //           ALs.add(al);
  //         }
  //       }
  //     });
  //   });
  // }
  // // Current Locations Activity
  // Widget formattedCurrentLocations() {
  //   if (aLS2?.locations?.isEmpty ?? true) {
  //     // List is empty
  //     return const Text("Wherever you want :)");
  //   } else {
  //     //List is not empty
  //     return Column(
  //       children: (aLS2?.locations ?? [])
  //           .map(
  //             (location) {
  //               return Text(
  //                 "- ${location.address}",
  //                 style: textStyleGrey,
  //               );
  //             },
  //           )
  //           .whereType<Widget>()
  //           .toList(),
  //     );
  //   }
  // }

  Future<List<ActivityList>> getActivityList() async {
    List<ActivityList> activitiesList = [];

    // Convert date string to DateTime and then to Timestamp
    DateTime dateTime = DateTime.parse(_selectedDate);
    Timestamp startOfDay = Timestamp.fromDate(dateTime);
    Timestamp endOfDay =
        Timestamp.fromDate(dateTime.add(const Duration(days: 1)));

    QuerySnapshot schSnap = await FirebaseFirestore.instance
        .collection('scheduled_activities')
        .where('actual_start_time', isGreaterThanOrEqualTo: startOfDay)
        .where('actual_start_time', isLessThan: endOfDay)
        .get();

    for (QueryDocumentSnapshot scheduleDoc in schSnap.docs) {
      Map<String, dynamic>? scheduleData =
          scheduleDoc.data() as Map<String, dynamic>?;

      String? activityId;

      if (scheduleData != null) {
        activityId = scheduleData['activities_id'] as String?;
      }

      Timestamp? actualStartTimeTimestamp =
          scheduleData?['actual_start_time'] as Timestamp?;

      DateTime? actualStartTime = actualStartTimeTimestamp?.toDate();

      String? actualStartTimeString;
      if (actualStartTime != null) {
        actualStartTimeString = actualStartTime.toString();
      }

      Timestamp? actualEndTimeTimestamp =
          scheduleData?['actual_end_time'] as Timestamp?;

      DateTime? actualEndTime = actualEndTimeTimestamp?.toDate();

      String? actualEndTimeString;
      if (actualEndTime != null) {
        actualEndTimeString = actualEndTime.toString();
      }

      // print("test 1: $actualStartTimeString");

      if (activityId != null) {
        // print("test 2: $activityId");
        QuerySnapshot activityQuerySnapshot = await FirebaseFirestore.instance
            .collection('activities')
            .where(FieldPath.documentId, isEqualTo: activityId)
            .where('user_id', isEqualTo: userID)
            .get();

        if (activityQuerySnapshot.docs.isNotEmpty) {
          DocumentSnapshot activityDoc = activityQuerySnapshot.docs.first;
          Map<String, dynamic> activityData =
              activityDoc.data() as Map<String, dynamic>;

          QuerySnapshot locQuerySnapshot = await FirebaseFirestore.instance
              .collection('locations')
              .where('activities_id', isEqualTo: activityId)
              .get();

          List<Locations> locations = locQuerySnapshot.docs.map((locDoc) {
            Map<String, dynamic> locData =
                locDoc.data() as Map<String, dynamic>;
            return Locations(
              address: locData['address'] as String,
              latitude: locData['latitude'] as double,
              longitude: locData['longitude'] as double,
            );
          }).toList();

          String? categoriesId = activityData['categories_id'] as String?;
          Map<String, dynamic>? categoryData;

          if (categoriesId != null && categoriesId.isNotEmpty) {
            DocumentSnapshot categoryDoc = await FirebaseFirestore.instance
                .collection('categories')
                .doc(categoriesId)
                .get();
            categoryData = categoryDoc.data() as Map<String, dynamic>?;
          }

          ActivityList activity = ActivityList(
            id_activity: activityId,
            id_scheduled: scheduleDoc.id,
            title: activityData['title'] as String,
            start_time: actualStartTimeString!,
            end_time: actualEndTimeString!,
            important_type: activityData['important_type'] as String,
            urgent_type: activityData['urgent_type'] as String,
            color_a: categoryData != null ? categoryData['color_a'] as int : 0,
            color_r: categoryData != null ? categoryData['color_r'] as int : 0,
            color_g: categoryData != null ? categoryData['color_g'] as int : 0,
            color_b: categoryData != null ? categoryData['color_b'] as int : 0,
            timezone: "Test",
            locations: locations,
          );

          activitiesList.add(activity);
          // print("Activity List: $activitiesList");
        }
      } else {
        // print('Test');
      }
    }
    return activitiesList;
  }

  void _fetchActivityList() async {
    // Fetch activities list from your function
    List<ActivityList> activities = await getActivityList();

    // Update state
    setState(() {
      actList = activities;
    });
  }

  // Activity List
  Widget formattedListOfActivities(List<ActivityList> activList) {
    if (activList.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 255, 170, 0),
        ),
        child: Text(
          "You're free on this day, Enjoy :)",
          style: headerStyle,
        ),
      );
    } else {
      return ListView.builder(
        itemCount: activList.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailActivity(
                    activityID: activList[index].id_scheduled,
                  ),
                ),
              );
              // print(activList[index].id_scheduled);
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
                            activList[index].color_a == 0
                                ? 255
                                : activList[index].color_a,
                            activList[index].color_r == 0
                                ? 255
                                : activList[index].color_r,
                            activList[index].color_g == 0
                                ? 170
                                : activList[index].color_g,
                            activList[index].color_b == 0
                                ? 0
                                : activList[index].color_b,
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
                                        color: const Color.fromARGB(
                                            255, 3, 0, 66)),
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      getPriority(
                                        activList[index].important_type,
                                        activList[index].urgent_type,
                                      ),
                                      style: textStyleWhite,
                                    ),
                                  ),
                                  Text(
                                    activList[index].title,
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
                                          activList[index].locations?.length ??
                                              0,
                                      itemBuilder:
                                          (BuildContext ctxt, int indx) {
                                        if (activList[index]
                                                .locations
                                                ?.isNotEmpty ==
                                            true) {
                                          return Text(
                                            "- ${activList[index].locations?[indx].address}",
                                            style: textStyleGrey,
                                          );
                                        } else {
                                          return Text(
                                            "Wherever you want :)",
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
                                    "${formattedActivityTimeOnly(activList[index].start_time)} - ${formattedActivityTimeOnly(activList[index].end_time)}",
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
                                    activList[index].important_type,
                                    activList[index].urgent_type)),
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
    // bacaData();
    // print("selected date: $_selectedDate");
    _fetchActivityList();

    // Periodically check and update current activity
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // updateCurrentActivity();
      // bacaDataCurrent();
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
                          "Today, $_todayDate",
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
              margin: const EdgeInsets.only(
                top: 15,
              ),
              width: double.infinity,
              child: Text(
                "Current Activity",
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
                      activityID: aLS2!.id_scheduled,
                    ),
                  ),
                );
              },
              child: aLS2 == null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(255, 255, 170, 0),
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
                          aLS2?.color_a ?? 255,
                          aLS2?.color_r ?? 166,
                          aLS2?.color_g ?? 255,
                          aLS2?.color_b ?? 204,
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
                                    color: const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    getPriority(
                                      aLS2!.important_type,
                                      aLS2!.urgent_type,
                                    ),
                                    style: textStyle,
                                  ),
                                ),
                                Text(
                                  aLS2!.title,
                                  style: screenTitleStyle,
                                ),
                                Text(
                                  "Do your activity at Place",
                                  style: textStyleGrey,
                                ),
                                // Container(
                                //   alignment: Alignment.topLeft,
                                //   child: formattedCurrentLocations(),
                                // ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "${formattedActivityTimeOnly(aLS2!.start_time)} - ${formattedActivityTimeOnly(aLS2!.end_time)}",
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
                                  aLS2!.important_type, aLS2!.urgent_type)),
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
                selectionColor: const Color.fromARGB(255, 3, 0, 66),
                selectedTextColor: Colors.white,
                dayTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                dateTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                monthTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                onDateChange: (date) {
                  _selectedDate = date.toString();
                  // bacaData();
                  _fetchActivityList();
                  // print("selected date: $_selectedDate");
                  // print("user ID: $userID");
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
              child: formattedListOfActivities(actList),
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
            foregroundColor: const Color.fromARGB(255, 255, 170, 0),
            backgroundColor: const Color.fromARGB(255, 3, 0, 66),
            splashColor: const Color.fromARGB(255, 255, 170, 0),
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => AddActivities())));
            },
          ),
          FloatingActionButton.small(
            foregroundColor: const Color.fromARGB(255, 255, 170, 0),
            backgroundColor: const Color.fromARGB(255, 3, 0, 66),
            splashColor: const Color.fromARGB(255, 255, 170, 0),
            shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EditActivities())));
            },
          ),
          FloatingActionButton.small(
            foregroundColor: const Color.fromARGB(255, 255, 170, 0),
            backgroundColor: const Color.fromARGB(255, 3, 0, 66),
            splashColor: const Color.fromARGB(255, 255, 170, 0),
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
