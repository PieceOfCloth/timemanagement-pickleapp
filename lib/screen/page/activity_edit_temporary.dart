// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:pickleapp/screen/components/input_file.dart';
import 'package:pickleapp/screen/components/input_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/screen/class/add_activity_list.dart';
import 'package:pickleapp/screen/class/categories.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/theme.dart';

class ActivityEditTemporaries extends StatefulWidget {
  final AddActivityList activity;
  const ActivityEditTemporaries({super.key, required this.activity});

  @override
  State<ActivityEditTemporaries> createState() =>
      _ActivityEditTemporariesState();
}

class _ActivityEditTemporariesState extends State<ActivityEditTemporaries> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _tooltipDuration = GlobalKey();
  final GlobalKey _tooltipTasks = GlobalKey();
  final GlobalKey _tooltipCategory = GlobalKey();
  final GlobalKey _tooltipRepDuration = GlobalKey();
  final GlobalKey _tooltipNotif = GlobalKey();
  final GlobalKey _tooltipLoc = GlobalKey();

  bool _isContentInputOptionalVisible = false;
  bool _isContentAddCategoryVisible = false;
  bool _isContentListOfLocationVisible = false;
  bool _isContentListOfFilesVisible = false;

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // ignore: prefer_typing_uninitialized_variables
  var geoPoint;

  String? importance;
  String? urgent;
  String? category;
  String? repeatFreq;
  String address = "";
  String latitude = "";
  String longitude = "";
  String? timezoneName;
  String currentCategoryID = "";

  late TextEditingController title;
  late TextEditingController calendarDate;
  late TextEditingController startTime;
  late TextEditingController endTime;
  late TextEditingController duration;
  late TextEditingController tasks;
  TextEditingController newCat = TextEditingController();
  late TextEditingController colorA;
  late TextEditingController colorR;
  late TextEditingController colorG;
  late TextEditingController colorB;
  late TextEditingController repeatDur;
  late TextEditingController notification;
  late TextEditingController file;

  List<Category> categoryList = [];
  List<DropdownMenuItem<String>> dropdownCat = [];
  List<Files> fileList = [];

  Color currentColorCategory = const Color.fromARGB(255, 166, 204, 255);

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  String getTasksAsString() {
    return widget.activity.tasks?.map((task) => task.task).join(",") ?? "";
  }

  String? getNotificationAsString() {
    return widget.activity.notif
        ?.map((notification) => notification.minute)
        .join(".");
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Show theory infographic in a alertdialog
  void _showInfoDialogPriority(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Importance and Urgency Info",
            style: subHeaderStyleBold,
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
              child: Text(
                "Close",
                style: textStyleBold,
              ),
            ),
          ],
        );
      },
    );
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Convert hexadecimal color category to decimal argb format
  void colorToARGBCategory(String hexColor) {
    colorA.text = int.parse(hexColor.substring(0, 2), radix: 16).toString();
    colorR.text = int.parse(hexColor.substring(2, 4), radix: 16).toString();
    colorG.text = int.parse(hexColor.substring(4, 6), radix: 16).toString();
    colorB.text = int.parse(hexColor.substring(6, 8), radix: 16).toString();
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Add a new location from an existing location list
  void addLocation(String inpAddress, String latitude, String longitude) {
    setState(() {
      widget.activity.locations?.add(Locations(
        address: inpAddress,
        latitude: double.parse(latitude),
        longitude: double.parse(longitude),
      ));
    });
  }

  void removeLocation(int index) {
    setState(() {
      widget.activity.locations?.removeAt(index);
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
      PlatformFile platformFile = result.files.first;
      setState(() {
        widget.activity.files?.add(Files(
          name: platformFile.name,
          path: platformFile.path ?? "",
        ));
        print('Files: ${widget.activity.files ?? ""}');
      });
    }
  }

  void openFile(String path) {
    OpenFile.open(path);
  }

  // Remove file if user decided not to get the file
  Future<void> removeFile(int index) async {
    File file = File(widget.activity.files?[index].path ?? "");
    await file.delete();
    setState(() {
      widget.activity.files?.removeAt(index);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Add activity to temporary list of activities
  void editActivityTemporary() {
    setState(() {
      // Edit the activity with the value from controller etc.
      widget.activity.title = title.text;
      widget.activity.impType = importance;
      widget.activity.urgType = urgent;
      widget.activity.date = calendarDate.text;
      widget.activity.strTime = startTime.text == "" ? null : startTime.text;
      widget.activity.duration = int.parse(duration.text);
      widget.activity.tasks = tasks.text.isEmpty
          ? []
          : tasks.text
              .split(",")
              .map((task) => Tasks(task: task.trim(), status: false))
              .toList();
      widget.activity.cat = category;
      widget.activity.rptIntv = repeatFreq;
      widget.activity.rptDur =
          repeatFreq == "Never" ? null : int.parse(repeatDur.text);
      widget.activity.notif =
          notification.text.isEmpty || notification.text == ""
              ? []
              : notification.text
                  .split(".")
                  .map((minute) => Notifications(minute: int.parse(minute)))
                  .toList();

      print(widget.activity);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            "Successfully edit temporary activity. Check your activity cart above."),
      ),
    );
    FocusScope.of(context).unfocus();
    Navigator.pop(context, widget.activity);
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Change format time to yyyy-MM-dd
  String formattedActivityDateOnly(String inptTime) {
    try {
      DateTime time = DateTime.parse(inptTime);

      DateFormat formatter = DateFormat("yyyy-MM-dd");

      String formattedTime = formatter.format(time);

      return formattedTime;
    } catch (e) {
      print("Error formatting date: $e");
      return "";
    }
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(String inptTime) {
    DateTime time = DateTime.parse(inptTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  String totalDuration(String start, String end) {
    DateTime startTime = DateTime.parse(start);
    DateTime endTime = DateTime.parse(end);

    Duration difference = endTime.difference(startTime);
    int totalMinutes = difference.inMinutes;

    return totalMinutes.toString();
  }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A new category is successfully added"),
        ),
      );

      setState(() {
        newCat.clear();
      });
    } catch (e) {
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

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    getCategoryData();
    print(widget.activity.toString());

    setState(() {
      String repDurText = widget.activity.rptDur != null
          ? widget.activity.rptDur.toString()
          : "";
      print(repDurText);

      title = TextEditingController(text: widget.activity.title);
      String formattedDate = widget.activity.date;
      calendarDate = TextEditingController(text: formattedDate);
      startTime = TextEditingController(text: widget.activity.strTime);
      duration =
          TextEditingController(text: widget.activity.duration.toString());
      importance = widget.activity.impType;
      urgent = widget.activity.urgType;
      tasks = TextEditingController(text: getTasksAsString());
      category = widget.activity.cat;
      repeatFreq = widget.activity.rptIntv;
      repeatDur = TextEditingController(text: repDurText);
      notification = TextEditingController(text: getNotificationAsString());
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss the keyboard by unfocusing the current focus node
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit Activity',
            style: subHeaderStyleBold,
          ),
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
                  InputText(
                    title: "Activity Title",
                    placeholder: "Enter your activity title here",
                    cont: title,
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
                                    style: textStyle,
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
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonFormField(
                                isExpanded: true,
                                value: importance,
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
                                    importance = v;
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
                                    style: textStyle,
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
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
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
                        style: textStyle,
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
                            });
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                          ),
                          alignment: Alignment.centerLeft,
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
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
                              style: textStyle,
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
                                height: 50,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
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
                                        decoration: InputDecoration(
                                          hintText:
                                              "When do you want to start?",
                                          hintStyle: textStyleGrey,
                                        ),
                                        // validator: (v) {
                                        //   if (v == null || v.isEmpty) {
                                        //     return 'Opps, You need to fill this';
                                        //   } else {
                                        //     return null;
                                        //   }
                                        // },
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
                                    style: textStyle,
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
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
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
                                      onChanged: (v) {},
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
                                    style: textStyle,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
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
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
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
                                decoration: InputDecoration(
                                  hintText: "Enter your tasks if you have",
                                  hintStyle: textStyleGrey,
                                ),
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
                                    style: textStyle,
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
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                value: category,
                                hint: Text(
                                  "Choose any category that fit to your activity",
                                  style: textStyleGrey,
                                ),
                                items: dropdownCat,
                                onChanged: (v) {
                                  setState(() {
                                    category = v;
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
                                          title: Text(
                                            'Pick a color',
                                            style: subHeaderStyleBold,
                                          ),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              color: currentColorCategory,
                                              onColorChanged: (Color color) {
                                                setState(() =>
                                                    currentColorCategory =
                                                        color);
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
                                                    .pop(currentColorCategory);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    setState(() =>
                                        currentColorCategory = selectedColor);
                                    String argbCode = ColorTools.colorCode(
                                      currentColorCategory,
                                    );
                                    colorToARGBCategory(argbCode);
                                    print(
                                        'ARGB Code: (${colorA.text}, ${colorR.text}, ${colorG.text}, ${colorB.text})');
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
                                      color: currentColorCategory,
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
                                      style: textStyle,
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
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
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
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Enter your new category (eg: sports, studies, etc)",
                                                hintStyle: textStyleGrey,
                                              ),
                                              controller: newCat,
                                              onChanged: (v) {
                                                print(newCat.text);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: GestureDetector(
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
                                            child: Container(
                                              alignment: Alignment.center,
                                              width: double.infinity,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                color: const Color.fromARGB(
                                                    255, 3, 0, 66),
                                              ),
                                              child: Text(
                                                'Add',
                                                style: textStyleBoldWhite,
                                              ),
                                            ),
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
                                    style: textStyle,
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
                                    height: 50,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: DropdownButton(
                                      isExpanded: true,
                                      value: repeatFreq,
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
                                          repeatFreq = v;
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
                                          style: textStyle,
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
                                    height: 50,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: TextFormField(
                                      autofocus: false,
                                      enabled:
                                          repeatFreq == "Never" ? false : true,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      decoration: InputDecoration(
                                        hintText:
                                            "How long do you want to repeat it?",
                                        hintStyle: textStyleGrey,
                                      ),
                                      controller: repeatDur,
                                      onFieldSubmitted: (v) {
                                        setState(() {
                                          print(repeatDur.text);
                                        });
                                      },
                                      validator: (v) {
                                        if (repeatFreq != "Never" && v == "") {
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
                                    style: textStyle,
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
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
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
                                decoration: InputDecoration(
                                  hintText:
                                      "Set time notification in a minutes",
                                  hintStyle: textStyleGrey,
                                ),
                                controller: notification,
                                onChanged: (value) {
                                  // addNotification(value);
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
                                    style: textStyle,
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
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
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
                                        latitude = geoPoint.latitude.toString();
                                        longitude =
                                            geoPoint.longitude.toString();
                                        address =
                                            "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";

                                        addLocation(
                                            address, latitude, longitude);
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
                            height: (widget.activity.locations?.isEmpty ?? true)
                                ? 50
                                : 100,
                            padding:
                                (widget.activity.locations?.isEmpty ?? true)
                                    ? const EdgeInsets.all(10)
                                    : const EdgeInsets.only(
                                        left: 5,
                                        right: 5,
                                      ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15)),
                            child: (widget.activity.locations?.isEmpty ?? true)
                                ? Text(
                                    "There are no locations",
                                    style: textStyle,
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: List.generate(
                                        widget.activity.locations?.length ?? 0,
                                        (index) {
                                          return ListTile(
                                            title: GestureDetector(
                                              onTap: () async {
                                                openGoogleMaps(
                                                  widget
                                                          .activity
                                                          .locations?[index]
                                                          .latitude ??
                                                      0.0,
                                                  widget
                                                          .activity
                                                          .locations?[index]
                                                          .longitude ??
                                                      0.0,
                                                );
                                              },
                                              child: Text(
                                                widget
                                                        .activity
                                                        .locations?[index]
                                                        .address ??
                                                    "",
                                                style: textStyle,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                removeLocation(index);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Location removed'),
                                                  ),
                                                );
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
                            height: (widget.activity.files?.isEmpty ?? true)
                                ? 50
                                : 100,
                            padding: (widget.activity.files?.isEmpty ?? true)
                                ? const EdgeInsets.all(10)
                                : const EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15)),
                            child: (widget.activity.files?.isEmpty ?? true)
                                ? Text(
                                    "There are no attachment files",
                                    style: textStyle,
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: List.generate(
                                        widget.activity.files?.length ?? 0,
                                        (index) {
                                          return ListTile(
                                            title: GestureDetector(
                                              onTap: () {
                                                OpenFile.open(widget.activity
                                                        .files?[index].path ??
                                                    "");
                                              },
                                              child: Text(
                                                widget.activity.files?[index]
                                                        .name ??
                                                    "",
                                                style: textStyle,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                removeFile(index);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content:
                                                        Text('File removed'),
                                                  ),
                                                );
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

                        const SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  // Button Add
                  GestureDetector(
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
                        editActivityTemporary();
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color.fromARGB(255, 3, 0, 66),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ), // Logout icon
                          const SizedBox(
                              width: 8.0), // Space between icon and text
                          Text(
                            "Edit this Activity",
                            style: textStyleBoldWhite,
                          ),
                        ],
                      ),
                    ),
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
