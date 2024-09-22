// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pickleapp/auth.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:file_picker/file_picker.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/theme.dart';
import 'package:pickleapp/screen/class/add_activity_list.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
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

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();
    if (permission.isGranted) {
      // Permission granted
    } else {
      // Permission denied
    }
  }

  final GlobalKey _tooltipTasks = GlobalKey();
  final GlobalKey _tooltipCategory = GlobalKey();
  final GlobalKey _tooltipDuration = GlobalKey();
  final GlobalKey _tooltipRepDuration = GlobalKey();
  final GlobalKey _tooltipNotif = GlobalKey();
  final GlobalKey _tooltipLoc = GlobalKey();
  final GlobalKey _tooltipFile = GlobalKey();
  final GlobalKey _tooltipFixed = GlobalKey();

  final _formKey = GlobalKey<FormState>();
  final logger = Logger();

  bool _isFixed = false;
  bool _isContentAddCategoryVisible = false;
  bool _isContentInputOptionalVisible = false;
  bool _isContentListOfFilesVisible = false;
  bool _isContentListOfLocationVisible = false;
  final bool _isCheckedTaskStatus = false;

  Color currentColor = const Color.fromARGB(255, 3, 0, 66);

  List<String> cS = [];
  List<Files> files = [];
  List<Tasks> taskList = [];
  List<Notifications> notificationList = [];
  List<Locations> locations = [];
  List<AddActivityList> temporaryAct = [];
  List<DropdownMenuItem<String>> dropdownCat = [];

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
  String? catTemp;
  String? rptFreq = "Tidak";

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Convert hexadecimal color to decimal argb format
  void colorToARGB(String hexColor) {
    colorA.text = int.parse(hexColor.substring(0, 2), radix: 16).toString();
    colorR.text = int.parse(hexColor.substring(2, 4), radix: 16).toString();
    colorG.text = int.parse(hexColor.substring(4, 6), radix: 16).toString();
    colorB.text = int.parse(hexColor.substring(6, 8), radix: 16).toString();
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  void addTask(String input, bool? status) {
    List<String> taskNames = input.split(',');
    List<Tasks> newTasks = [];

    for (String taskName in taskNames) {
      newTasks.add(Tasks(
        task: taskName.trim(),
        status: input.isEmpty ? null : status ?? false,
      ));
    }

    setState(() {
      taskList = newTasks;
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
      ));
    }

    setState(() {
      notificationList = newNotifications;
      print('Notifikasi: $notificationList');
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
      throw 'Tidak bisa meluncurkan: $url';
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
        files.add(Files(
          name: platformFile.name,
          path: platformFile.path!,
        ));
        print('Files: $files');
      });
    }
  }

  void openFile(String path) {
    OpenFile.open(path);
  }

  // Remove file if user decided not to get the file
  Future<void> removeFile(int index) async {
    File file = File(files[index].path);
    await file.delete();
    setState(() {
      files.removeAt(index);
    });
  }

  // Change format time to hh:mm PM/AM
  DateTime formattedActivityTimeOnly(String inptTime) {
    DateTime formattedTime = DateFormat("hh:mm a").parse(inptTime);

    return formattedTime;
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Add activity to temporary list of activities
  void addActivity() {
    DateTime tanggal = DateFormat("yyyy-MM-dd").parse(calendarDate.text);

    DateTime waktuMulai = DateTime(
      tanggal.year,
      tanggal.month,
      tanggal.day,
      formattedActivityTimeOnly(startTime.text).hour,
      formattedActivityTimeOnly(startTime.text).minute,
    );
    AddActivityList newActivityList = AddActivityList(
      userID: userID,
      title: actTitle.text,
      impType: important,
      urgType: urgent,
      date: calendarDate.text,
      strTime: waktuMulai,
      duration: int.parse(duration.text),
      tasks: taskList.isEmpty ? [] : taskList,
      cat: catID,
      rptIntv: rptFreq,
      rptDur: rptDur.text.isNotEmpty ? int.parse(rptDur.text) : null,
      notif: notificationList.isEmpty ? [] : notificationList,
      locations: locations.isEmpty ? [] : locations,
      files: files.isEmpty ? [] : files,
      isFixed: _isFixed,
    );

    setState(() {
      temporaryAct.add(newActivityList);
      print('Temp Act: $temporaryAct');

      // Sort the temporaryAct list by date and start time
      temporaryAct.sort((a, b) {
        // Compare dates first
        int dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) {
          return dateComparison;
        }
        // If dates are the same, compare start times
        return (a.strTime!).compareTo(b.strTime!);
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
      rptFreq = "Tidak";
      rptDur.clear();
      notificationList = [];
      notif.clear();
      locations = [];
      files = [];
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

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
          content: Text("Kategori baru berhasil ditambahkan"),
        ),
      );

      setState(() {
        newCat.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal untuk menambahkan data: $e"),
        ),
      );
    }
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
      if (element['nama'] == "Lainnya") {
        catID = element.id;
      }

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
    getCategoryData();
    setState(() {});
    // bacaData();
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
            'Tambah Kegiatan',
            style: subHeaderStyleBold,
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.today_sharp),
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
                                    controller: actTitle,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonFormField(
                                    isExpanded: true,
                                    value: important,
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
                                        important = v;
                                        print(important);
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
                                    borderRadius: BorderRadius.circular(10),
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
                                        print(urgent);
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Silahkan pilih salah satu.';
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
                              width: constraints.maxWidth,
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
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        autofocus: false,
                                        readOnly: true,
                                        keyboardType: TextInputType.text,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: InputDecoration(
                                          hintText: "Pilih tanggal Kegiatanmu",
                                          hintStyle: textStyleGrey,
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Silahkan isi tanggal kegiatan';
                                          } else {
                                            return null;
                                          }
                                        },
                                        controller: calendarDate,
                                      ),
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
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: AbsorbPointer(
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
                                              validator: (value) {
                                                if (value == null &&
                                                    _isFixed == true) {
                                                  return "Silahkan isi ini";
                                                } else {
                                                  return null;
                                                }
                                              },
                                            ),
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
                                          decoration: InputDecoration(
                                            hintText: "Dalam Menit",
                                            hintStyle: textStyleGrey,
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Silahkan isi durasi kegiatan';
                                            } else {
                                              return null;
                                            }
                                          },
                                          controller: duration,
                                          onChanged: (v) {
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
                                        "Sub tugas",
                                        style: textStyle,
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
                                    decoration: InputDecoration(
                                      hintText:
                                          "Masukkan sub tugas kamu disini",
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButton(
                                    isExpanded: true,
                                    value: catID,
                                    hint: Text(
                                      "Silahkan pilih salah satu jika ingin",
                                      style: textStyleGrey,
                                    ),
                                    items: dropdownCat,
                                    onChanged: (v) {
                                      setState(() {
                                        catID = v ?? "Lainnya";
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
                                              title: Text(
                                                'Pilih Warna Kategori Kamu',
                                                style: subHeaderStyleBold,
                                              ),
                                              content: SingleChildScrollView(
                                                child: ColorPicker(
                                                  color: currentColor,
                                                  onColorChanged:
                                                      (Color color) {
                                                    setState(() =>
                                                        currentColor = color);
                                                  },
                                                  width: 50,
                                                  height: 50,
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
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .pop(currentColor);
                                                  },
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    width: constraints.maxWidth,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 3, 0, 66),
                                                    ),
                                                    child: Text(
                                                      'Pilih',
                                                      style: textStyleBoldWhite,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        // ignore: unnecessary_null_comparison
                                        if (selectedColor != null) {
                                          setState(() =>
                                              currentColor = selectedColor);
                                          String argbCode =
                                              ColorTools.colorCode(
                                            currentColor,
                                          );
                                          colorToARGB(argbCode);
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
                                                      BorderRadius.circular(10),
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
                                                        "Masukkan kategori baru",
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
                                              flex: 3,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (newCat.text == "") {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Silahkan isi nama kategori')));
                                                  } else {
                                                    createNewCategory();
                                                    getCategoryData();
                                                  }
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: constraints.maxWidth,
                                                  height: 50,
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
                                              BorderRadius.circular(10),
                                        ),
                                        child: DropdownButton(
                                          isExpanded: true,
                                          value: rptFreq,
                                          hint: Text(
                                            "Silahkan pilih salah satu",
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
                                              rptFreq = v;
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
                                              BorderRadius.circular(10),
                                        ),
                                        child: TextFormField(
                                          autofocus: false,
                                          enabled:
                                              rptFreq == "Tidak" ? false : true,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(),
                                          decoration: InputDecoration(
                                            hintText:
                                                "Masukkan durasi pengulangan",
                                            hintStyle: textStyleGrey,
                                          ),
                                          controller: rptDur,
                                          onFieldSubmitted: (v) {
                                            setState(() {
                                              print(rptDur.text);
                                            });
                                          },
                                          validator: (v) {
                                            if (rptFreq != "Tidak" && v == "") {
                                              return 'Silahkan isi durasi pengulangan kamu';
                                            } else if (v!.contains(".") ||
                                                v.contains("-")) {
                                              return 'Mohon masukkan angka saja';
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
                                        "Pengingat kegiatan (Reminder)",
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
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          "Silahkan masukkan waktu pengingat kegiatan",
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
                                //     borderRadius: BorderRadius.circular(10),
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
                                //           title: 'Tambah Lokasi',
                                //           titleStyle: subHeaderStyleBold,
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
                                //           FocusScope.of(context).unfocus();
                                //           List<Placemark> placemarks =
                                //               await placemarkFromCoordinates(
                                //                   geoPoint.latitude,
                                //                   geoPoint.longitude);
                                //           if (placemarks.isNotEmpty) {
                                //             Placemark placemark = placemarks[0];
                                //             setState(() {
                                //               lat =
                                //                   geoPoint.latitude.toString();
                                //               long =
                                //                   geoPoint.longitude.toString();
                                //               loc =
                                //                   "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
                                //               // print("$loc, $lat, $long");
                                //               addLocation(loc, lat, long);
                                //             });
                                //           }
                                //         } else {
                                //           FocusScope.of(context).unfocus();
                                //         }
                                //       } else {
                                //         ScaffoldMessenger.of(context)
                                //             .showSnackBar(
                                //           const SnackBar(
                                //               content: Text(
                                //                   'Izin lokasi tidak diberikan')),
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
                                        title: 'Tambah Lokasi',
                                        titleStyle: subHeaderStyleBold,
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
                                        FocusScope.of(context).unfocus();
                                        List<Placemark> placemarks =
                                            await placemarkFromCoordinates(
                                                geoPoint.latitude,
                                                geoPoint.longitude);
                                        if (placemarks.isNotEmpty) {
                                          Placemark placemark = placemarks[0];
                                          setState(() {
                                            lat = geoPoint.latitude.toString();
                                            long =
                                                geoPoint.longitude.toString();
                                            loc =
                                                "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
                                            // print("$loc, $lat, $long");
                                            addLocation(loc, lat, long);
                                          });
                                        }
                                      } else {
                                        FocusScope.of(context).unfocus();
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Izin lokasi tidak diberikan')),
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
                                        "Tidak ada lokasi kegiatan",
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
                                                      locations[index]
                                                          .longitude,
                                                    );
                                                  },
                                                  child: Text(
                                                      locations[index].address),
                                                ),
                                                trailing: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
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
                            // MyInputFile(
                            //   title: "File",
                            //   placeholder:
                            //       "Click disini untuk menambahkan file kegiatan",
                            //   onTapFunct: () {
                            //     getFile(context);
                            //     FocusScope.of(context).unfocus();
                            //   },
                            // ),
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
                                        "Tidak ada file kegiatan",
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
                                                    openFile(files[index].path);
                                                  },
                                                  child:
                                                      Text(files[index].name),
                                                ),
                                                trailing: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
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
                              height: 10,
                            ),
                          ],
                        ),
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
                                  "Terdapat beberapa input yang kosong, Mohon untuk mengisi input yang wajib. Terima kasih.",
                            );

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
                              addActivity();
                              _isFixed = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Sukses menambahkan kegiatan. Cek kegiatan kamu pada ikon jadwal di pojok kanan atas."),
                                ),
                              );
                            }
                            FocusScope.of(context).unfocus();
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
                                Icons.calendar_month,
                                color: Colors.white,
                              ), // Logout icon
                              const SizedBox(
                                  width: 8.0), // Space between icon and text
                              Text(
                                'Tambah Kegiatan Sementara',
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
