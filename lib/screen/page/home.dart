// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/profile.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:pickleapp/screen/page/detail_activity.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/theme.dart';
import 'package:pickleapp/screen/class/activity_list.dart';
import 'package:pickleapp/screen/page/add_activities.dart';
import 'package:pickleapp/auth.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  late List<DateTime> activeDates;

  String message = "";
  String scheduledID = "";

  List<ActivityList> actList = [];
  ActivityList? aLS2;
  late Future<List<ActivityList>> activityListFuture;
  Timer? _timer;
  CalendarFormat calendarFormat = CalendarFormat.week;

  void _initializeActiveDates() {
    // Create a list of active dates, for example, the past 365 days
    activeDates = List<DateTime>.generate(365, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void dispose() {
    // Cancel the timer in the dispose method
    _timer?.cancel();
    super.dispose();
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

  /* ------------------------------------------------------------------------------------------------------------------- */

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
  String getPriorityTypeOnly(important, urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return "Utama";
    } else if (important == "Important" && urgent == "Not Urgent") {
      return "Tinggi";
    } else if (important == "Not Important" && urgent == "Urgent") {
      return "Sedang";
    } else {
      return "Rendah";
    }
  }

  Color getPriorityColorByPriorityType(String priorityType) {
    if (priorityType == "Utama") {
      return Colors.red;
    } else if (priorityType == "Tinggi") {
      return Colors.yellow;
    } else if (priorityType == "Sedang") {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  String getPriorityImageByPriorityType(String priorityType) {
    if (priorityType == "Utama") {
      return 'assets/golfBall_1.png';
    } else if (priorityType == "Tinggi") {
      return 'assets/pebbles_1.png';
    } else if (priorityType == "Sedang") {
      return 'assets/sand_1.png';
    } else {
      return 'assets/water_1.png';
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(String activityTime) {
    DateTime time = DateTime.parse(activityTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

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
            idActivity: activityId,
            idScheduled: scheduleDoc.id,
            title: activityData['title'] as String,
            startTime: actualStartTimeString!,
            endTime: actualEndTimeString!,
            importantType: activityData['important_type'] as String,
            urgentType: activityData['urgent_type'] as String,
            colorA: categoryData != null ? categoryData['color_a'] as int : 0,
            colorR: categoryData != null ? categoryData['color_r'] as int : 0,
            colorG: categoryData != null ? categoryData['color_g'] as int : 0,
            colorB: categoryData != null ? categoryData['color_b'] as int : 0,
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

  Future<ProfileClass?> getProfile() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();

    if (userDoc.exists) {
      var userData = userDoc.data()!;
      String imagePath = userData['path'];
      String imageUrl =
          await FirebaseStorage.instance.ref(imagePath).getDownloadURL();

      return ProfileClass(
        email: userData['email'],
        name: userData['name'],
        path: imageUrl,
      );
    }
    return null;
  }

  Future<Map<String, int>> getActivitiesPerPriority() async {
    DateTime dateTime = DateTime.parse(_selectedDate);
    Timestamp startOfDay = Timestamp.fromDate(dateTime);
    Timestamp endOfDay =
        Timestamp.fromDate(dateTime.add(const Duration(days: 1)));

    final schedSnap = await FirebaseFirestore.instance
        .collection("scheduled_activities")
        .where("actual_start_time", isGreaterThanOrEqualTo: startOfDay)
        .where("actual_start_time", isLessThan: endOfDay)
        .get();

    Map<String, int> totalPriority = {};

    for (var doc in schedSnap.docs) {
      String activityId = doc["activities_id"];

      DocumentSnapshot actSnap = await FirebaseFirestore.instance
          .collection("activities")
          .doc(activityId)
          .get();

      Map<String, dynamic> actData = actSnap.data() as Map<String, dynamic>;
      if (actData['user_id'] == userID) {
        String priorityType = getPriorityTypeOnly(
            actData["important_type"], actData["urgent_type"]);

        if (totalPriority.containsKey(priorityType)) {
          totalPriority[priorityType] = totalPriority[priorityType]! + 1;
        } else {
          totalPriority[priorityType] = 1;
        }
      }
    }
    return totalPriority;
  }

  Future<void> deleteScheduledActivity(
      String scheduleID, String activityID) async {
    try {
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
            await AwesomeNotifications().cancel(doc.id.hashCode);
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
          }

          await schedRef.delete();
        }

        Navigator.of(context).pop();
        Navigator.of(context).pop();

        AlertInformation.showDialogBox(
          context: context,
          title: "Deleted Schedule",
          message: "Successfully deleted the schedule activity, Thank you.",
        );
      } else {
        Navigator.of(context).pop();
        Navigator.of(context).pop();

        AlertInformation.showDialogBox(
          context: context,
          title: "Undeleted Schedule",
          message: "The schedule activity unsuccessfully deleted.",
        );
        print('Document not found or activities_id does not match');
      }
    } catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
        context: context,
        title: "E",
        message: "E",
      );
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Widget profileTop(BuildContext context) {
    return FutureBuilder<ProfileClass?>(
      future: getProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: textStyleWhite,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Text(
              'Profil Pengguna Tidak Ditemukan',
              style: textStyleWhite,
            ),
          );
        } else {
          ProfileClass user = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(user.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo,",
                      style: subHeaderStyleGrey,
                    ),
                    Text(
                      user.name,
                      style: screenTitleStyleWhite,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget formattedTotalActivitiesPerPriority(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: getActivitiesPerPriority(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              // style: caption1Style,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Row(
            children: [
              Container(
                margin: const EdgeInsets.only(
                  right: 5,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  color: getPriorityColorByPriorityType("Utama"),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        getPriorityImageByPriorityType("Utama"),
                      ),
                    ),
                    Text(
                      "Prioritas Utama",
                      style: textStyle,
                    ),
                    Expanded(
                      child: Text(
                        "0 Aktivitas",
                        style: textStyleBold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  right: 5,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  color: getPriorityColorByPriorityType("Tinggi"),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        getPriorityImageByPriorityType("Tinggi"),
                      ),
                    ),
                    Text(
                      "Prioritas Tinggi",
                      style: textStyle,
                    ),
                    Expanded(
                      child: Text(
                        "0 Aktivitas",
                        style: textStyleBold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  right: 5,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  color: getPriorityColorByPriorityType("Sedang"),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        getPriorityImageByPriorityType("Sedang"),
                      ),
                    ),
                    Text(
                      "Prioritas Sedang",
                      style: textStyle,
                    ),
                    Expanded(
                      child: Text(
                        "0 Aktivitas",
                        style: textStyleBold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  right: 5,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  color: getPriorityColorByPriorityType("Rendah"),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        getPriorityImageByPriorityType("Rendah"),
                      ),
                    ),
                    Text(
                      "Prioritas Rendah",
                      style: textStyle,
                    ),
                    Expanded(
                      child: Text(
                        "0 Aktivitas",
                        style: textStyleBold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          Map<String, int> priority = snapshot.data!;
          return Row(
            children: priority.entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(
                  right: 5,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  color: getPriorityColorByPriorityType(e.key),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        getPriorityImageByPriorityType(e.key),
                      ),
                    ),
                    Text(
                      "Prioritas ${e.key}",
                      style: textStyle,
                    ),
                    Expanded(
                      child: Text(
                        "${e.value} Aktivitas",
                        style: textStyleBold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  // Activity List
  Widget formattedListOfActivities(BuildContext context) {
    return FutureBuilder<List<ActivityList>>(
        future: getActivityList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                // style: caption1Style,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.only(
                bottom: 20,
                left: 20,
                right: 20,
                top: 10,
              ),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color.fromARGB(255, 3, 0, 66),
                ),
              ),
              child: Text(
                "Kamu belum punya aktivitas apapun, mulai rencanakan aktivitasmu hari ini dan keluarkan potensimu sepenuhnya.",
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            );
          } else {
            List<ActivityList> activity = snapshot.data!;

            return ListView.builder(
              itemCount: activity.length,
              itemBuilder: (BuildContext context, int index) {
                ActivityList act = activity[index];
                String priority =
                    getPriorityTypeOnly(act.importantType, act.urgentType);

                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailActivity(
                          scheduledID: act.idScheduled,
                        ),
                      ),
                    );
                    setState(() {
                      getActivityList();
                      // scheduleNotifications(userID);
                    });
                    // print(activList[index].id_scheduled);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 5,
                      right: 20,
                      left: 20,
                    ),
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
                                  style: headerStyleBold,
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
                                  borderRadius: BorderRadius.circular(15),
                                  color:
                                      getPriorityColorByPriorityType(priority),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: const Color.fromARGB(
                                                    255, 3, 0, 66)),
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                              bottom: 5,
                                              left: 10,
                                              right: 10,
                                            ),
                                            child: Text(
                                              "Prioritas $priority",
                                              style: textStyleBoldWhite,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: PopupMenuButton(
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.delete,
                                                                  color: Colors
                                                                      .black),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Hapus'),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                              onSelected: (value) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        "Konfirmasi Hapus",
                                                        style:
                                                            subHeaderStyleBold,
                                                      ),
                                                      content: Text(
                                                        'Apakah kamu yakin untuk menghapus jadwal kegiatan ini?',
                                                        style: textStyle,
                                                      ),
                                                      actions: [
                                                        GestureDetector(
                                                          onTap: () async {
                                                            await deleteScheduledActivity(
                                                              act.idScheduled,
                                                              act.idActivity,
                                                            );

                                                            setState(() {
                                                              getActivityList();
                                                            });
                                                          },
                                                          child: Container(
                                                            alignment: Alignment
                                                                .center,
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15),
                                                              border:
                                                                  Border.all(
                                                                width: 1,
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    3,
                                                                    0,
                                                                    66),
                                                              ),
                                                            ),
                                                            child: // Space between icon and text
                                                                Text(
                                                              'Hapus',
                                                              style:
                                                                  textStyleBold,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 5),
                                                            alignment: Alignment
                                                                .center,
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15),
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  3, 0, 66),
                                                            ),
                                                            child: Text(
                                                              'Batal',
                                                              style:
                                                                  textStyleBoldWhite,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                act.title,
                                                style: headerStyleBold,
                                              ),
                                              Text(
                                                "Lakukan Aktivitasmu di: ",
                                                style: textStyle,
                                              ),
                                              act.locations == null
                                                  ? Text(
                                                      "Dimanapun :)",
                                                      style: textStyle,
                                                    )
                                                  : Column(
                                                      children: List.generate(
                                                          act.locations!.length,
                                                          (int indx) {
                                                        return Text(
                                                          "- ${act.locations![indx].address}",
                                                          style: textStyle,
                                                        );
                                                      }),
                                                    ),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              Text(
                                                "${formattedActivityTimeOnly(act.startTime)} - ${formattedActivityTimeOnly(act.endTime)}",
                                                style: subHeaderStyleBold,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            margin: const EdgeInsets.all(10),
                                            child: Image.asset(
                                                getPriorityImageByPriorityType(
                                                    priority)),
                                          ),
                                        ),
                                      ],
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
                  ),
                );
              },
            );
          }
        });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    getProfile();
    getActivitiesPerPriority();
    _initializeActiveDates();
    fetchDataAndScheduleNotifications();
  }

  Future<void> fetchDataAndScheduleNotifications() async {
    await getActivityList();
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: <Widget>[
            Container(
              width: constraints.maxWidth,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 10,
              ),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 3, 0, 66),
              ),
              child: profileTop(context),
            ),
            // Total Activity Per Priority - Title
            Container(
              width: constraints.maxWidth,
              margin: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                "Total Kegiatan per Prioritas",
                style: subHeaderStyleBold,
              ),
            ),
            // Total Activity Per Priority - Content
            Container(
              margin: const EdgeInsets.only(
                left: 20,
                right: 20,
              ),
              width: constraints.maxWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: formattedTotalActivitiesPerPriority(context),
              ),
            ),
            //Calendar
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20),
              child: TableCalendar(
                locale: 'id_ID',
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                calendarFormat: calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedDate =
                        DateFormat("yyyy-MM-dd").format(selectedDay);
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: subHeaderStyleBold,
                  weekendTextStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  selectedTextStyle: subHeaderStyleBoldWhite,
                  todayTextStyle: subHeaderStyleBold,
                  todayDecoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color.fromARGB(255, 3, 0, 66),
                    shape: BoxShape.circle,
                  ),
                ),
                headerVisible: true,
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: subHeaderStyleBold,
                  formatButtonVisible: false,
                  formatButtonShowsNext: false,
                ),
              ),
            ),
            // Activity list - Title
            Container(
              margin: const EdgeInsets.only(
                left: 20,
                right: 20,
              ),
              width: constraints.maxWidth,
              child: Text(
                "Your Activities",
                style: subHeaderStyleBold,
              ),
            ),
            // Activity List - Content
            Expanded(
              child: formattedListOfActivities(context),
            ),
          ],
        );
      }),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: ((context) => const AddActivities())),
          ).then((result) {
            if (result == true) {
              // Data was added, refresh timer.dart
              Provider.of<ActivityTaskToday>(context, listen: false)
                  .resetDataLoaded();
              Provider.of<ActivityTaskToday>(context, listen: false)
                  .getListOfTodayActivities();
            }
          });
          // await scheduleNotifications(userID);
          setState(() {
            _selectedDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
            // scheduleNotifications(userID);
          });
        },
        elevation: 10.0,
        backgroundColor: const Color.fromARGB(255, 3, 0, 66),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
