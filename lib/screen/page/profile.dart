import 'package:flutter/material.dart';
import 'package:pickleapp/main.dart';
import 'package:pickleapp/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:pickleapp/screen/class/profile.dart';

import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:pickleapp/screen/components/button_white.dart';
import 'package:pickleapp/screen/page/edit_profile.dart';
import 'package:pickleapp/screen/page/change_password.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Profiles? Ps;

  @override
  void initState() {
    super.initState();
    bacaData();
  }

  // Logout function
  void doLogout() async {
    // ini nanti dihapus jika tidak diperlukan
    // final prefs = await SharedPreferences.getInstance();
    // prefs.remove("user_id");

    FirebaseAuth.instance.signOut();
  }

  // Get any data from database
  Future<String> fetchData() async {
    final response = await http.post(
      Uri.parse("http://192.168.1.12:8012/picklePHP/profile.php"),
      body: {
        "email": activeUser,
      },
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  bacaData() {
    fetchData().then((value) {
      Map json = jsonDecode(value);
      Ps = Profiles.fromJson(json['dataProfile']);
      setState(() {
        name = TextEditingController(text: Ps?.name ?? "");
      });
    });
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(String activityTime) {
    DateTime time = DateTime.parse(activityTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  // Get priority color based on important und urgent level
  Color formattedPriorityColor(important, urgent) {
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

  // Widget Activities
  Widget formattedListOActivities() {
    if (Ps?.activity?.isEmpty ?? true) {
      // List is empty
      return Text(
        "No activity today, Enjoy :)",
        style: subHeaderStyle,
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: (Ps?.activity ?? []).map(
                (activity) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: 5,
                    ),
                    padding: const EdgeInsets.only(
                      top: 5,
                      left: 5,
                    ),
                    width: 150,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: formattedPriorityColor(
                          activity['important_type'],
                          activity['urgent_type'],
                        ),
                        width: 3,
                      ),
                      color: Color.fromARGB(
                        activity['color_a'],
                        activity['color_r'],
                        activity['color_g'],
                        activity['color_b'],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          activity['activity_name'],
                          style: textStyle,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "${formattedActivityTimeOnly(activity['start_time'])} - ${formattedActivityTimeOnly(activity['end_time'])}",
                          style: textStyle,
                        ),
                      ],
                    ),
                  );
                },
              ).toList() ??
              [],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                  style: screenTitleStyle,
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
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1,
                        color: Color.fromARGB(255, 166, 204, 255),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.exit_to_app), // Logout icon
                        SizedBox(width: 8.0), // Space between icon and text
                        Text(
                          'Logout',
                          style: textStyle,
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
              top: 20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color.fromARGB(255, 166, 204, 255),
                      width: 1,
                    ),
                    image: DecorationImage(
                      image: AssetImage(
                          Ps?.path ?? "assets/Default_Photo_Profile.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Ps?.name ?? "Please wait...",
                      style: headerStyle,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      Ps?.email ?? "Please wait...",
                      style: subHeaderStyleGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Today Tasks Information
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(
              top: 20,
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
                  "You've Got ${Ps?.activity?.length == null ? 0 : Ps?.activity?.length} Activities Today",
                  style: headerStyle,
                ),
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
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: <Widget>[
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Reminder",
                    style: headerStyle,
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "For Today",
                    style: subHeaderStyleGrey,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                  ),
                  alignment: Alignment.center,
                  child: formattedListOActivities(),
                ),
              ],
            ),
          ),
          // Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
              top: 40,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                // Button Edit Profile
                MyButtonCalmBlue(
                  label: "Edit Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyEditProfile(
                          name: name,
                          email: Ps?.email ?? "",
                          urlPhoto: Ps?.path ?? "",
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                // Button Logout
                MyButtonWhite(
                  label: "Change Password",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyChangePassword(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController name = TextEditingController();
}
