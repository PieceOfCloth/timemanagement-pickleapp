// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
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
  final GlobalKey _tooltipFile = GlobalKey();
  final GlobalKey _tooltipFixed = GlobalKey();

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
  bool? _isFixed;

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

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();
    if (permission.isGranted) {
      // Permission granted
    } else {
      // Permission denied
    }
  }

  String formattedTimes(DateTime datetime) {
    DateTime dateTime = DateTime.parse(datetime.toString());
    String formattedTime = DateFormat('hh:mm a').format(dateTime);
    return formattedTime;
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
      throw 'Tidak dapat meluncurkan: $url';
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

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(String inptTime) {
    DateTime time = DateTime.parse(inptTime);

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  DateTime formattedActivityTimeOnly1(String inptTime) {
    DateTime formattedTime = DateFormat("hh:mm a").parse(inptTime);

    return formattedTime;
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Add activity to temporary list of activities
  void editActivityTemporary() {
    setState(() {
      // Edit the activity with the value from controller etc.
      DateTime tanggal = DateFormat("yyyy-MM-dd").parse(calendarDate.text);

      DateTime waktuMulai = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
        formattedActivityTimeOnly1(startTime.text).hour,
        formattedActivityTimeOnly1(startTime.text).minute,
      );

      widget.activity.title = title.text;
      widget.activity.isFixed = _isFixed ?? widget.activity.isFixed;
      widget.activity.impType = importance;
      widget.activity.urgType = urgent;
      widget.activity.date = calendarDate.text;
      widget.activity.strTime = waktuMulai;
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
          repeatFreq == "Tidak" ? null : int.parse(repeatDur.text);
      widget.activity.notif =
          notification.text.isEmpty || notification.text == ""
              ? []
              : notification.text
                  .split(".")
                  .map((minute) => Notifications(minute: int.parse(minute)))
                  .toList();

      print(widget.activity);
    });

    FocusScope.of(context).unfocus();
    Navigator.pop(context, widget.activity);
    AlertInformation.showDialogBox(
        context: context,
        title: "Sukses Mengubah Kegiatan Sementara",
        message:
            "Kegiatan sementara yang kamu pilih telah berhasil diubah. Terima kasih.");
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
      print("Error melakukan format tanggal: $e");
      return "";
    }
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
      await FirebaseFirestore.instance.collection('kategoris').add({
        'nama': newCat.text,
        'warna_a': int.parse(colorA.text),
        'warna_r': int.parse(colorR.text),
        'warna_g': int.parse(colorG.text),
        'warna_b': int.parse(colorB.text),
        'users_id': userID, // Referensi ke UID pengguna
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kategori baru berhasil ditambahkan. Terima kasih."),
        ),
      );

      setState(() {
        newCat.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menambahkan kategori baru: $e"),
        ),
      );
    }
  }

  // Read Category Data
  Future<void> getCategoryData() async {
    QuerySnapshot data = await FirebaseFirestore.instance
        .collection('kategoris')
        .where('users_id', isEqualTo: userID)
        .get();

    List<DropdownMenuItem<String>> items = [];

    for (var element in data.docs) {
      String catTitle = element['nama'];
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

  void showPickleJarInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctxt) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Teori Pickle Jar - Pemilihan Prioritas',
                  style: subHeaderStyleBold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(ctxt).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Bola Golf (Prioritas Utama):',
                  style: textStyleBold,
                ),
                Text(
                  'Kegiatan yang penting dan mendesak.',
                  style: textStyle,
                ),
                const SizedBox(height: 8.0),
                Text(
                  '2. Kerikil (Prioritas Tinggi):',
                  style: textStyleBold,
                ),
                Text(
                  'Kegiatan yang penting tapi tidak mendesak.',
                  style: textStyle,
                ),
                const SizedBox(height: 8.0),
                Text(
                  '3. Pasir (Prioritas Sedang):',
                  style: textStyleBold,
                ),
                Text(
                  'Kegiatan yang tidak penting tapi mendesak.',
                  style: textStyle,
                ),
                const SizedBox(height: 8.0),
                Text(
                  '4. Air (Prioritas Rendah):',
                  style: textStyleBold,
                ),
                Text(
                  'Kegiatan yang tidak penting dan tidak mendesak.',
                  style: textStyle,
                ),
              ],
            ),
          ),
        );
      },
    );
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
      _isFixed = widget.activity.isFixed;
      String formattedDate = widget.activity.date;

      calendarDate = TextEditingController(text: formattedDate);
      startTime = TextEditingController(
          text: widget.activity.strTime != null
              ? formattedTimes(widget.activity.strTime!)
              : "");
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
            'Ubah Kegiatan Sementara',
            style: subHeaderStyleBold,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      // Activity Title Input
                      Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Nama kegiatan",
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
                                  width: constraints.maxWidth,
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
                                        TextCapitalization.words,
                                    // style: textStyle,
                                    decoration: InputDecoration(
                                      hintText:
                                          "Masukkan nama kegiatan kamu disini",
                                      hintStyle: textStyleGrey,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Silahkan isi nama kegiatanmu';
                                      } else {
                                        return null;
                                      }
                                    },
                                    controller: title,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Text(
                                        "Fix?",
                                        style: textStyle,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Tooltip(
                                        key: _tooltipFixed,
                                        margin: const EdgeInsets.only(
                                          left: 80,
                                          right: 20,
                                        ),
                                        message:
                                            "Waktu pada kegiatan yang fix tidak berdampak atau berubah ketika ada perubahan pada jadwal kegiatan lain.",
                                        child: GestureDetector(
                                          onTap: () {
                                            final dynamic tooltip =
                                                _tooltipFixed.currentState;
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
                                  width: constraints.maxWidth,
                                  child: Checkbox(
                                    value: _isFixed,
                                    onChanged: (value) {
                                      setState(() {
                                        _isFixed = value!;
                                        print(_isFixed);
                                      });
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
                                        "Kepentingan",
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
                                          showPickleJarInfo(context);
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
                                  width: constraints.maxWidth,
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
                                      "Pilih salah satu",
                                      style: textStyleGrey,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: "Penting",
                                        child: Text(
                                          "Penting",
                                          style: textStyle,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: "Tidak Penting",
                                        child: Text(
                                          "Tidak Penting",
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
                                        return 'Silahkan pilih salah satu';
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
                                        "Mendesak",
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
                                          showPickleJarInfo(context);
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
                                  width: constraints.maxWidth,
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
                                      "Pilih salah satu",
                                      style: textStyleGrey,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: "Mendesak",
                                        child: Text(
                                          "Mendesak",
                                          style: textStyle,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: "Tidak Mendesak",
                                        child: Text(
                                          "Tidak Mendesak",
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
                                        return 'Silahkan pilih salah satu';
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
                            "Tanggal",
                            style: textStyle,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          GestureDetector(
                            onTap: () {
                              showDatePicker(
                                      locale: const Locale("id", "ID"),
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
                              width: constraints.maxWidth,
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
                                        hintText: "Pilih tanggal kegiatanmu",
                                        hintStyle: textStyleGrey,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Silahkan isi tanggal kegiatanmu';
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
                                  "Waktu mulai",
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
                                          String period = selectedTime.period ==
                                                  DayPeriod.am
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
                                    width: constraints.maxWidth,
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
                                              hintText: "Pilih waktu mulai",
                                              hintStyle: textStyleGrey,
                                            ),
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
                                        "Durasi",
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
                                            "Silahkan untuk memberikan durasi kegiatan dalam menit (Contoh input '13' memiliki arti durasi 13 menit)",
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
                                  width: constraints.maxWidth,
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
                                                "Masukkan durasi kegiatan",
                                            hintStyle: textStyleGrey,
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Silahkan isi durasimu';
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
                          width: constraints.maxWidth,
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
                                "Input Opsional",
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
                                        "Sub tugas",
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
                                            "Jika kamu ingin memasukkan lebih dari 1 sub tugas. Silahkan gunakan tanda koma (,) sebagai pemisah (Contoh: Melihat email, Membalas email).",
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
                                  width: constraints.maxWidth,
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
                                      hintText:
                                          "Masukkan sub tugas kamu disini",
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
                                        "Kategori",
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
                                            "Silahkan pilih salah satu kategori kegiatan jika menginginkan (Contoh: Olahraga atau Proyek Kuliah).",
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
                                  width: constraints.maxWidth,
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
                                      "Silahkan pilih salah satu jika ingin",
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
                                width: constraints.maxWidth,
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
                                      "Tidak menemukan kategori?",
                                      style: textStyleGrey,
                                    ),
                                    Text(
                                      " Tambahkan",
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
                                              title: Expanded(
                                                child: Text(
                                                  'Pilih Warna Kategori Kamu',
                                                  style: subHeaderStyleBold,
                                                ),
                                              ),
                                              content: SingleChildScrollView(
                                                child: ColorPicker(
                                                  color: currentColorCategory,
                                                  onColorChanged:
                                                      (Color color) {
                                                    setState(() =>
                                                        currentColorCategory =
                                                            color);
                                                  },
                                                  width: 40,
                                                  height: 100,
                                                  borderRadius: 10,
                                                  heading: Text(
                                                    'Pilih Warna',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineSmall,
                                                  ),
                                                  pickersEnabled: const <ColorPickerType,
                                                      bool>{
                                                    ColorPickerType.both: false,
                                                    ColorPickerType.primary:
                                                        true,
                                                    ColorPickerType.accent:
                                                        false,
                                                    ColorPickerType.bw: false,
                                                    ColorPickerType.custom:
                                                        false,
                                                    ColorPickerType.wheel:
                                                        false,
                                                  },
                                                ),
                                              ),
                                              actions: <Widget>[
                                                MyButtonCalmBlue(
                                                  label: "Pilih",
                                                  onTap: () {
                                                    Navigator.of(context).pop(
                                                        currentColorCategory);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        setState(() => currentColorCategory =
                                            selectedColor);
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Nama kategori",
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
                                                  keyboardType:
                                                      TextInputType.text,
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Masukkan nama kategori baru",
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
                                              flex: 3,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (newCat.text == "") {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Silahkan isi nama kategori'),
                                                      ),
                                                    );
                                                  } else {
                                                    createNewCategory();
                                                    getCategoryData();
                                                  }
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: constraints.maxWidth,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    color: const Color.fromARGB(
                                                        255, 3, 0, 66),
                                                  ),
                                                  child: Text(
                                                    'Tambah',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ulangi",
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
                                        width: constraints.maxWidth,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: DropdownButton(
                                          isExpanded: true,
                                          value: repeatFreq,
                                          hint: Text(
                                            "Pilih salah satu",
                                            style: textStyleGrey,
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: "Tidak",
                                              child: Text(
                                                "Tidak",
                                                style: textStyle,
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "Harian",
                                              child: Text(
                                                "Harian",
                                                style: textStyle,
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "Mingguan",
                                              child: Text(
                                                "Mingguan",
                                                style: textStyle,
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "Bulanan",
                                              child: Text(
                                                "Bulanan",
                                                style: textStyle,
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "Tahunan",
                                              child: Text(
                                                "Tahunan",
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: Text(
                                              "Durasi",
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
                                                  "Silahkan masukkan durasi pengulangan (Contoh: Pengulangan harian and durasi 2, Maka kegiatanmu akan dijadwalkan selama 2 hari kedepan).",
                                              child: GestureDetector(
                                                onTap: () {
                                                  final dynamic tooltip =
                                                      _tooltipRepDuration
                                                          .currentState;
                                                  tooltip
                                                      .ensureTooltipVisible();
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
                                        width: constraints.maxWidth,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: TextFormField(
                                          autofocus: false,
                                          enabled: repeatFreq == "Tidak"
                                              ? false
                                              : true,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(),
                                          decoration: InputDecoration(
                                            hintText:
                                                "Masukkan durasi pengulangan",
                                            hintStyle: textStyleGrey,
                                          ),
                                          controller: repeatDur,
                                          onFieldSubmitted: (v) {
                                            setState(() {
                                              print(repeatDur.text);
                                            });
                                          },
                                          validator: (v) {
                                            if (repeatFreq != "Tidak" &&
                                                v == "") {
                                              return 'Silahkan isi durasi pengulangan';
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
                                        "Pengingat Kegiatan (Reminder)",
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
                                            "Silahkan untuk memasukkan pengingat waktu dalam menit. Gunakan pemisah tanda koma (,) jika ingin memasukkan lebih dari 1 reminder (Contoh: 60, 120)",
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
                                  width: constraints.maxWidth,
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
                                          "Silahkan masukkan waktu pengingat kegiatan",
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
                                        "Lokasi",
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
                                            "Silahkan masukkan lokasi yang kamu inginkan untuk melaksanakan kegiatan",
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
                                // Container(
                                //   padding: const EdgeInsets.only(
                                //     left: 10,
                                //     right: 10,
                                //   ),
                                //   alignment: Alignment.center,
                                //   width: constraints.maxWidth,
                                //   height: 50,
                                //   decoration: BoxDecoration(
                                //     border: Border.all(
                                //       color: Colors.grey,
                                //       width: 1.0,
                                //     ),
                                //     borderRadius: BorderRadius.circular(15),
                                //     color: Colors.grey[300],
                                //   ),
                                //   child: GestureDetector(
                                //     onTap: () async {
                                //       await _requestLocationPermission(); // Meminta izin lokasi sebelum menampilkan picker lokasi

                                //       if (await Permission.location.isGranted) {
                                //         geoPoint =
                                //             await osm.showSimplePickerLocation(
                                //           context: context,
                                //           isDismissible: true,
                                //           title: 'Tambah Lokasi Kegiatan',
                                //           textConfirmPicker: "Tambah",
                                //           // initPosition: osm.GeoPoint(
                                //           //   latitude: -7.3225653,
                                //           //   longitude: 112.7678477,
                                //           // ),
                                //           initCurrentUserPosition:
                                //               const osm.UserTrackingOption(
                                //             enableTracking: true,
                                //             unFollowUser: true,
                                //           ),
                                //           zoomOption: const osm.ZoomOption(
                                //             initZoom: 20,
                                //           ),
                                //         );

                                //         if (geoPoint != null) {
                                //           List<Placemark> placemarks =
                                //               await placemarkFromCoordinates(
                                //                   geoPoint.latitude,
                                //                   geoPoint.longitude);
                                //           if (placemarks.isNotEmpty) {
                                //             Placemark placemark = placemarks[0];
                                //             setState(() {
                                //               latitude =
                                //                   geoPoint.latitude.toString();
                                //               longitude =
                                //                   geoPoint.longitude.toString();
                                //               address =
                                //                   "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";

                                //               addLocation(
                                //                   address, latitude, longitude);
                                //             });
                                //           }
                                //         }
                                //       } else {
                                //         ScaffoldMessenger.of(context)
                                //             .showSnackBar(
                                //           const SnackBar(
                                //             content: Text(
                                //                 'Izin lokasi tidak diberikan'),
                                //           ),
                                //         );
                                //       }
                                //     },
                                //     child: Expanded(
                                //       child: Text(
                                //         "Click disini untuk menambahkan lokasi baru",
                                //         style: textStyle,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                                GestureDetector(
                                  onTap: () async {
                                    await _requestLocationPermission(); // Meminta izin lokasi sebelum menampilkan picker lokasi

                                    if (await Permission.location.isGranted) {
                                      geoPoint =
                                          await osm.showSimplePickerLocation(
                                        context: context,
                                        isDismissible: true,
                                        title: 'Tambah Lokasi Kegiatan',
                                        textConfirmPicker: "Tambah",
                                        // initPosition: osm.GeoPoint(
                                        //   latitude: -7.3225653,
                                        //   longitude: 112.7678477,
                                        // ),
                                        initCurrentUserPosition:
                                            const osm.UserTrackingOption(
                                          enableTracking: true,
                                          unFollowUser: true,
                                        ),
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
                                            latitude =
                                                geoPoint.latitude.toString();
                                            longitude =
                                                geoPoint.longitude.toString();
                                            address =
                                                "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";

                                            addLocation(
                                                address, latitude, longitude);
                                          });
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Izin lokasi tidak diberikan'),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: constraints.maxWidth,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.grey,
                                    ),
                                    child: // Space between icon and text
                                        Text(
                                      'Click disini untuk menambahkan lokasi baru',
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
                                width: constraints.maxWidth,
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
                                      "Lokasi kegiatan kamu",
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
                                width: constraints.maxWidth,
                                height:
                                    (widget.activity.locations?.isEmpty ?? true)
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
                                child: (widget.activity.locations?.isEmpty ??
                                        true)
                                    ? Text(
                                        "Tidak ada lokasi kegiatan",
                                        style: textStyle,
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          children: List.generate(
                                            widget.activity.locations?.length ??
                                                0,
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
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () {
                                                    removeLocation(index);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Lokasi dibatalkan'),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Text(
                                        "File Kegiatan",
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
                                        key: _tooltipFile,
                                        margin: const EdgeInsets.only(
                                          left: 40,
                                          right: 20,
                                        ),
                                        message:
                                            "Silahkan masukkan file yang kamu inginkan untuk mendukung kegiatanmu",
                                        child: GestureDetector(
                                          onTap: () {
                                            final dynamic tooltip =
                                                _tooltipFile.currentState;
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
                                GestureDetector(
                                  onTap: () {
                                    getFile(context);
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: constraints.maxWidth,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.grey,
                                    ),
                                    child: // Space between icon and text
                                        Text(
                                      'Click disini untuk menambahkan file kegiatan',
                                      style: textStyle,
                                    ),
                                  ),
                                ),
                              ],
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
                                width: constraints.maxWidth,
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
                                      "File kegiatan kamu",
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
                                width: constraints.maxWidth,
                                height: (widget.activity.files?.isEmpty ?? true)
                                    ? 50
                                    : 100,
                                padding:
                                    (widget.activity.files?.isEmpty ?? true)
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
                                        "Tidak ada file kegiatan",
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
                                                    OpenFile.open(widget
                                                            .activity
                                                            .files?[index]
                                                            .path ??
                                                        "");
                                                  },
                                                  child: Text(
                                                    widget
                                                            .activity
                                                            .files?[index]
                                                            .name ??
                                                        "",
                                                    style: textStyle,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () {
                                                    removeFile(index);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'File dibatalkan'),
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
                              height: 10,
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
                            AlertInformation.showDialogBox(
                                context: context,
                                title: "Beberapa Input Kosong",
                                message:
                                    "Terdapat beberapa input yang kosong, Mohon untuk mengisi input yang wajib. Terima kasih.");

                            FocusScope.of(context).unfocus();
                          } else {
                            if (_isFixed == true && startTime.text == "") {
                              AlertInformation.showDialogBox(
                                context: context,
                                title: "Peringatan",
                                message:
                                    "Harap mengisi waktu mulai, karena anda telah mengaktifkan fixed. Terima kasih.",
                              );
                            } else {
                              editActivityTemporary();
                            }
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: constraints.maxWidth,
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
                                "Ubah Kegiatan Ini",
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
            );
          }),
        ),
      ),
    );
  }
}
