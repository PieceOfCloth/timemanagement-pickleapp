import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
import 'package:pickleapp/auth.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:pickleapp/screen/components/button_white.dart';
// import 'package:pickleapp/screen/page/timezones.dart';
import 'package:pickleapp/theme.dart';
import 'package:pickleapp/screen/components/input_file.dart';
// import 'package:pickleapp/screen/class/categories.dart';
import 'package:pickleapp/screen/class/addActivityList.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/timezone.dart';
import 'package:pickleapp/screen/page/activity_cart.dart';

class AddActivities extends StatefulWidget {
  const AddActivities({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddActivitiesState createState() => _AddActivitiesState();
}

class _AddActivitiesState extends State<AddActivities> {
  // ignore: prefer_typing_uninitialized_variables
  var geoPoint;
  String loc = "";
  String lat = "";
  String long = "";

  Color currentColor = Color.fromARGB(255, 166, 204, 255);

  final GlobalKey _tooltipTasks = GlobalKey();
  final GlobalKey _tooltipCategory = GlobalKey();
  final GlobalKey _tooltipDuration = GlobalKey();
  final GlobalKey _tooltipRepDuration = GlobalKey();
  final GlobalKey _tooltipNotif = GlobalKey();
  final GlobalKey _tooltipLoc = GlobalKey();
  final GlobalKey _tooltipTimezone = GlobalKey();

  final _formKey = GlobalKey<FormState>();
  final logger = Logger();

  bool _isContentAddCategoryVisible = false;
  bool _isContentInputOptionalVisible = false;
  bool _isContentListOfFilesVisible = false;
  bool _isContentListOfLocationVisible = false;
  // bool _isCheckedAlgorithm = false;
  final bool _isCheckedTaskStatus = false;

  List<String> Cs = [];
  List<Timezones> Ts = [];
  List<Files> files = [];
  List<Tasks> taskList = [];
  List<Notifications> notificationList = [];
  List<Locations> locations = [];
  List<AddActivityList> temporaryAct = [];
  List<DropdownMenuItem<String>> dropdownCat = [];
  List<String> timeZoneNames = [];

  TextEditingController actTitle = TextEditingController();
  TextEditingController calendarDate = TextEditingController();
  TextEditingController rptDur = TextEditingController();
  TextEditingController notif = TextEditingController();
  TextEditingController startTime = TextEditingController();
  TextEditingController duration = TextEditingController();
  TextEditingController tasks = TextEditingController();
  TextEditingController newCat = TextEditingController();
  TextEditingController file = TextEditingController();
  TextEditingController colorA = TextEditingController();
  TextEditingController colorR = TextEditingController();
  TextEditingController colorG = TextEditingController();
  TextEditingController colorB = TextEditingController();

  String? important;
  String? urgent;
  String? catID;
  String? timezoneName = "Asia/Jakarta";
  String? rptFreq = "Never";

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Convert hexadecimal color to decimal argb format
  void colorToARGB(String hexColor) {
    colorA.text = int.parse(hexColor.substring(0, 2), radix: 16).toString();
    colorR.text = int.parse(hexColor.substring(2, 4), radix: 16).toString();
    colorG.text = int.parse(hexColor.substring(4, 6), radix: 16).toString();
    colorB.text = int.parse(hexColor.substring(6, 8), radix: 16).toString();
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // void addNewCategory() async {
  //   final response = await http.post(
  //     Uri.parse("http://192.168.1.13:8012/picklePHP/addCategory.php"),
  //     body: {
  //       'title': newCat.text,
  //       'colorA': colorA.text,
  //       'colorR': colorR.text,
  //       'colorG': colorG.text,
  //       'colorB': colorB.text,
  //     },
  //   );
  //   if (response.statusCode == 200) {
  //     print(response.body);
  //     Map json = jsonDecode(response.body);
  //     if (json['result'] == 'success') {
  //       if (!mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text(
  //                 'Not added successfully, check your connection please :)')));
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('New activity categories have been added')));
  //         newCat.clear();
  //         currentColor = const Color.fromARGB(255, 166, 204, 255);
  //         bacaData();
  //       }
  //     }
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Get data category from database
  // Future<String> fetchDataCategory() async {
  //   final response = await http.post(
  //       Uri.parse("http://192.168.1.13:8012/picklePHP/category.php"),
  //       body: {
  //         /*'email': active_user,*/
  //       });
  //   if (response.statusCode == 200) {
  //     return response.body;
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }

