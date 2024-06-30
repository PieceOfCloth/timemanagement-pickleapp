import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:pickleapp/screen/page/sign_in.dart';
import 'package:pickleapp/theme.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/screen/class/profile.dart';
import 'package:pickleapp/screen/page/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pickleapp/screen/page/change_password.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ProfileClass? Ps;
  List activity = [];
  List schedule = [];
  late Future<ProfileClass?> userApp;

  // Logout function
  void doLogout() async {
    // ini nanti dihapus jika tidak diperlukan
    // final prefs = await SharedPreferences.getInstance();
    // prefs.remove("user_id");
    Provider.of<ActivityTaskToday>(context, listen: false).resetDataLoaded();

    FirebaseAuth.instance.signOut();
  }

  // // Get any data from database
  // Future<String> fetchData() async {
  //   final response = await http.post(
  //     Uri.parse("http://192.168.1.12:8012/picklePHP/profile.php"),
  //     body: {
  //       "email": activeUser,
  //     },
  //   );
  //   if (response.statusCode == 200) {
  //     return response.body;
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }

  // bacaData() {
  //   fetchData().then((value) {
  //     Map json = jsonDecode(value);
  //     Ps = ProfileClass.fromJson(json['dataProfile']);
  //     setState(() {
  //       name = TextEditingController(text: Ps?.name ?? "");
  //     });
  //   });
  // }

  Future<ProfileClass?> getProfile() async {
    List<Map<String, dynamic>> activity = [];

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();

    if (userDoc.exists) {
      var userData = userDoc.data()!;
      String imagePath = userData['path'];
      String imageUrl =
          await FirebaseStorage.instance.ref(imagePath).getDownloadURL();

      final actSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where("user_id", isEqualTo: userID)
          .get();

      if (actSnap.docs.isNotEmpty) {
        for (var doc in actSnap.docs) {
          var activityData = doc.data();
          var actID = doc.id;

          var now = DateTime.now();
          var startOfDay = DateTime(now.year, now.month, now.day);
          var endOfDay = now.add(const Duration(days: 1));

          QuerySnapshot schedSnap = await FirebaseFirestore.instance
              .collection('scheduled_activities')
              .where('actual_start_time',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('actual_start_time',
                  isLessThan: Timestamp.fromDate(endOfDay))
              .where('activities_id', isEqualTo: actID)
              .get();

          if (schedSnap.docs.isNotEmpty) {
            for (var schedDoc in schedSnap.docs) {
              var start = (schedDoc['actual_start_time'] as Timestamp).toDate();
              var end = (schedDoc['actual_end_time'] as Timestamp).toDate();

              activityData['actual_start'] = start;
              activityData['actual_end'] = end;

              activity.add(activityData);
            }
          }
        }
      }
      return ProfileClass(
        email: userData['email'],
        name: userData['name'],
        path: imageUrl,
        activity: activity,
      );
    }
    return null;
  }

  // Change format time to hh:mm PM/AM
  String getActivityTimeOnly(DateTime time) {
    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  String getPriorityCategory(String importance, String urgent) {
    if (importance == "Important" && urgent == "Urgent") {
      return "Golf";
    } else if (importance == "Important" && urgent == "Not Urgent") {
      return "Pebbles";
    } else if (importance == "Not Important" && urgent == "Urgent") {
      return "Sand";
    } else {
      return "Water";
    }
  }

  Color getPriorityColor(String priorityType) {
    if (priorityType == 'Golf') {
      return Colors.red;
    } else if (priorityType == 'Pebbles') {
      return Colors.yellow;
    } else if (priorityType == 'Sand') {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  @override
  void initState() {
    super.initState();
    // bacaData();
    userApp = getProfile();
  }

  @override
  void dispose() {
    super.dispose();
    // Perform any cleanup if necessary
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 66),
      body: FutureBuilder<ProfileClass?>(
        future: userApp,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
            ));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: GestureDetector(
                onTap: () {
                  doLogout();
                },
                child: Text(
                  'No Profiles Found',
                  style: textStyleBoldWhite,
                ),
              ),
            );
          } else {
            ProfileClass user = snapshot.data!;
            return Column(
              children: [
                // Title My Profile + Log Out
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 40,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "My Profile",
                        style: screenTitleStyleWhite,
                      ),
                      GestureDetector(
                        onTap: () {
                          doLogout();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              width: 1,
                              color: Colors.white,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.exit_to_app,
                                color: Colors.white,
                              ), // Logout icon
                              const SizedBox(
                                  width: 8.0), // Space between icon and text
                              Text(
                                'Logout',
                                style: textStyleBoldWhite,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile pict n name n email
                Container(
                  margin: const EdgeInsets.only(
                    right: 20,
                    left: 20,
                    top: 30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                          // Handle it later
                          image: DecorationImage(
                            image: NetworkImage(user.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        user.name,
                        style: headerStyleBoldWhite,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        user.email,
                        style: textStyleGrey,
                      ),
                    ],
                  ),
                ),
                // Today Tasks Information
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 30),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                              top: 10,
                              left: 20,
                              right: 20,
                            ),
                            child: Column(
                              children: [
                                const Divider(
                                  color: Colors.black,
                                  thickness: 1,
                                ),
                                Text(
                                    "You've Got ${user.activity?.length ?? 0} Activities Today",
                                    style: subHeaderStyleBold),
                                const Divider(
                                  color: Colors.black,
                                  thickness: 1,
                                ),
                              ],
                            ),
                          ),
                          // Reminder Today Tasks
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                              top: 10,
                              left: 20,
                              right: 20,
                            ),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Reminder",
                                    style: textStyleBoldGrey,
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "For Today",
                                    style: textStyleBold,
                                  ),
                                ),
                                user.activity!.isEmpty
                                    ? Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 5),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                                255, 3, 0, 6),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Expanded(
                                              flex: 2,
                                              child: Icon(
                                                Icons.info_outline_rounded,
                                                color: Color.fromARGB(
                                                    255, 3, 0, 6),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 7,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "No activity today",
                                                    style: textStyleBold,
                                                  ),
                                                  Text(
                                                    "Don't forget to start you bright day with plans, so let's plan your day :)",
                                                    style: textStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                            top: 5, bottom: 10),
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.2,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: user.activity!.map(
                                              (act) {
                                                String type =
                                                    getPriorityCategory(
                                                        act['important_type'],
                                                        act['urgent_type']);
                                                return Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.5,
                                                  height: double.infinity,
                                                  margin: const EdgeInsets.only(
                                                      right: 5),
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color:
                                                        getPriorityColor(type),
                                                    border: Border.all(
                                                        color: Colors.white),
                                                  ),
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    color: Colors.white,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          act['title'],
                                                          style:
                                                              textStyleBoldGrey,
                                                        ),
                                                        Text(
                                                          "${getActivityTimeOnly(act['actual_start'])} - ${getActivityTimeOnly(act['actual_end'])}",
                                                          style: textStyleBold,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          // Button
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                              top: 20,
                              left: 20,
                              right: 20,
                              bottom: 20,
                            ),
                            child: isLoginManual == true
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Button Edit Profile
                                      GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MyEditProfile(
                                                name: user.name,
                                                urlPhoto: user.path,
                                              ),
                                            ),
                                          );

                                          setState(() {
                                            getProfile();
                                            userApp = getProfile();
                                          });
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.42,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            color: const Color.fromARGB(
                                                255, 3, 0, 66),
                                          ),
                                          child: // Space between icon and text
                                              Text(
                                            'Edit Profile',
                                            style: textStyleBoldWhite,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      // Button Change Password
                                      GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ChangePassword(),
                                            ),
                                          ).then((result) {
                                            if (result == true) {
                                              doLogout();
                                            }
                                          });

                                          setState(() {
                                            getProfile();
                                            userApp = getProfile();
                                          });
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.42,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              width: 1,
                                              color: const Color.fromARGB(
                                                  255, 3, 0, 66),
                                            ),
                                          ),
                                          child: // Space between icon and text
                                              Text(
                                            'Change Password',
                                            style: textStyleBold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : // Button Edit Profile
                                GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MyEditProfile(
                                            name: user.name,
                                            urlPhoto: user.path,
                                          ),
                                        ),
                                      );

                                      setState(() {});
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width *
                                          0.42,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color:
                                            const Color.fromARGB(255, 3, 0, 66),
                                      ),
                                      child: // Space between icon and text
                                          Text(
                                        'Edit Profile',
                                        style: textStyleBoldWhite,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
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

  TextEditingController name = TextEditingController();
}
