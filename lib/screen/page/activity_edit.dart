import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:pickleapp/screen/components/button_white.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/screen/class/addActivityList.dart';
import 'package:pickleapp/screen/class/categories.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/timezone.dart';
import 'package:pickleapp/screen/components/input_file.dart';
import 'package:pickleapp/theme.dart';

class ActivityEdits extends StatefulWidget {
  final AddActivityList activity;
  final String userID;
  const ActivityEdits(
      {super.key, required this.activity, required this.userID});

  @override
  State<ActivityEdits> createState() => _ActivityEditsState();
}

class _ActivityEditsState extends State<ActivityEdits> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _tooltipDuration = GlobalKey();
  final GlobalKey _tooltipTasks = GlobalKey();
  final GlobalKey _tooltipCategory = GlobalKey();
  final GlobalKey _tooltipRepDuration = GlobalKey();
  final GlobalKey _tooltipNotif = GlobalKey();
  final GlobalKey _tooltipLoc = GlobalKey();
  final GlobalKey _tooltipTimezone = GlobalKey();

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

  Color currentColorCategory = const Color.fromARGB(255, 166, 204, 255);

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  String getTasksAsString() {
    return widget.activity.tasks?.map((task) => task.task).join(",") ?? "";
  }

  String getNotificationAsString() {
    return widget.activity.notif
            ?.map((notification) => notification.minute)
            .join(".") ??
        "";
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
      widget.activity.locations!.add(Locations(
        address: inpAddress,
        latitude: double.parse(latitude),
        longitude: double.parse(longitude),
      ));
    });
  }

  void removeLocation(int index) {
    setState(() {
      widget.activity.locations!.removeAt(index);
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
          widget.activity.files!.add(Files(
            name: fileName,
            path: newPath,
          ));
        });
      }
    }
  }

  void removeFile(int index) {
    setState(() {
      widget.activity.files!.removeAt(index);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

// Add activity to temporary list of activities
  void editActivity() {
    setState(() {
      // Edit the activity with the value from controller etc.
      widget.activity.title = title.text;
      widget.activity.imp_type = importance;
      widget.activity.urg_type = urgent;
      widget.activity.date = calendarDate.text;
      widget.activity.str_time = startTime.text;
      widget.activity.timezone = timezoneName ?? "Asia/Jakarta";
      widget.activity.duration = int.parse(duration.text);
      widget.activity.tasks = tasks.text.isEmpty
          ? [] // If tasks is empty, set it to an empty list
          : tasks.text
              .split(",")
              .map((task) => Tasks(
                  task: task
                      .trim(), // Trim removes any leading/trailing whitespace
                  status: false)) // Set status to false for all tasks
              .toList();
      widget.activity.cat = category;
      widget.activity.rpt_intv = repeatFreq;
      widget.activity.rpt_dur =
          repeatFreq == "Never" ? null : int.parse(repeatDur.text);
      widget.activity.notif =
          notification.text.isEmpty || notification.text == ""
              ? []
              : notification.text
                  .split(".")
                  .map((minute) => Notifications(minute: int.parse(minute)))
                  .toList();

      // ignore: avoid_print
      print(widget.activity);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Read Category Data
  Future<void> getCategoryData() async {
    QuerySnapshot data = await FirebaseFirestore.instance
        .collection('categories')
        .where('userId', isEqualTo: widget.userID)
        .get();

    List<DropdownMenuItem<String>> items = [];

    for (var element in data.docs) {
      String catTitle = element['title'];

      items.add(DropdownMenuItem(
        value: element.id,
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

  // Read Current Category
  // Future<void> getCurrentCategoryData() async {
  //   String s = widget.activity.cat ?? "";

  //   DocumentSnapshot data =
  //       await FirebaseFirestore.instance.collection('categories').doc(s).get();

  //   List<DropdownMenuItem<String>> items = [];

  //   data.docs.forEach((element) {
  //     String catTitle = element['title'];

  //     items.add(DropdownMenuItem(
  //       value: element.id,
  //       child: Text(catTitle),
  //     ));
  //   });

  //   setState(() {
  //     dropdownCat = items;
  //   });
  // }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    getCategoryData();

    String repDurText = widget.activity.rpt_dur != null &&
            widget.activity.rpt_dur.toString() != "null"
        ? widget.activity.rpt_dur.toString()
        : "";

    title = TextEditingController(text: widget.activity.title);
    calendarDate = TextEditingController(text: widget.activity.date);
    startTime = TextEditingController(text: widget.activity.str_time);
    duration = TextEditingController(text: widget.activity.duration.toString());
    importance = widget.activity.imp_type;
    urgent = widget.activity.urg_type;
    tasks = TextEditingController(text: getTasksAsString());
    category = widget.activity.cat;
    repeatFreq = widget.activity.rpt_intv;
    repeatDur = TextEditingController(text: repDurText);
    notification = TextEditingController(text: getNotificationAsString());
    timezoneName = widget.activity.timezone;
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
            style: screenTitleStyle,
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
                          controller: title,
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
                              height: 40,
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
                              height: 40,
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
                              calendarDate.text =
                                  value.toString().substring(0, 10);
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
                                    style: subHeaderStyleGrey,
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
                                          title: const Text('Pick a color'),
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
                                    // ignore: avoid_print
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
                                              onChanged: (v) {
                                                // ignore: avoid_print
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
                                          child: MyButtonWhite(
                                            label: "Add",
                                            onTap: () {
                                              if (newCat.text == "") {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Please fill the category name :)')));
                                              } else {
                                                // addNewCategory();
                                                newCat.clear;
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
                                          repeatFreq == "Never" ? false : true,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      // textCapitalization: TextCapitalization.sentences,
                                      style: textStyle,
                                      decoration: InputDecoration(
                                        hintText:
                                            "How long do you want to repeat it?",
                                        hintStyle: textStyleGrey,
                                      ),
                                      controller: repeatDur,
                                      onFieldSubmitted: (v) {
                                        setState(() {
                                          // ignore: avoid_print
                                          print(repeatDur.text);
                                        });
                                      },
                                      validator: (v) {
                                        // ignore: unrelated_type_equality_checks
                                        if (repeatDur != "Never" && v == null) {
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
                            height: widget.activity.locations?.isEmpty ?? true
                                ? 50
                                : 100,
                            padding: widget.activity.locations?.isEmpty ?? true
                                ? const EdgeInsets.all(10)
                                : const EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: widget.activity.locations?.isEmpty ?? true
                                ? Text(
                                    "There are no activity locations",
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
                                                      .locations![index]
                                                      .latitude,
                                                  widget
                                                      .activity
                                                      .locations![index]
                                                      .longitude,
                                                );
                                              },
                                              child: Text(widget.activity
                                                  .locations![index].address),
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
                            height: widget.activity.files?.isEmpty ?? true
                                ? 50
                                : 100,
                            padding: widget.activity.files?.isEmpty ?? true
                                ? const EdgeInsets.all(10)
                                : const EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: widget.activity.files?.isEmpty ?? true
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
                                                    .files![index].path);
                                              },
                                              child: Text(widget
                                                  .activity.files![index].name),
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
                                items: timezone.map((time) {
                                  return DropdownMenuItem(
                                    value: time.name,
                                    child: Text(
                                      time.name,
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
                        editActivity();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Successfully edit temporary activity. Check your activity cart above."),
                          ),
                        );
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context, widget.activity);
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
