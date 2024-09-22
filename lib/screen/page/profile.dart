import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/activity_list.dart';
import 'package:pickleapp/screen/class/location.dart';
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
  List<ActivityList> activitiesList = [];
  late Future<ProfileClass?> userApp;

  // Logout function
  void doLogout() async {
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
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();

    if (userDoc.exists) {
      var userData = userDoc.data()!;
      String imagePath = userData['path'];
      String imageUrl =
          await FirebaseStorage.instance.ref(imagePath).getDownloadURL();

      // Convert date string to DateTime and then to Timestamp
      DateTime dateTime = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);

      Timestamp startOfDay = Timestamp.fromDate(dateTime);
      Timestamp endOfDay =
          Timestamp.fromDate(dateTime.add(const Duration(days: 1)));

      QuerySnapshot schSnap = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where('waktu_mulai', isGreaterThanOrEqualTo: startOfDay)
          .where('waktu_mulai', isLessThan: endOfDay)
          .where("users_id", isEqualTo: userID)
          .get();

      for (var doc in schSnap.docs) {
        Timestamp actualStartTimeTimestamp = doc['waktu_mulai'];

        DateTime actualStartTime = actualStartTimeTimestamp.toDate();

        String actualStartTimeString = actualStartTime.toString();

        Timestamp actualEndTimeTimestamp = doc['waktu_akhir'];

        DateTime actualEndTime = actualEndTimeTimestamp.toDate();

        String actualEndTimeString = actualEndTime.toString();

        QuerySnapshot locQuerySnapshot = await FirebaseFirestore.instance
            .collection('lokasis')
            .where('kegiatans_id', isEqualTo: doc.id)
            .get();

        List<Locations> locations = locQuerySnapshot.docs.map((locDoc) {
          Map<String, dynamic> locData = locDoc.data() as Map<String, dynamic>;
          return Locations(
            address: locData['alamat'] as String,
            latitude: locData['latitude'] as double,
            longitude: locData['longitude'] as double,
          );
        }).toList();

        String categoriesId = doc['kategoris_id'];
        Map<String, dynamic> categoryData;
        DocumentSnapshot categoryDoc = await FirebaseFirestore.instance
            .collection('kategoris')
            .doc(categoriesId)
            .get();
        categoryData = categoryDoc.data() as Map<String, dynamic>;

        ActivityList activity = ActivityList(
          idActivity: doc.id,
          title: doc['nama'],
          startTime: actualStartTimeString,
          endTime: actualEndTimeString,
          importantType: doc['tipe_kepentingan'],
          urgentType: doc['tipe_mendesak'],
          colorA: categoryData['warna_a'],
          colorR: categoryData['warna_r'],
          colorG: categoryData['warna_g'],
          colorB: categoryData['warna_b'],
          locations: locations,
        );

        activitiesList.add(activity);
      }
      return ProfileClass(
        email: userData['email'],
        name: userData['name'],
        path: imageUrl,
        activity: activitiesList,
      );
    }
    return null;
  }

  // Change format time to hh:mm PM/AM
  String getActivityTimeOnly(String activityTime) {
    DateTime time = DateTime.parse(activityTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  String getPriorityCategory(String importance, String urgent) {
    if (importance == "Penting" && urgent == "Mendesak") {
      return "Bola Golf";
    } else if (importance == "Penting" && urgent == "Tidak Mendesak") {
      return "Kerikil";
    } else if (importance == "Tidak Penting" && urgent == "Mendesak") {
      return "Pasir";
    } else {
      return "Air";
    }
  }

  Color getPriorityColor(String priorityType) {
    if (priorityType == 'Bola Golf') {
      return Colors.red;
    } else if (priorityType == 'Kerikil') {
      return Colors.yellow;
    } else if (priorityType == 'Pasir') {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  @override
  void initState() {
    super.initState();
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
                  setState(() {
                    isLoginManual = false;
                  });
                  doLogout();
                },
                child: Text(
                  'Profil Tidak Ditemukan',
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
                        "Profil Saya",
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
                                    "Hari ini kamu memiliki ${user.activity?.length ?? 0} kegiatan",
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
                                    "Kegiatan",
                                    style: textStyleBoldGrey,
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Untuk hari ini",
                                    style: textStyleBold,
                                  ),
                                ),
                                activitiesList.isEmpty
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
                                                    "Tidak ada kegiatan untuk hari",
                                                    style: textStyleBold,
                                                  ),
                                                  Text(
                                                    "Jangan lupa untuk memulai hari cerahmu dengan rencana. Oleh karena itu ayo jadwalkan kegiatanmu.",
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
                                            children: activitiesList.map(
                                              (act) {
                                                String type =
                                                    getPriorityCategory(
                                                        act.importantType,
                                                        act.urgentType);
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
                                                        Expanded(
                                                          child: Text(
                                                            act.title,
                                                            style:
                                                                textStyleBoldGrey,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "${getActivityTimeOnly(act.startTime)} - ${getActivityTimeOnly(act.endTime)}",
                                                            style:
                                                                textStyleBold,
                                                          ),
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
                                            'Ubah Profil',
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
                                            border: Border.all(
                                              width: 1,
                                              color: const Color.fromARGB(
                                                  255, 3, 0, 66),
                                            ),
                                          ),
                                          child: // Space between icon and text
                                              Text(
                                            'Ganti Kata Sandi',
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
                                        'Ubah Profil',
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