  // Convert it from JSON to list of Activity Category
  // bacaData() {
  //   Cs.clear();
  //   Future<String> dataCategory = fetchDataCategory();
  //   dataCategory.then((value) {
  //     setState(() {
  //       Map json = jsonDecode(value);
  //       if (json['dataCategory'] != null || json['dataCategory'].length > 0) {
  //         for (var cat in json['dataCategory']) {
  //           Category c = Category.fromJson(cat);
  //           Cs.add(c);
  //         }
  //       }
  //     });
  //   });
  // }

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
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  void addTask(String input, bool? status) {
    List<String> taskNames = input.split(',');
    List<Tasks> newTasks = [];

    for (String taskName in taskNames) {
      newTasks.add(Tasks(
        task: taskName.trim(),
        status: input.isEmpty ? null : status ?? false,
      )); // Trim removes any leading/trailing whitespace
    }

    setState(() {
      taskList = newTasks;
      // ignore: avoid_print
      print('Tasks: $taskList');
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  void addNotification(String input) {
    List<String> notificationTimes = input.split('.');
    List<Notifications> newNotifications = [];

    for (String notificationTime in notificationTimes) {
      newNotifications.add(Notifications(
        minute: int.parse(notificationTime),
      )); // Trim removes any leading/trailing whitespace
    }

    setState(() {
      notificationList = newNotifications;
      // ignore: avoid_print
      print('Notification in a minutes before: $notificationList');
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  void addLocation(String inpAddress, String latitude, String longitude) {
    setState(() {
      locations.add(Locations(
        address: inpAddress,
        latitude: double.parse(latitude),
        longitude: double.parse(longitude),
      ));
      // ignore: avoid_print
      print('Locations: $locations');
    });
  }

  void removeLocation(int index) {
    setState(() {
      locations.removeAt(index);
    });
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

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Get the files
  Future<void> getFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'docx',
        'doc',
        'xlsx',
        'xls',
        'pptx',
        'ppt',
        'txt',
        'rtf',
        'csv',
        'png',
        'jpg',
        'jpeg',
        'gif',
      ], // Add more file types here
    );

    if (result != null) {
      for (PlatformFile file in result.files) {
        File pickedFile = File(file.path!);
        String fileName = path.basename(pickedFile.path);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;

        String newPath = path.join(appDocPath, fileName);

        await pickedFile.copy(newPath);

        setState(() {
          files.add(Files(
            name: fileName,
            path: newPath,
          ));
          // ignore: avoid_print
          print('Files: $files');
        });
      }
    }
  }

  // Remove file if user decided not to get the file
  Future<void> removeFile(int index) async {
    File file = File(files[index].path);
    await file.delete();
    setState(() {
      files.removeAt(index);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Add activity to temporary list of activities
  void addActivity() {
    AddActivityList newActivityList = AddActivityList(
      userID: userID,
      title: actTitle.text,
      imp_type: important,
      urg_type: urgent,
      date: calendarDate.text,
      str_time: startTime.text,
      duration: int.parse(duration.text),
      tasks: taskList.isEmpty ? [] : taskList,
      cat: catID,
      rpt_intv: rptFreq,
      timezone: timezoneName ?? "Asia/Jakarta",
      rpt_dur: rptDur.text.isNotEmpty ? int.parse(rptDur.text) : null,
      notif: notificationList.isEmpty ? [] : notificationList,
      locations: locations.isEmpty ? [] : locations,
      files: files.isEmpty ? [] : files,
    );

    setState(() {
      temporaryAct.add(newActivityList);
      // ignore: avoid_print
      print('Temp Act: $temporaryAct');

      // Sort the temporaryAct list by date and start time
      temporaryAct.sort((a, b) {
        // Compare dates first
        int dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) {
          return dateComparison;
        }
        // If dates are the same, compare start times
        return (a.str_time ?? '').compareTo(b.str_time ?? '');
      });

      // Delete the input form field value
      actTitle.clear();
      important = null;
      urgent = null;
      calendarDate.clear();
      startTime.clear();
      duration.clear();
      taskList = [];
      tasks.clear();
      catID = null;
      rptFreq = "Never";
      rptDur.clear();
      notificationList = [];
      notif.clear();
      locations = [];
      files = [];
      timezoneName = "Asia/Jakarta";
    });
  }

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

  // Create New Category
  Future<void> createNewCategory() async {
    try {
      // Menambahkan aktivitas baru ke koleksi "activities" dengan referensi ke UID pengguna
      await FirebaseFirestore.instance.collection('categories').add({
        'title': newCat.text,
        'color_a': int.parse(colorA.text),
        'color_r': int.parse(colorR.text),
        'color_g': int.parse(colorG.text),
        'color_b': int.parse(colorB.text),
        'userId': userID, // Referensi ke UID pengguna
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A new category is successfully added"),
        ),
      );

      setState(() {
        newCat.clear();
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add data: $e"),
        ),
      );
    }
  }

  // Read Category Data
  Future<void> getCategoryData() async {
    QuerySnapshot data = await FirebaseFirestore.instance
        .collection('categories')
        .where('userId', isEqualTo: userID)
        .get();

    List<DropdownMenuItem<String>> items = [];

    for (var element in data.docs) {
      String catTitle = element['title'];
      String categoryID = element.id;

      items.add(DropdownMenuItem(
        value: categoryID,
        child: Text(
          catTitle,
          style: textStyle,
        ),
      ));
    }

    setState(() {
      dropdownCat = items;
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    setState(() {
      timeZoneNames = tz.timeZoneDatabase.locations.keys.toList();
      // ignore: avoid_print
      print(timeZoneNames);
    });
    // bacaData();
    getCategoryData();
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  Widget build(BuildContext context) {
    // Sort the scenarios by date
    temporaryAct.sort((a, b) => a.date.compareTo(b.date));

    return GestureDetector(
      onTap: () {
        // Dismiss the keyboard by unfocusing the current focus node
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Add Activities',
            style: screenTitleStyle,
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // Open cart
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityCart(temporaryAct: temporaryAct),
                      ),
                    );
                  },
                ),
                if (temporaryAct.isNotEmpty)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        temporaryAct.length.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  // Activity Title Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Activity Title",
                        style: subHeaderStyleGrey,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        alignment: Alignment.centerLeft,
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: TextFormField(
                          autofocus: false,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          style: textStyle,
                          decoration: InputDecoration(
                            hintText: "Enter your activity title here",
                            hintStyle: textStyleGrey,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Opps, You need to fill this';
                            } else {
                              return null;
                            }
                          },
                          controller: actTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  // Activity Important n Urgent Types
                  Row(
                    children: [
                      // Important
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Importance",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showInfoDialogPriority(context);
                                    },
                                    child: const Icon(
                                      Icons.info,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 45,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonFormField(
                                isExpanded: true,
                                value: important,
                                hint: Text(
                                  "Choose one only",
                                  style: textStyleGrey,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: "Important",
                                    child: Text(
                                      "Important",
                                      style: textStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "Not Important",
                                    child: Text(
                                      "Not Important",
                                      style: textStyle,
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) {
                                  setState(() {
                                    important = v;
                                    // ignore: avoid_print
                                    print(important);
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Oops, please select an option :)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      // Urgent
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Urgency",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showInfoDialogPriority(context);
                                    },
                                    child: const Icon(
                                      Icons.info,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 45,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonFormField(
                                isExpanded: true,
                                value: urgent,
                                hint: Text(
                                  "Choose one only",
                                  style: textStyleGrey,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: "Urgent",
                                    child: Text(
                                      "Urgent",
                                      style: textStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "Not Urgent",
                                    child: Text(
                                      "Not Urgent",
                                      style: textStyle,
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) {
                                  setState(() {
                                    urgent = v;
                                    // ignore: avoid_print
                                    print(urgent);
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Oops, please select an option :)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  // Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date",
                        style: subHeaderStyleGrey,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2100))
                              .then((value) {
                            setState(() {
                              Timestamp date = Timestamp.fromDate(DateTime(
                                value!.year,
                                value.month,
                                value.day,
                              ));
                              calendarDate.text =
                                  date.toDate().toString().substring(0, 10);
                              // ignore: avoid_print
                              print(calendarDate.text);
                            });
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                          ),
                          alignment: Alignment.centerLeft,
                          height: 40,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: TextFormField(
                                  autofocus: false,
                                  readOnly: true,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: textStyle,
                                  decoration: InputDecoration(
                                    hintText: "Choose your date",
                                    hintStyle: textStyleGrey,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Opps, You need to fill this';
                                    } else {
                                      return null;
                                    }
                                  },
                                  controller: calendarDate,
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              const Expanded(
                                flex: 2,
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.grey,
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
                  // Start time n Duration
                  Row(
                    children: [
                      // Start time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Start Time",
                              style: subHeaderStyleGrey,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    setState(() {
                                      // Convert selectedTime to AM/PM format
                                      String period =
                                          selectedTime.period == DayPeriod.am
                                              ? 'AM'
                                              : 'PM';
                                      // Extract hours and minutes
                                      int hours = selectedTime.hourOfPeriod;
                                      int minutes = selectedTime.minute;
                                      // Format the time as a string
                                      String formattedTime =
                                          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
                                      // Update the text field with the selected time
                                      startTime.text = formattedTime;
                                      // ignore: avoid_print
                                      print(startTime.text);
                                    });
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                ),
                                alignment: Alignment.centerLeft,
                                height: 40,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: TextFormField(
                                        autofocus: false,
                                        readOnly: true,
                                        keyboardType: TextInputType.text,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        style: textStyle,
                                        decoration: InputDecoration(
                                          hintText:
                                              "When do you want to start?",
                                          hintStyle: textStyleGrey,
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Opps, You need to fill this';
                                          } else {
                                            return null;
                                          }
                                        },
                                        controller: startTime,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    const Expanded(
                                      flex: 2,
                                      child: Icon(
                                        Icons.access_time,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      // Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Duration",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                //Tambah informasi (input in a minute)
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    key: _tooltipDuration,
                                    margin: const EdgeInsets.only(
                                      left: 80,
                                      right: 20,
                                    ),
                                    message:
                                        "Please enter the duration in minutes (E.g. input '13' means for 13 minutes)",
                                    child: GestureDetector(
                                      onTap: () {
                                        final dynamic tooltip =
                                            _tooltipDuration.currentState;
                                        tooltip.ensureTooltipVisible();
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: TextFormField(
                                      autofocus: false,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]')),
                                      ],
                                      style: textStyle,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Enter your duration plan (in a minutes)",
                                        hintStyle: textStyleGrey,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Opps, You need to fill this';
                                        } else {
                                          return null;
                                        }
                                      },
                                      controller: duration,
                                      onChanged: (v) {
                                        // ignore: avoid_print
                                        print(duration.text);
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Icon(
                                      Icons.timer_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  // Input optional
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isContentInputOptionalVisible =
                            !_isContentInputOptionalVisible;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Colors.grey,
                              height: 36,
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Input Optional",
                            style: textStyleGrey,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          const Expanded(
                            child: Divider(
                              color: Colors.grey,
                              height: 36,
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Icon(
                            _isContentInputOptionalVisible
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  // Input optional - content
                  Visibility(
                    visible: _isContentInputOptionalVisible,
                    child: Column(
                      children: [
                        // Tasks Input
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Tasks",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                // Information = if user have more than 1 task user delimeter please like (,)
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    key: _tooltipTasks,
                                    margin: const EdgeInsets.only(
                                      left: 40,
                                      right: 20,
                                    ),
                                    message:
                                        "If you want to enter more than one task. please use the comma (,) separator (E.g. buying eggs, breaking eggs)",
                                    child: GestureDetector(
                                      onTap: () {
                                        final dynamic tooltip =
                                            _tooltipTasks.currentState;
                                        tooltip.ensureTooltipVisible();
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              child: TextFormField(
                                autofocus: false,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: textStyle,
                                decoration: InputDecoration(
                                  hintText: "Enter your tasks if you have",
                                  hintStyle: textStyleGrey,
                                ),
                                onChanged: (value) {
                                  addTask(value, _isCheckedTaskStatus);
                                },
                                controller: tasks,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Combo Category
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Category",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    key: _tooltipCategory,
                                    margin: const EdgeInsets.only(
                                      left: 80,
                                      right: 20,
                                    ),
                                    message:
                                        "Please enter your activity into the category you want (E.g. Sprots or College Activities)",
                                    child: GestureDetector(
                                      onTap: () {
                                        final dynamic tooltip =
                                            _tooltipCategory.currentState;
                                        tooltip.ensureTooltipVisible();
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                value: catID,
                                hint: Text(
                                  "Choose any category that fit to your activity",
                                  style: textStyleGrey,
                                ),
                                items: dropdownCat,
                                onChanged: (v) {
                                  setState(() {
                                    catID = v;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Add Activity Category and Color - Title (Hide n show)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isContentAddCategoryVisible =
                                  !_isContentAddCategoryVisible;
                            });
                          },
                          child: Container(
                            alignment: Alignment.centerRight,
                            width: double.infinity,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 36,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Didn't find any category?",
                                  style: textStyleGrey,
                                ),
                                Text(
                                  " Add a new one",
                                  style: textStyle,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 36,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  _isContentAddCategoryVisible
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Add Activity Category and Color - Content (Hide n show)
                        Visibility(
                          visible: _isContentAddCategoryVisible,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () async {
                                    Color selectedColor = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Pick a color'),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              color: currentColor,
                                              onColorChanged: (Color color) {
                                                setState(
                                                    () => currentColor = color);
                                              },
                                              width: 40,
                                              height: 100,
                                              borderRadius: 10,
                                              heading: Text(
                                                'Select color',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall,
                                              ),
                                              pickersEnabled: const <ColorPickerType,
                                                  bool>{
                                                ColorPickerType.both: false,
                                                ColorPickerType.primary: true,
                                                ColorPickerType.accent: false,
                                                ColorPickerType.bw: false,
                                                ColorPickerType.custom: false,
                                                ColorPickerType.wheel: false,
                                              },
                                            ),
                                          ),
                                          actions: <Widget>[
                                            MyButtonCalmBlue(
                                              label: "Done",
                                              onTap: () {
                                                Navigator.of(context)
                                                    .pop(currentColor);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    // ignore: unnecessary_null_comparison
                                    if (selectedColor != null) {
                                      setState(
                                          () => currentColor = selectedColor);
                                      String argbCode = ColorTools.colorCode(
                                        currentColor,
                                      );
                                      colorToARGB(argbCode);
                                      // ignore: avoid_print
                                      print(
                                          'ARGB Code: (${colorA.text}, ${colorR.text}, ${colorG.text}, ${colorB.text})');
                                    }
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                      color: currentColor,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Category",
                                      style: subHeaderStyleGrey,
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Container(
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                              right: 10,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: TextFormField(
                                              autofocus: false,
                                              keyboardType: TextInputType.text,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              style: textStyle,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Enter your new category (eg: sports, studies, etc)",
                                                hintStyle: textStyleGrey,
                                              ),
                                              controller: newCat,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: MyButtonWhite(
                                            label: "Add",
                                            onTap: () {
                                              if (newCat.text == "") {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Please fill the category name :)')));
                                              } else {
                                                createNewCategory();
                                                getCategoryData();
                                              }
                                            },
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
                        const SizedBox(
                          height: 5,
                        ),
                        // Repeat Interval n frequency
                        Row(
                          children: [
                            // Repeat Frequency
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Repeat",
                                    style: subHeaderStyleGrey,
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButton(
                                      isExpanded: true,
                                      value: rptFreq,
                                      hint: Text(
                                        "Choose one only",
                                        style: textStyleGrey,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: "Never",
                                          child: Text(
                                            "Never",
                                            style: textStyle,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Daily",
                                          child: Text(
                                            "Daily",
                                            style: textStyle,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Weekly",
                                          child: Text(
                                            "Weekly",
                                            style: textStyle,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Monthly",
                                          child: Text(
                                            "Monthly",
                                            style: textStyle,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Yearly",
                                          child: Text(
                                            "Yearly",
                                            style: textStyle,
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        setState(() {
                                          rptFreq = v;
                                          // ignore: avoid_print
                                          print(rptFreq);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            // Duration Frequent
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: Text(
                                          "Rep Duration",
                                          style: subHeaderStyleGrey,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      //Tambah informasi (How many times do you want to repeat it?)
                                      Expanded(
                                        flex: 2,
                                        child: Tooltip(
                                          key: _tooltipRepDuration,
                                          margin: const EdgeInsets.only(
                                            left: 80,
                                            right: 20,
                                          ),
                                          message:
                                              "Please enter the duration of repetition (E.g. Your repetition is daily and the duration is 2, then your activity will be repeated 2 days in a row)",
                                          child: GestureDetector(
                                            onTap: () {
                                              final dynamic tooltip =
                                                  _tooltipRepDuration
                                                      .currentState;
                                              tooltip.ensureTooltipVisible();
                                            },
                                            child: const Icon(
                                              Icons.info,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: TextFormField(
                                      autofocus: false,
                                      enabled:
                                          rptFreq == "Never" ? false : true,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      // textCapitalization: TextCapitalization.sentences,
                                      style: textStyle,
                                      decoration: InputDecoration(
                                        hintText:
                                            "How long do you want to repeat it?",
                                        hintStyle: textStyleGrey,
                                      ),
                                      controller: rptDur,
                                      onFieldSubmitted: (v) {
                                        setState(() {
                                          // ignore: avoid_print
                                          print(rptDur.text);
                                        });
                                      },
                                      validator: (v) {
                                        if (rptFreq != "Never" && v == null) {
                                          return 'Opps, You need to fill this';
                                        } else {
                                          return null;
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Ganti kayak task jadi pemisahnya pakai delimiter (,)
                        // Notification
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Notification",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                //Tambah informasi (How many times do you want to repeat it?)
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    key: _tooltipNotif,
                                    margin: const EdgeInsets.only(
                                      left: 80,
                                      right: 20,
                                    ),
                                    message:
                                        "Please set notification time in a MINUTE before activity and if you want to enter more than one notification, please use the dot (.) separator (E.g: 60. 120)",
                                    child: GestureDetector(
                                      onTap: () {
                                        final dynamic tooltip =
                                            _tooltipNotif.currentState;
                                        tooltip.ensureTooltipVisible();
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              child: TextFormField(
                                autofocus: false,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: textStyle,
                                decoration: InputDecoration(
                                  hintText:
                                      "Set time notification in a minutes",
                                  hintStyle: textStyleGrey,
                                ),
                                controller: notif,
                                onChanged: (value) {
                                  addNotification(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Activity Location
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Locations",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                //Tambah informasi (How many times do you want to repeat it?)
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    key: _tooltipLoc,
                                    margin: const EdgeInsets.only(
                                      left: 40,
                                      right: 20,
                                    ),
                                    message:
                                        "Please enter the location you want to add for",
                                    child: GestureDetector(
                                      onTap: () {
                                        final dynamic tooltip =
                                            _tooltipLoc.currentState;
                                        tooltip.ensureTooltipVisible();
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  geoPoint = await osm.showSimplePickerLocation(
                                    context: context,
                                    isDismissible: true,
                                    title: 'Add a activity location',
                                    textConfirmPicker: "Add",
                                    initPosition: osm.GeoPoint(
                                      latitude: -7.3225653,
                                      longitude: 112.7678477,
                                    ),
                                    // initCurrentUserPosition: true,
                                    zoomOption: const osm.ZoomOption(
                                      initZoom: 20,
                                    ),
                                  );

                                  if (geoPoint != null) {
                                    List<Placemark> placemarks =
                                        await placemarkFromCoordinates(
                                            geoPoint.latitude,
                                            geoPoint.longitude);
                                    if (placemarks.isNotEmpty) {
                                      Placemark placemark = placemarks[0];
                                      setState(() {
                                        lat = geoPoint.latitude.toString();
                                        long = geoPoint.longitude.toString();
                                        loc =
                                            "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
                                        // print("$loc, $lat, $long");
                                        addLocation(loc, lat, long);
                                      });
                                    }
                                  }
                                },
                                child: Text(
                                  "Click here to add new location",
                                  style: textStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // List of Locations - Title (Hide n show)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isContentListOfLocationVisible =
                                  !_isContentListOfLocationVisible;
                            });
                          },
                          child: Container(
                            alignment: Alignment.centerRight,
                            width: double.infinity,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 36,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Your activity locations",
                                  style: textStyleGrey,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 36,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  _isContentListOfLocationVisible
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // List of Locations - Content (Hide n show)
                        Visibility(
                          visible: _isContentListOfLocationVisible,
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: locations.isEmpty ? 50 : 100,
                            padding: locations.isEmpty
                                ? const EdgeInsets.all(10)
                                : const EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: locations.isEmpty
                                ? Text(
                                    "There are no activity locations",
                                    style: textStyle,
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: List.generate(
                                        locations.length,
                                        (index) {
                                          return ListTile(
                                            title: GestureDetector(
                                              onTap: () async {
                                                openGoogleMaps(
                                                  locations[index].latitude,
                                                  locations[index].longitude,
                                                );
                                              },
                                              child: Text(
                                                  locations[index].address),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  removeLocation(index),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Attach File
                        MyInputFile(
                          title: "Add Files",
                          placeholder: "attach any files do you want",
                          onTapFunct: () {
                            getFile(context);
                          },
                        ),
                        // List of files - Title (Hide n show)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isContentListOfFilesVisible =
                                  !_isContentListOfFilesVisible;
                            });
                          },
                          child: Container(
                            alignment: Alignment.centerRight,
                            width: double.infinity,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 36,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Your attachment files",
                                  style: textStyleGrey,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 36,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  _isContentListOfFilesVisible
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // List of files - Content (Hide n show)
                        Visibility(
                          visible: _isContentListOfFilesVisible,
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: files.isEmpty ? 50 : 100,
                            padding: files.isEmpty
                                ? const EdgeInsets.all(10)
                                : const EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: files.isEmpty
                                ? Text(
                                    "There are no attachment files",
                                    style: textStyle,
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: List.generate(
                                        files.length,
                                        (index) {
                                          return ListTile(
                                            title: GestureDetector(
                                              onTap: () {
                                                OpenFile.open(
                                                    files[index].path);
                                              },
                                              child: Text(files[index].name),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                removeFile(index);
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Combo Timezone
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    "Timezone",
                                    style: subHeaderStyleGrey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    key: _tooltipTimezone,
                                    margin: const EdgeInsets.only(
                                      left: 80,
                                      right: 20,
                                    ),
                                    message:
                                        "Please enter your activity timezone",
                                    child: GestureDetector(
                                      onTap: () {
                                        final dynamic tooltip =
                                            _tooltipTimezone.currentState;
                                        tooltip.ensureTooltipVisible();
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                value: timezoneName,
                                hint: Text(
                                  "Choose timezone for your activity",
                                  style: textStyleGrey,
                                ),
                                items: timeZoneNames.map((time) {
                                  return DropdownMenuItem(
                                    value: time,
                                    child: Text(
                                      time,
                                      style: textStyle,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    timezoneName = v;
                                  });
                                },
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
                  const SizedBox(
                    height: 5,
                  ),
                  // Button Add
                  MyButtonCalmBlue(
                    label: "Add A New Activity",
                    onTap: () {
                      if (_formKey.currentState != null &&
                          !_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Kindly complete all mandatory fields."),
                          ),
                        );
                        FocusScope.of(context).unfocus();
                      } else {
                        addActivity();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Successfully added temporary activity. Check your activity cart above."),
                          ),
                        );
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
