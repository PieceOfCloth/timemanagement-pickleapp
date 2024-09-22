// ignore_for_file: avoid_print, use_build_context_synchronously, unused_local_variable

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/activity_detail.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pickleapp/screen/class/categories.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/theme.dart';

class ActivityEditDetails extends StatefulWidget {
  final DetailActivities actDetail;
  const ActivityEditDetails({super.key, required this.actDetail});

  @override
  State<ActivityEditDetails> createState() => _ActivityEditDetailsState();
}

class _ActivityEditDetailsState extends State<ActivityEditDetails> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _tooltipTasks = GlobalKey();
  final GlobalKey _tooltipCategory = GlobalKey();
  final GlobalKey _tooltipNotif = GlobalKey();
  final GlobalKey _tooltipLoc = GlobalKey();
  final GlobalKey _tooltipFile = GlobalKey();
  final GlobalKey _tooltipFixed = GlobalKey();
  final GlobalKey _tooltipRepDuration = GlobalKey();

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
  String address = "";
  String latitude = "";
  String longitude = "";
  String? timezoneName;
  String currentCategoryID = "";
  String? repeatFreq;
  bool? _isFixed;

  late TextEditingController title;
  late TextEditingController calendarDate;
  late TextEditingController startTime;
  late TextEditingController endTime;
  late TextEditingController tasks;
  TextEditingController newCat = TextEditingController();
  late TextEditingController colorA;
  late TextEditingController repeatDur;
  late TextEditingController colorR;
  late TextEditingController colorG;
  late TextEditingController colorB;
  late TextEditingController notification;
  late TextEditingController file;

  TimeOfDay? startTime2;
  TimeOfDay? endTime2;

  List<Category> categoryList = [];
  List<DropdownMenuItem<String>> dropdownCat = [];
  List<Files> fileList = [];

  Color currentColorCategory = const Color.fromARGB(255, 166, 204, 255);

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  String getTasksAsString() {
    return widget.actDetail.tasks?.map((task) => task.task).join(",") ?? "";
  }

  String? getNotificationAsString() {
    return widget.actDetail.notif
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

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  // Convert hexadecimal color category to decimal argb format
  void colorToARGBCategory(String hexColor) {
    colorA.text = int.parse(hexColor.substring(0, 2), radix: 16).toString();
    colorR.text = int.parse(hexColor.substring(2, 4), radix: 16).toString();
    colorG.text = int.parse(hexColor.substring(4, 6), radix: 16).toString();
    colorB.text = int.parse(hexColor.substring(6, 8), radix: 16).toString();
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

  // Add a new location from an existing location list
  void addLocation(String inpAddress, String latitude, String longitude) {
    setState(() {
      widget.actDetail.locations?.add(Locations(
        address: inpAddress,
        latitude: double.parse(latitude),
        longitude: double.parse(longitude),
      ));
    });
  }

  void removeLocation(int index) {
    setState(() {
      widget.actDetail.locations?.removeAt(index);
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
        fileList.add(Files(
          name: platformFile.name,
          path: platformFile.path ?? "",
        ));
        print('Files: $fileList');
      });
    }
  }

  void openFile(String path) {
    OpenFile.open(path);
  }

  // Remove file if user decided not to get the file
  Future<void> removeFile(int index) async {
    File file = File(fileList[index].path);
    await file.delete();
    setState(() {
      fileList.removeAt(index);
    });
  }

  Future<void> fileDownload(String path, String name) async {
    try {
      String url = await FirebaseStorage.instance.ref(path).getDownloadURL();

      // Download the file to a local path
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$name');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await tempFile.create();
      final http.Client httpClient = http.Client();
      final http.Response response = await httpClient.get(Uri.parse(url));
      await tempFile.writeAsBytes(response.bodyBytes);

      setState(() {
        fileList.add(Files(name: name, path: tempFile.path));
      });

      // Open the file
      // await OpenFile.open(tempFile.path);
    } catch (e) {
      print(e);
    }
  }

  Future<void> getListFileDownloaded() async {
    for (Files file in widget.actDetail.files ?? []) {
      await fileDownload(file.path, file.name);
    }
  }

  // Change format time to yyyy-MM-dd
  String formattedActivityDateOnly(DateTime inptTime) {
    try {
      DateTime time = inptTime;

      DateFormat formatter = DateFormat("yyyy-MM-dd");

      String formattedTime = formatter.format(time);

      return formattedTime;
    } catch (e) {
      print("Error ketika melakukan format tanggal: $e");
      return "";
    }
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(DateTime inptTime) {
    DateTime time = inptTime;

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

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  Future<void> editActivitySchedule() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      bool? kegiatanIni;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('kegiatans')
          .where("kegiatans_id", isEqualTo: widget.actDetail.idAct2)
          .get();

      int it = 0;

      // Iterate through the documents
      for (var doc in snapshot.docs) {
        it += 1;
      }
      if (it > 1) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Ubah Kegiatan",
                style: subHeaderStyleBold,
              ),
              // content: Text(
              //   'Hanya kegiatan ini?',
              //   style: textStyle,
              // ),
              actions: [
                GestureDetector(
                  onTap: () async {
                    kegiatanIni = true;
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        width: 1,
                        color: const Color.fromARGB(255, 3, 0, 66),
                      ),
                    ),
                    child: // Space between icon and text
                        Text(
                      'Hanya Kegiatan Ini',
                      style: textStyleBold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    kegiatanIni = false;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 5),
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: const Color.fromARGB(255, 3, 0, 66),
                    ),
                    child: Text(
                      'Semua Kegiatan dalam series',
                      style: textStyleBoldWhite,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
      print(it);
      if (it > 1) {
        if (kegiatanIni == true) {
          DateTime start = DateFormat("yyyy-MM-dd hh:mm a")
              .parse("${calendarDate.text} ${startTime.text}");
          DateTime startDate =
              DateFormat("yyyy-MM-dd").parse(calendarDate.text);
          DateTime end = DateFormat("yyyy-MM-dd hh:mm a")
              .parse("${calendarDate.text} ${endTime.text}");

          QuerySnapshot dailyActivities = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('waktu_mulai',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('waktu_mulai',
                  isLessThan: Timestamp.fromDate(
                      startDate.add(const Duration(days: 1))))
              .get();

          for (var activityDoc in dailyActivities.docs) {
            DateTime activityStart =
                (activityDoc['waktu_mulai'] as Timestamp).toDate();
            DateTime activityEnd =
                (activityDoc['waktu_akhir'] as Timestamp).toDate();

            if (start.isBefore(activityEnd) && end.isAfter(activityStart)) {
              if (activityDoc['fixed'] == false) {
                if (activityStart.isBefore(start)) {
                  // Adjust start time if the activity starts before the new activity
                  DateTime newActivityStart =
                      start.subtract(activityEnd.difference(activityStart));
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(newActivityStart),
                    "waktu_akhir": Timestamp.fromDate(newActivityStart
                        .add(activityEnd.difference(activityStart))),
                  });
                } else {
                  // Adjust end time if the activity starts after the new activity
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(end),
                    "waktu_akhir": Timestamp.fromDate(
                        end.add(activityEnd.difference(activityStart))),
                  });
                }
              }
            }
          }

          // Jika user pilih ganti hanya untuk kegiatan ini
          await FirebaseFirestore.instance
              .collection('kegiatans')
              .doc(widget.actDetail.idAct)
              .update({
            'nama': title.text,
            "waktu_mulai": Timestamp.fromDate(start),
            "waktu_akhir": Timestamp.fromDate(end),
            'fixed': _isFixed,
            "interval_pengulangan": repeatFreq,
            "durasi_pengulangan": int.parse(repeatDur.text),
            "kategoris_id": category,
            "kegiatans_id": widget.actDetail.idAct,
            "tipe_kepentingan": importance,
            "tipe_mendesak": urgent,
          });

          QuerySnapshot overlappingActivities = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('fixed', isEqualTo: false)
              .where('waktu_mulai', isGreaterThanOrEqualTo: start)
              .where('waktu_mulai', isLessThan: end)
              .get();

          for (var overlappingDoc in overlappingActivities.docs) {
            DateTime overlappingStart =
                (overlappingDoc['waktu_mulai'] as Timestamp).toDate();
            DateTime overlappingEnd =
                (overlappingDoc['waktu_akhir'] as Timestamp).toDate();

            // Update the overlapping flexible activity
            await FirebaseFirestore.instance
                .collection('kegiatans')
                .doc(overlappingDoc.id)
                .update({
              'waktu_mulai': Timestamp.fromDate(end),
              'waktu_akhir': Timestamp.fromDate(
                  end.add(overlappingEnd.difference(overlappingStart))),
            });

            // Update any related tasks, notifications, locations, or files for the overlapping activity
            // (similar to the update process above)
          }

          QuerySnapshot taskSnap = await FirebaseFirestore.instance
              .collection('subtugass')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
              .get();

          List<String> newTask = tasks.text
              .split(',')
              .map((task) => task.trim())
              .where((task) => task.isNotEmpty)
              .toList();
          List<String> existingTask =
              taskSnap.docs.map((doc) => doc['nama'] as String).toList();

          List<DocumentSnapshot> tasksToDelete = taskSnap.docs.where((doc) {
            return !newTask.contains(doc['nama']);
          }).toList();
          List<String> tasksToAdd = newTask.where((name) {
            return !existingTask.contains(name);
          }).toList();

          for (DocumentSnapshot doc in tasksToDelete) {
            await FirebaseFirestore.instance
                .collection('subtugass')
                .doc(doc.id)
                .delete();
          }

          for (String taskName in tasksToAdd) {
            await FirebaseFirestore.instance.collection('subtugass').add({
              'nama': taskName,
              'kegiatans_id': widget.actDetail.idAct,
              'status': false,
            });
          }

          QuerySnapshot notifSnap = await FirebaseFirestore.instance
              .collection('notifikasis')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
              .get();

          for (var doc in notifSnap.docs) {
            await FirebaseFirestore.instance
                .collection('notifikasis')
                .doc(doc.id)
                .delete();
            await AwesomeNotifications().cancel(doc.id.hashCode);
          }

          List<String> newNotif = notification.text.split('.');
          print(newNotif);
          for (String notif in newNotif) {
            if (notif.isNotEmpty) {
              if (int.tryParse(notif) != null) {
                DocumentReference notify = await FirebaseFirestore.instance
                    .collection('notifikasis')
                    .add({
                  'menit_sebelum': int.parse(notif),
                  'kegiatans_id': widget.actDetail.idAct,
                });

                DateTime notiftime =
                    start.subtract(Duration(minutes: int.parse(notif)));

                await AwesomeNotifications().createNotification(
                  content: NotificationContent(
                    id: notify.id.hashCode,
                    channelKey: 'activity_reminder',
                    title: "Kegiatan Selanjutnya - ${title.text}",
                    body: "Kegiatanmu akan dimulai pada $start",
                    notificationLayout: NotificationLayout.BigText,
                    criticalAlert: true,
                    wakeUpScreen: true,
                    category: NotificationCategory.Reminder,
                  ),
                  schedule: NotificationCalendar.fromDate(
                    date: notiftime,
                    preciseAlarm: true,
                    allowWhileIdle: true,
                  ),
                );
              } else {
                throw const FormatException("Format notifikasi tidak sesuai");
              }
            }
          }

          QuerySnapshot locSnap = await FirebaseFirestore.instance
              .collection('lokasis')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
              .get();

          for (var doc in locSnap.docs) {
            await FirebaseFirestore.instance
                .collection('lokasis')
                .doc(doc.id)
                .delete();
          }

          for (Locations loc in widget.actDetail.locations ?? []) {
            await FirebaseFirestore.instance.collection('lokasis').add({
              'kegiatans_id': widget.actDetail.idAct,
              'alamat': loc.address,
              'latitude': loc.latitude,
              'longitude': loc.longitude,
            });
          }

          QuerySnapshot fileSnap1 = await FirebaseFirestore.instance
              .collection('files')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
              .get();

          for (DocumentSnapshot doc in fileSnap1.docs) {
            await FirebaseStorage.instance.ref(doc['path']).delete();

            await FirebaseFirestore.instance
                .collection('files')
                .doc(doc.id)
                .delete();
          }

          ListResult listFile = await FirebaseStorage.instance
              .ref("user_files/${widget.actDetail.idAct}")
              .listAll();

          for (Reference file in listFile.items) {
            await file.delete();
          }

          for (Files file in fileList) {
            String folder = "user_files/$userID/${widget.actDetail.idAct}";
            String filePath = "$folder/${file.name}";
            await FirebaseFirestore.instance.collection('files').add({
              'nama': file.name,
              'path': "$folder/${file.name}",
              'kegiatans_id': widget.actDetail.idAct,
            });
            await FirebaseStorage.instance
                .ref(filePath)
                .putFile(File(file.path));
          }

          for (var i = 1;
              i < (repeatFreq == "Tidak" ? 1 : int.parse(repeatDur.text));
              i++) {
            DateTime startTimeReal;
            DateTime startDateReal;
            DateTime endTimeReal;

            if (repeatFreq == "Harian") {
              startTimeReal = start.add(Duration(days: i));
              startDateReal = startDate.add(Duration(days: i));
              endTimeReal = end.add(Duration(days: i));
            } else if (repeatFreq == "Mingguan") {
              startTimeReal = start.add(Duration(days: 7 * i));
              startDateReal = startDate.add(Duration(days: 7 * i));
              endTimeReal = end.add(Duration(days: 7 * i));
            } else if (repeatFreq == "Bulanan") {
              startTimeReal = start.add(Duration(days: 30 * i));
              startDateReal = startDate.add(Duration(days: 30 * i));
              endTimeReal = end.add(Duration(days: 30 * i));
            } else if (repeatFreq == "Tahunan") {
              startTimeReal = start.add(Duration(days: 365 * i));
              startDateReal = startDate.add(Duration(days: 365 * i));
              endTimeReal = end.add(Duration(days: 365 * i));
            } else {
              startTimeReal = start;
              startDateReal = startDate;
              endTimeReal = end;
            }

            QuerySnapshot dailyActivities = await FirebaseFirestore.instance
                .collection('kegiatans')
                .where('waktu_mulai',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startDateReal))
                .where('waktu_mulai',
                    isLessThan: Timestamp.fromDate(
                        startDateReal.add(const Duration(days: 1))))
                .get();

            for (var activityDoc in dailyActivities.docs) {
              DateTime activityStart =
                  (activityDoc['waktu_mulai'] as Timestamp).toDate();
              DateTime activityEnd =
                  (activityDoc['waktu_akhir'] as Timestamp).toDate();

              if (startTimeReal.isBefore(activityEnd) &&
                  endTimeReal.isAfter(activityStart)) {
                if (activityDoc['fixed'] == false) {
                  if (activityStart.isBefore(startTimeReal)) {
                    // Adjust start time if the activity starts before the new activity
                    DateTime newActivityStart = startTimeReal
                        .subtract(activityEnd.difference(activityStart));
                    await FirebaseFirestore.instance
                        .collection('kegiatans')
                        .doc(activityDoc.id)
                        .update({
                      "waktu_mulai": Timestamp.fromDate(newActivityStart),
                      "waktu_akhir": Timestamp.fromDate(newActivityStart
                          .add(activityEnd.difference(activityStart))),
                    });
                  } else {
                    // Adjust end time if the activity starts after the new activity
                    await FirebaseFirestore.instance
                        .collection('kegiatans')
                        .doc(activityDoc.id)
                        .update({
                      "waktu_mulai": Timestamp.fromDate(endTimeReal),
                      "waktu_akhir": Timestamp.fromDate(endTimeReal
                          .add(activityEnd.difference(activityStart))),
                    });
                  }
                }
              }
            }
            // Tambahkan kegiatan baru ke dalam Firestore
            DocumentReference actID =
                await FirebaseFirestore.instance.collection('kegiatans').add({
              'nama': title.text,
              "waktu_mulai": Timestamp.fromDate(startTimeReal),
              "waktu_akhir": Timestamp.fromDate(endTimeReal),
              'fixed': _isFixed,
              "interval_pengulangan": repeatFreq,
              "durasi_pengulangan": int.parse(repeatDur.text),
              "kategoris_id": category,
              "kegiatans_id": widget.actDetail.idAct,
              "tipe_kepentingan": importance,
              "tipe_mendesak": urgent,
              "status": false,
              "users_id": userID,
            });

            List<String> newNotif = notification.text.split('.');
            for (String notif in newNotif) {
              if (notif.isNotEmpty) {
                if (int.tryParse(notif) != null) {
                  DocumentReference notify = await FirebaseFirestore.instance
                      .collection('notifikasis')
                      .add({
                    'menit_sebelum': int.parse(notif),
                    'kegiatans_id': actID,
                  });

                  DateTime notiftime = startTimeReal
                      .subtract(Duration(minutes: int.parse(notif)));

                  await AwesomeNotifications().createNotification(
                    content: NotificationContent(
                      id: notify.id.hashCode,
                      channelKey: 'activity_reminder',
                      title: "Kegiatan Selanjutnya - ${title.text}",
                      body:
                          "Kegiatanmu akan dimulai pada ${formattedActivityTimeOnly(startTimeReal)}",
                      notificationLayout: NotificationLayout.BigText,
                      criticalAlert: true,
                      wakeUpScreen: true,
                      category: NotificationCategory.Reminder,
                    ),
                    schedule: NotificationCalendar.fromDate(
                      date: notiftime,
                      preciseAlarm: true,
                      allowWhileIdle: true,
                    ),
                  );
                } else {
                  throw const FormatException("Format notifikasi tidak sesuai");
                }
              }
            }

            for (Files file in fileList) {
              String folder = "user_files/$userID/${actID.id}";
              String filePath = "$folder/${file.name}";
              await FirebaseFirestore.instance.collection('files').add({
                'nama': file.name,
                'path': "$folder/${file.name}",
                'kegiatans_id': actID.id,
              });
              await FirebaseStorage.instance
                  .ref(filePath)
                  .putFile(File(file.path));
            }

            for (Locations loc in widget.actDetail.locations ?? []) {
              await FirebaseFirestore.instance.collection('lokasis').add({
                'alamat': loc.address,
                'latitude': loc.latitude,
                'longitude': loc.longitude,
                'kegiatans_id': actID.id,
              });
            }

            List<String> newTask = tasks.text.split(',');

            for (String task in newTask == [""] ? [] : newTask) {
              await FirebaseFirestore.instance.collection('subtugass').add({
                'nama': task,
                'status': false,
                'kegiatans_id': actID.id,
              });
            }
          }
          Navigator.of(context).pop();
        } else {
          final act1 = await FirebaseFirestore.instance
              .collection('kegiatans')
              .doc(widget.actDetail.idAct2)
              .get();

          QuerySnapshot kegiatanToDelete = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct2)
              .get();

          for (var doc in kegiatanToDelete.docs) {
            print("ini id yang kegiatannya sama: ${doc.id}");
            if (doc.id != widget.actDetail.idAct2) {
              await FirebaseFirestore.instance
                  .collection('kegiatans')
                  .doc(doc.id)
                  .delete();

              QuerySnapshot taskSnap = await FirebaseFirestore.instance
                  .collection('subtugass')
                  .where('kegiatans_id', isEqualTo: doc.id)
                  .get();

              for (DocumentSnapshot doc1 in taskSnap.docs) {
                await FirebaseFirestore.instance
                    .collection('subtugass')
                    .doc(doc1.id)
                    .delete();
              }

              QuerySnapshot notifSnap = await FirebaseFirestore.instance
                  .collection('notifikasis')
                  .where('kegiatans_id', isEqualTo: doc.id)
                  .get();

              for (DocumentSnapshot doc1 in notifSnap.docs) {
                await FirebaseFirestore.instance
                    .collection('notifikasis')
                    .doc(doc1.id)
                    .delete();
              }

              QuerySnapshot logSnap = await FirebaseFirestore.instance
                  .collection('logs')
                  .where('kegiatans_id', isEqualTo: doc.id)
                  .get();

              for (DocumentSnapshot doc1 in logSnap.docs) {
                await FirebaseFirestore.instance
                    .collection('logs')
                    .doc(doc1.id)
                    .delete();
              }

              QuerySnapshot locSnap = await FirebaseFirestore.instance
                  .collection('lokasis')
                  .where('kegiatans_id', isEqualTo: doc.id)
                  .get();

              for (DocumentSnapshot doc1 in locSnap.docs) {
                await FirebaseFirestore.instance
                    .collection('lokasis')
                    .doc(doc1.id)
                    .delete();
              }

              QuerySnapshot fileSnap = await FirebaseFirestore.instance
                  .collection('files')
                  .where('kegiatans_id', isEqualTo: doc.id)
                  .get();

              for (DocumentSnapshot doc1 in fileSnap.docs) {
                await FirebaseStorage.instance.ref(doc['path']).delete();

                await FirebaseFirestore.instance
                    .collection('files')
                    .doc(doc1.id)
                    .delete();
              }

              ListResult listFile = await FirebaseStorage.instance
                  .ref("user_files/${doc.id}")
                  .listAll();

              for (Reference file in listFile.items) {
                await file.delete();
              }
            }
          }

          DateTime start = DateFormat("yyyy-MM-dd hh:mm a").parse(
              "${formattedActivityDateOnly((act1['waktu_mulai'] as Timestamp).toDate())} ${startTime.text}");
          DateTime startDate = DateFormat("yyyy-MM-dd").parse(
              formattedActivityDateOnly(
                  (act1['waktu_mulai'] as Timestamp).toDate()));
          DateTime end = DateFormat("yyyy-MM-dd hh:mm a").parse(
              "${formattedActivityDateOnly((act1['waktu_mulai'] as Timestamp).toDate())} ${endTime.text}");

          QuerySnapshot dailyActivities = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('waktu_mulai',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('waktu_mulai',
                  isLessThan: Timestamp.fromDate(
                      startDate.add(const Duration(days: 1))))
              .get();

          for (var activityDoc in dailyActivities.docs) {
            DateTime activityStart =
                (activityDoc['waktu_mulai'] as Timestamp).toDate();
            DateTime activityEnd =
                (activityDoc['waktu_akhir'] as Timestamp).toDate();

            if (start.isBefore(activityEnd) && end.isAfter(activityStart)) {
              if (activityDoc['fixed'] == false) {
                if (activityStart.isBefore(start)) {
                  // Adjust start time if the activity starts before the new activity
                  DateTime newActivityStart =
                      start.subtract(activityEnd.difference(activityStart));
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(newActivityStart),
                    "waktu_akhir": Timestamp.fromDate(newActivityStart
                        .add(activityEnd.difference(activityStart))),
                  });
                } else {
                  // Adjust end time if the activity starts after the new activity
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(end),
                    "waktu_akhir": Timestamp.fromDate(
                        end.add(activityEnd.difference(activityStart))),
                  });
                }
              }
            }
          }

          // Jika user pilih ganti hanya untuk kegiatan ini
          await FirebaseFirestore.instance
              .collection('kegiatans')
              .doc(widget.actDetail.idAct2)
              .update({
            "kegiatans_id": widget.actDetail.idAct2,
            'nama': title.text,
            "waktu_mulai": Timestamp.fromDate(start),
            "waktu_akhir": Timestamp.fromDate(end),
            'fixed': _isFixed,
            "interval_pengulangan": repeatFreq,
            "durasi_pengulangan": int.parse(repeatDur.text),
            "kategoris_id": category,
            "tipe_kepentingan": importance,
            "tipe_mendesak": urgent,
          });

          QuerySnapshot taskSnap = await FirebaseFirestore.instance
              .collection('subtugass')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct2)
              .get();

          List<String> newTask = tasks.text
              .split(',')
              .map((task) => task.trim())
              .where((task) => task.isNotEmpty)
              .toList();
          List<String> existingTask =
              taskSnap.docs.map((doc) => doc['nama'] as String).toList();

          List<DocumentSnapshot> tasksToDelete = taskSnap.docs.where((doc) {
            return !newTask.contains(doc['nama']);
          }).toList();
          List<String> tasksToAdd = newTask.where((name) {
            return !existingTask.contains(name);
          }).toList();

          for (DocumentSnapshot doc in tasksToDelete) {
            await FirebaseFirestore.instance
                .collection('subtugass')
                .doc(doc.id)
                .delete();
          }

          for (String taskName in tasksToAdd) {
            await FirebaseFirestore.instance.collection('subtugass').add({
              'nama': taskName,
              'kegiatans_id': widget.actDetail.idAct2,
              'status': false,
            });
          }

          QuerySnapshot notifSnap = await FirebaseFirestore.instance
              .collection('notifikasis')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct2)
              .get();

          for (var doc in notifSnap.docs) {
            await FirebaseFirestore.instance
                .collection('notifikasis')
                .doc(doc.id)
                .delete();
            await AwesomeNotifications().cancel(doc.id.hashCode);
          }

          List<String> newNotif = notification.text.split('.');
          print(newNotif);
          for (String notif in newNotif) {
            if (notif.isNotEmpty) {
              if (int.tryParse(notif) != null) {
                DocumentReference notify = await FirebaseFirestore.instance
                    .collection('notifikasis')
                    .add({
                  'menit_sebelum': int.parse(notif),
                  'kegiatans_id': widget.actDetail.idAct2,
                });

                DateTime notiftime =
                    start.subtract(Duration(minutes: int.parse(notif)));

                await AwesomeNotifications().createNotification(
                  content: NotificationContent(
                    id: notify.id.hashCode,
                    channelKey: 'activity_reminder',
                    title: "Kegiatan Selanjutnya - ${title.text}",
                    body:
                        "Kegiatanmu akan dimulai pada ${formattedActivityTimeOnly(start)}",
                    notificationLayout: NotificationLayout.BigText,
                    criticalAlert: true,
                    wakeUpScreen: true,
                    category: NotificationCategory.Reminder,
                  ),
                  schedule: NotificationCalendar.fromDate(
                    date: notiftime,
                    preciseAlarm: true,
                    allowWhileIdle: true,
                  ),
                );
              } else {
                throw const FormatException("Format notifikasi tidak sesuai");
              }
            }
          }

          QuerySnapshot locSnap = await FirebaseFirestore.instance
              .collection('lokasis')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct2)
              .get();

          for (var doc in locSnap.docs) {
            await FirebaseFirestore.instance
                .collection('lokasis')
                .doc(doc.id)
                .delete();
          }

          for (Locations loc in widget.actDetail.locations ?? []) {
            await FirebaseFirestore.instance.collection('lokasis').add({
              'kegiatans_id': widget.actDetail.idAct2,
              'alamat': loc.address,
              'latitude': loc.latitude,
              'longitude': loc.longitude,
            });
          }

          QuerySnapshot fileSnap1 = await FirebaseFirestore.instance
              .collection('files')
              .where('kegiatans_id', isEqualTo: widget.actDetail.idAct2)
              .get();

          for (DocumentSnapshot doc in fileSnap1.docs) {
            await FirebaseStorage.instance.ref(doc['path']).delete();

            await FirebaseFirestore.instance
                .collection('files')
                .doc(doc.id)
                .delete();
          }

          ListResult listFile = await FirebaseStorage.instance
              .ref("user_files/${widget.actDetail.idAct2}")
              .listAll();

          for (Reference file in listFile.items) {
            await file.delete();
          }

          for (Files file in fileList) {
            String folder = "user_files/$userID/${widget.actDetail.idAct2}";
            String filePath = "$folder/${file.name}";
            await FirebaseFirestore.instance.collection('files').add({
              'nama': file.name,
              'path': "$folder/${file.name}",
              'kegiatans_id': widget.actDetail.idAct2,
            });
            await FirebaseStorage.instance
                .ref(filePath)
                .putFile(File(file.path));
          }

          for (var i = 1;
              i < (repeatFreq == "Tidak" ? 1 : int.parse(repeatDur.text));
              i++) {
            DateTime startTimeReal;
            DateTime startDateReal;
            DateTime endTimeReal;

            if (repeatFreq == "Harian") {
              startTimeReal = start.add(Duration(days: i));
              startDateReal = startDate.add(Duration(days: i));
              endTimeReal = end.add(Duration(days: i));
            } else if (repeatFreq == "Mingguan") {
              startTimeReal = start.add(Duration(days: 7 * i));
              startDateReal = startDate.add(Duration(days: 7 * i));
              endTimeReal = end.add(Duration(days: 7 * i));
            } else if (repeatFreq == "Bulanan") {
              startTimeReal = start.add(Duration(days: 30 * i));
              startDateReal = startDate.add(Duration(days: 30 * i));
              endTimeReal = end.add(Duration(days: 30 * i));
            } else if (repeatFreq == "Tahunan") {
              startTimeReal = start.add(Duration(days: 365 * i));
              startDateReal = startDate.add(Duration(days: 365 * i));
              endTimeReal = end.add(Duration(days: 365 * i));
            } else {
              startTimeReal = start;
              startDateReal = startDate;
              endTimeReal = end;
            }

            QuerySnapshot dailyActivities = await FirebaseFirestore.instance
                .collection('kegiatans')
                .where('waktu_mulai',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startDateReal))
                .where('waktu_mulai',
                    isLessThan: Timestamp.fromDate(
                        startDateReal.add(const Duration(days: 1))))
                .get();

            for (var activityDoc in dailyActivities.docs) {
              DateTime activityStart =
                  (activityDoc['waktu_mulai'] as Timestamp).toDate();
              DateTime activityEnd =
                  (activityDoc['waktu_akhir'] as Timestamp).toDate();

              if (startTimeReal.isBefore(activityEnd) &&
                  endTimeReal.isAfter(activityStart)) {
                if (activityDoc['fixed'] == false) {
                  if (activityStart.isBefore(startTimeReal)) {
                    // Adjust start time if the activity starts before the new activity
                    DateTime newActivityStart = startTimeReal
                        .subtract(activityEnd.difference(activityStart));
                    await FirebaseFirestore.instance
                        .collection('kegiatans')
                        .doc(activityDoc.id)
                        .update({
                      "waktu_mulai": Timestamp.fromDate(newActivityStart),
                      "waktu_akhir": Timestamp.fromDate(newActivityStart
                          .add(activityEnd.difference(activityStart))),
                    });
                  } else {
                    // Adjust end time if the activity starts after the new activity
                    await FirebaseFirestore.instance
                        .collection('kegiatans')
                        .doc(activityDoc.id)
                        .update({
                      "waktu_mulai": Timestamp.fromDate(endTimeReal),
                      "waktu_akhir": Timestamp.fromDate(endTimeReal
                          .add(activityEnd.difference(activityStart))),
                    });
                  }
                }
              }
            }
            // Tambahkan kegiatan baru ke dalam Firestore
            DocumentReference actID =
                await FirebaseFirestore.instance.collection('kegiatans').add({
              'nama': title.text,
              "status": false,
              "users_id": userID,
              "waktu_mulai": Timestamp.fromDate(startTimeReal),
              "waktu_akhir": Timestamp.fromDate(endTimeReal),
              'fixed': _isFixed,
              "interval_pengulangan": repeatFreq,
              "durasi_pengulangan": int.parse(repeatDur.text),
              "kategoris_id": category,
              "kegiatans_id": widget.actDetail.idAct2,
              "tipe_kepentingan": importance,
              "tipe_mendesak": urgent,
            });

            List<String> newNotif = notification.text.split('.');
            for (String notif in newNotif) {
              if (notif.isNotEmpty) {
                if (int.tryParse(notif) != null) {
                  DocumentReference notify = await FirebaseFirestore.instance
                      .collection('notifikasis')
                      .add({
                    'menit_sebelum': int.parse(notif),
                    'kegiatans_id': actID,
                  });

                  DateTime notiftime = startTimeReal
                      .subtract(Duration(minutes: int.parse(notif)));

                  await AwesomeNotifications().createNotification(
                    content: NotificationContent(
                      id: notify.id.hashCode,
                      channelKey: 'activity_reminder',
                      title: "Kegiatan Selanjutnya - ${title.text}",
                      body:
                          "Kegiatanmu akan dimulai pada ${formattedActivityTimeOnly(startTimeReal)}",
                      notificationLayout: NotificationLayout.BigText,
                      criticalAlert: true,
                      wakeUpScreen: true,
                      category: NotificationCategory.Reminder,
                    ),
                    schedule: NotificationCalendar.fromDate(
                      date: notiftime,
                      preciseAlarm: true,
                      allowWhileIdle: true,
                    ),
                  );
                } else {
                  throw const FormatException("Format notifikasi tidak sesuai");
                }
              }
            }

            for (Files file in fileList) {
              String folder = "user_files/$userID/${actID.id}";
              String filePath = "$folder/${file.name}";
              await FirebaseFirestore.instance.collection('files').add({
                'nama': file.name,
                'path': "$folder/${file.name}",
                'kegiatans_id': actID.id,
              });
              await FirebaseStorage.instance
                  .ref(filePath)
                  .putFile(File(file.path));
            }

            for (Locations loc in widget.actDetail.locations ?? []) {
              await FirebaseFirestore.instance.collection('lokasis').add({
                'alamat': loc.address,
                'latitude': loc.latitude,
                'longitude': loc.longitude,
                'kegiatans_id': actID.id,
              });
            }

            List<String> newTask = tasks.text.split(',');

            for (String task in newTask == [""] ? [] : newTask) {
              await FirebaseFirestore.instance.collection('subtugass').add({
                'nama': task,
                'status': false,
                'kegiatans_id': actID.id,
              });
            }
          }
          Navigator.of(context).pop();
        }
      } else {
        DateTime start = DateFormat("yyyy-MM-dd hh:mm a")
            .parse("${calendarDate.text} ${startTime.text}");
        DateTime startDate = DateFormat("yyyy-MM-dd").parse(calendarDate.text);
        DateTime end = DateFormat("yyyy-MM-dd hh:mm a")
            .parse("${calendarDate.text} ${endTime.text}");

        QuerySnapshot dailyActivities = await FirebaseFirestore.instance
            .collection('kegiatans')
            .where('waktu_mulai',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('waktu_mulai',
                isLessThan:
                    Timestamp.fromDate(startDate.add(const Duration(days: 1))))
            .get();

        for (var activityDoc in dailyActivities.docs) {
          DateTime activityStart =
              (activityDoc['waktu_mulai'] as Timestamp).toDate();
          DateTime activityEnd =
              (activityDoc['waktu_akhir'] as Timestamp).toDate();

          if (start.isBefore(activityEnd) && end.isAfter(activityStart)) {
            if (activityDoc['fixed'] == false) {
              if (activityStart.isBefore(start)) {
                // Adjust start time if the activity starts before the new activity
                DateTime newActivityStart =
                    start.subtract(activityEnd.difference(activityStart));
                await FirebaseFirestore.instance
                    .collection('kegiatans')
                    .doc(activityDoc.id)
                    .update({
                  "waktu_mulai": Timestamp.fromDate(newActivityStart),
                  "waktu_akhir": Timestamp.fromDate(newActivityStart
                      .add(activityEnd.difference(activityStart))),
                });
              } else {
                // Adjust end time if the activity starts after the new activity
                await FirebaseFirestore.instance
                    .collection('kegiatans')
                    .doc(activityDoc.id)
                    .update({
                  "waktu_mulai": Timestamp.fromDate(end),
                  "waktu_akhir": Timestamp.fromDate(
                      end.add(activityEnd.difference(activityStart))),
                });
              }
            }
          }
        }

        // Update the current activity
        await FirebaseFirestore.instance
            .collection('kegiatans')
            .doc(widget.actDetail.idAct)
            .update({
          'nama': title.text,
          "waktu_mulai": Timestamp.fromDate(start),
          "waktu_akhir": Timestamp.fromDate(end),
          'fixed': _isFixed,
          "interval_pengulangan": repeatFreq,
          "durasi_pengulangan": int.parse(repeatDur.text),
          "kategoris_id": category,
          "kegiatans_id": widget.actDetail.idAct,
          "tipe_kepentingan": importance,
          "tipe_mendesak": urgent,
        });

        // Update tasks
        QuerySnapshot taskSnap = await FirebaseFirestore.instance
            .collection('subtugass')
            .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
            .get();

        List<String> newTask = tasks.text
            .split(',')
            .map((task) => task.trim())
            .where((task) => task.isNotEmpty)
            .toList();
        List<String> existingTask =
            taskSnap.docs.map((doc) => doc['nama'] as String).toList();

        List<DocumentSnapshot> tasksToDelete = taskSnap.docs.where((doc) {
          return !newTask.contains(doc['nama']);
        }).toList();
        List<String> tasksToAdd = newTask.where((name) {
          return !existingTask.contains(name);
        }).toList();

        for (DocumentSnapshot doc in tasksToDelete) {
          await FirebaseFirestore.instance
              .collection('subtugass')
              .doc(doc.id)
              .delete();
        }

        for (String taskName in tasksToAdd) {
          await FirebaseFirestore.instance.collection('subtugass').add({
            'nama': taskName,
            'kegiatans_id': widget.actDetail.idAct,
            'status': false,
          });
        }

        // Update notifications
        QuerySnapshot notifSnap = await FirebaseFirestore.instance
            .collection('notifikasis')
            .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
            .get();

        for (var doc in notifSnap.docs) {
          await FirebaseFirestore.instance
              .collection('notifikasis')
              .doc(doc.id)
              .delete();
          await AwesomeNotifications().cancel(doc.id.hashCode);
        }

        List<String> newNotif = notification.text.split('.');
        for (String notif in newNotif) {
          if (notif.isNotEmpty) {
            if (int.tryParse(notif) != null) {
              DocumentReference notify = await FirebaseFirestore.instance
                  .collection('notifikasis')
                  .add({
                'menit_sebelum': int.parse(notif),
                'kegiatans_id': widget.actDetail.idAct,
              });

              DateTime notiftime =
                  start.subtract(Duration(minutes: int.parse(notif)));

              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: notify.id.hashCode,
                  channelKey: 'activity_reminder',
                  title: "Kegiatan Selanjutnya - ${title.text}",
                  body:
                      "Kegiatanmu akan dimulai pada ${formattedActivityTimeOnly(start)}",
                  notificationLayout: NotificationLayout.BigText,
                  criticalAlert: true,
                  wakeUpScreen: true,
                  category: NotificationCategory.Reminder,
                ),
                schedule: NotificationCalendar.fromDate(
                  date: notiftime,
                  preciseAlarm: true,
                  allowWhileIdle: true,
                ),
              );
            } else {
              throw const FormatException("Format notifikasi tidak sesuai");
            }
          }
        }

        // Update locations
        QuerySnapshot locSnap = await FirebaseFirestore.instance
            .collection('lokasis')
            .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
            .get();

        for (var doc in locSnap.docs) {
          await FirebaseFirestore.instance
              .collection('lokasis')
              .doc(doc.id)
              .delete();
        }

        for (Locations loc in widget.actDetail.locations ?? []) {
          await FirebaseFirestore.instance.collection('lokasis').add({
            'kegiatans_id': widget.actDetail.idAct,
            'alamat': loc.address,
            'latitude': loc.latitude,
            'longitude': loc.longitude,
          });
        }

        // Update files
        QuerySnapshot fileSnap1 = await FirebaseFirestore.instance
            .collection('files')
            .where('kegiatans_id', isEqualTo: widget.actDetail.idAct)
            .get();

        for (DocumentSnapshot doc in fileSnap1.docs) {
          await FirebaseStorage.instance.ref(doc['path']).delete();
          await FirebaseFirestore.instance
              .collection('files')
              .doc(doc.id)
              .delete();
        }

        ListResult listFile = await FirebaseStorage.instance
            .ref("user_files/${widget.actDetail.idAct}")
            .listAll();

        for (Reference file in listFile.items) {
          await file.delete();
        }

        for (Files file in fileList) {
          String folder = "user_files/$userID/${widget.actDetail.idAct}";
          String filePath = "$folder/${file.name}";
          await FirebaseFirestore.instance.collection('files').add({
            'nama': file.name,
            'path': "$folder/${file.name}",
            'kegiatans_id': widget.actDetail.idAct,
          });
          await FirebaseStorage.instance.ref(filePath).putFile(File(file.path));
        }

        // Handle repeated activities
        for (var i = 1;
            i < (repeatFreq == "Tidak" ? 1 : int.parse(repeatDur.text));
            i++) {
          DateTime startTimeReal;
          DateTime startDateReal;
          DateTime endTimeReal;

          if (repeatFreq == "Harian") {
            startTimeReal = start.add(Duration(days: i));
            startDateReal = startDate.add(Duration(days: i));
            endTimeReal = end.add(Duration(days: i));
          } else if (repeatFreq == "Mingguan") {
            startTimeReal = start.add(Duration(days: 7 * i));
            startDateReal = startDate.add(Duration(days: 7 * i));
            endTimeReal = end.add(Duration(days: 7 * i));
          } else if (repeatFreq == "Bulanan") {
            startTimeReal = start.add(Duration(days: 30 * i));
            startDateReal = startDate.add(Duration(days: 30 * i));
            endTimeReal = end.add(Duration(days: 30 * i));
          } else if (repeatFreq == "Tahunan") {
            startTimeReal = start.add(Duration(days: 365 * i));
            startDateReal = startDate.add(Duration(days: 365 * i));
            endTimeReal = end.add(Duration(days: 365 * i));
          } else {
            startTimeReal = start;
            startDateReal = startDate;
            endTimeReal = end;
          }

          QuerySnapshot dailyActivities = await FirebaseFirestore.instance
              .collection('kegiatans')
              .where('waktu_mulai',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDateReal))
              .where('waktu_mulai',
                  isLessThan: Timestamp.fromDate(
                      startDateReal.add(const Duration(days: 1))))
              .get();

          for (var activityDoc in dailyActivities.docs) {
            DateTime activityStart =
                (activityDoc['waktu_mulai'] as Timestamp).toDate();
            DateTime activityEnd =
                (activityDoc['waktu_akhir'] as Timestamp).toDate();
            if (startTimeReal.isBefore(activityEnd) &&
                endTimeReal.isAfter(activityStart)) {
              if (activityDoc['fixed'] == false) {
                if (activityStart.isBefore(startTimeReal)) {
                  // Adjust start time if the activity starts before the new activity
                  DateTime newActivityStart = startTimeReal
                      .subtract(activityEnd.difference(activityStart));
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(newActivityStart),
                    "waktu_akhir": Timestamp.fromDate(newActivityStart
                        .add(activityEnd.difference(activityStart))),
                  });
                } else {
                  // Adjust end time if the activity starts after the new activity
                  await FirebaseFirestore.instance
                      .collection('kegiatans')
                      .doc(activityDoc.id)
                      .update({
                    "waktu_mulai": Timestamp.fromDate(endTimeReal),
                    "waktu_akhir": Timestamp.fromDate(
                        endTimeReal.add(activityEnd.difference(activityStart))),
                  });
                }
              }
            }
          }
          // Tambahkan kegiatan baru ke dalam Firestore
          DocumentReference actID =
              await FirebaseFirestore.instance.collection('kegiatans').add({
            'nama': title.text,
            "waktu_mulai": Timestamp.fromDate(startTimeReal),
            "waktu_akhir": Timestamp.fromDate(endTimeReal),
            'fixed': _isFixed,
            "interval_pengulangan": repeatFreq,
            "durasi_pengulangan": int.parse(repeatDur.text),
            "kategoris_id": category,
            "kegiatans_id": widget.actDetail.idAct,
            "tipe_kepentingan": importance,
            "tipe_mendesak": urgent,
            "status": false,
            "users_id": userID,
          });

// Menambahkan notifikasi untuk kegiatan baru
          List<String> newNotif = notification.text.split('.');
          for (String notif in newNotif) {
            if (notif.isNotEmpty) {
              if (int.tryParse(notif) != null) {
                DocumentReference notify = await FirebaseFirestore.instance
                    .collection('notifikasis')
                    .add({
                  'menit_sebelum': int.parse(notif),
                  'kegiatans_id': actID.id,
                });

                DateTime notiftime =
                    startTimeReal.subtract(Duration(minutes: int.parse(notif)));

                await AwesomeNotifications().createNotification(
                  content: NotificationContent(
                    id: notify.id.hashCode,
                    channelKey: 'activity_reminder',
                    title: "Kegiatan Selanjutnya - ${title.text}",
                    body:
                        "Kegiatanmu akan dimulai pada ${formattedActivityTimeOnly(startTimeReal)}",
                    notificationLayout: NotificationLayout.BigText,
                    criticalAlert: true,
                    wakeUpScreen: true,
                    category: NotificationCategory.Reminder,
                  ),
                  schedule: NotificationCalendar.fromDate(
                    date: notiftime,
                    preciseAlarm: true,
                    allowWhileIdle: true,
                  ),
                );
              } else {
                throw const FormatException("Format notifikasi tidak sesuai");
              }
            }
          }

// Menambahkan file ke dalam Firestore dan Firebase Storage
          for (Files file in fileList) {
            String folder = "user_files/$userID/${actID.id}";
            String filePath = "$folder/${file.name}";
            await FirebaseFirestore.instance.collection('files').add({
              'nama': file.name,
              'path': "$folder/${file.name}",
              'kegiatans_id': actID.id,
            });
            await FirebaseStorage.instance
                .ref(filePath)
                .putFile(File(file.path));
          }

// Menambahkan lokasi ke dalam Firestore
          for (Locations loc in widget.actDetail.locations ?? []) {
            await FirebaseFirestore.instance.collection('lokasis').add({
              'alamat': loc.address,
              'latitude': loc.latitude,
              'longitude': loc.longitude,
              'kegiatans_id': actID.id,
            });
          }

// Menambahkan sub tugas ke dalam Firestore
          List<String> newTask = tasks.text.split(',');
          for (String task in newTask == [""] ? [] : newTask) {
            await FirebaseFirestore.instance.collection('subtugass').add({
              'nama': task,
              'status': false,
              'kegiatans_id': actID.id,
            });
          }
        }
      }

      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
        context: context,
        title: "Ubah Jadwal Kegiatan Sukses",
        message:
            "Kegiatan yang kamu pilih telah berhasil diubah. Terima kasih.",
      );
    } catch (e) {
      Navigator.of(context).pop();
      AlertInformation.showDialogBox(
        context: context,
        title: "Error",
        message: "$e",
      );
      print(e);
    }
  }

//   Future<void> shiftOverlappingActivities(String updatedDocId, DateTime newStartTime) async {
//   QuerySnapshot overlappingActivities = await FirebaseFirestore.instance
//       .collection('kegiatans')
//       .where('fixed', isEqualTo: false)
//       .where('waktu_mulai', isGreaterThanOrEqualTo: newStartTime)
//       .get();

//   for (var overlappingDoc in overlappingActivities.docs) {
//     if (overlappingDoc.id == updatedDocId) {
//       continue;
//     }

//     DateTime overlappingStart =
//         (overlappingDoc['waktu_mulai'] as Timestamp).toDate();
//     DateTime overlappingEnd =
//         (overlappingDoc['waktu_akhir'] as Timestamp).toDate();

//     // Calculate the duration of the overlapping activity
//     Duration overlappingDuration = overlappingEnd.difference(overlappingStart);

//     // Shift the overlapping activity by the same amount of time as the original shift
//     DateTime newOverlappingStart = newStartTime;
//     DateTime newOverlappingEnd = newStartTime.add(overlappingDuration);

//     await FirebaseFirestore.instance
//         .collection('kegiatans')
//         .doc(overlappingDoc.id)
//         .update({
//       'waktu_mulai': Timestamp.fromDate(newOverlappingStart),
//       'waktu_akhir': Timestamp.fromDate(newOverlappingEnd),
//     });

//     // Update any related tasks, notifications, locations, or files for the overlapping activity
//     // (similar to the update process above)

//     // Update newStartTime for the next shift
//     newStartTime = newOverlappingEnd;
//   }
// }

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
          content: Text("Kategori telah ditambahkan"),
        ),
      );

      setState(() {
        newCat.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menambah data kategori: $e"),
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

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    getCategoryData();
    getListFileDownloaded();
    print(widget.actDetail);

    setState(() {
      title = TextEditingController(text: widget.actDetail.title);
      String formattedDate =
          formattedActivityDateOnly(widget.actDetail.strTime);
      calendarDate = TextEditingController(text: formattedDate);
      startTime = TextEditingController(
          text: formattedActivityTimeOnly(widget.actDetail.strTime));
      startTime2 = TimeOfDay.fromDateTime(DateFormat.jm()
          .parse(formattedActivityTimeOnly(widget.actDetail.strTime)));
      endTime = TextEditingController(
          text: formattedActivityTimeOnly(widget.actDetail.endTime));
      endTime2 = TimeOfDay.fromDateTime(DateFormat.jm()
          .parse(formattedActivityTimeOnly(widget.actDetail.endTime)));
      importance = widget.actDetail.impType;
      urgent = widget.actDetail.urgType;
      tasks = TextEditingController(text: getTasksAsString());
      category = widget.actDetail.idCat;
      notification = TextEditingController(text: getNotificationAsString());
      _isFixed = widget.actDetail.isFixed;
      repeatFreq = widget.actDetail.rptFreq;
      repeatDur =
          TextEditingController(text: widget.actDetail.rptDur.toString());
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
            'Ubah Kegiatan',
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
                                    child: AbsorbPointer(
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
                                          startTime2 = TimeOfDay.fromDateTime(
                                              DateFormat.jm()
                                                  .parse(startTime.text));

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
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Silahkan isi waktu mulai';
                                                } else if ((startTime2!.hour *
                                                                60 +
                                                            startTime2!.minute)
                                                        .toInt() >
                                                    (endTime2!.hour * 60 +
                                                            endTime2!.minute)
                                                        .toInt()) {
                                                  return 'Harus lebih kecil';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              controller: startTime,
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
                          ), // End time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Waktu akhir",
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
                                          endTime.text = formattedTime;
                                          endTime2 = TimeOfDay.fromDateTime(
                                              DateFormat.jm()
                                                  .parse(endTime.text));

                                          print(endTime.text);
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
                                          child: AbsorbPointer(
                                            child: TextFormField(
                                              autofocus: false,
                                              readOnly: true,
                                              keyboardType: TextInputType.text,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: InputDecoration(
                                                hintText: "Pilih waktu akhir",
                                                hintStyle: textStyleGrey,
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Silahkan isi waktu akhir';
                                                } else if ((startTime2!.hour *
                                                                60 +
                                                            startTime2!.minute)
                                                        .toInt() >
                                                    (endTime2!.hour * 60 +
                                                            endTime2!.minute)
                                                        .toInt()) {
                                                  return 'Harus lebih besar';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              controller: endTime,
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
                                                  'Pilih Warna Kegiatan Kamu',
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
                                            'Kode ARGB: (${colorA.text}, ${colorR.text}, ${colorG.text}, ${colorB.text})');
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
                                                        "Masukkan kategori baru",
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
                                                onTap: () async {
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
                                                    await createNewCategory();
                                                    await getCategoryData();
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
                                          "Masukkan waktu pengingat kegiatan",
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
                                GestureDetector(
                                  onTap: () async {
                                    await _requestLocationPermission(); // Meminta izin lokasi sebelum menampilkan picker lokasi

                                    if (await Permission.location.isGranted) {
                                      geoPoint =
                                          await osm.showSimplePickerLocation(
                                        context: context,
                                        isDismissible: true,
                                        title: 'Tambah Lokasi',
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
                                // Container(
                                //   padding: const EdgeInsets.only(
                                //     left: 10,
                                //     right: 10,
                                //   ),
                                //   height: 50,
                                //   alignment: Alignment.center,
                                //   width: constraints.maxWidth,
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
                                //           title: 'Tambah Lokasi',
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
                                //     child: Text(
                                //       "Click disini untuk menambahkan lokasi baru",
                                //       style: textStyle,
                                //     ),
                                //   ),
                                // ),
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
                                height: (widget.actDetail.locations?.isEmpty ??
                                        true)
                                    ? 50
                                    : 100,
                                padding: (widget.actDetail.locations?.isEmpty ??
                                        true)
                                    ? const EdgeInsets.all(10)
                                    : const EdgeInsets.only(
                                        left: 5,
                                        right: 5,
                                      ),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15)),
                                child: (widget.actDetail.locations?.isEmpty ??
                                        true)
                                    ? Text(
                                        "Tidak ada lokasi kegiatan",
                                        style: textStyle,
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          children: List.generate(
                                            widget.actDetail.locations
                                                    ?.length ??
                                                0,
                                            (index) {
                                              return ListTile(
                                                title: GestureDetector(
                                                  onTap: () async {
                                                    openGoogleMaps(
                                                      widget
                                                              .actDetail
                                                              .locations?[index]
                                                              .latitude ??
                                                          0.0,
                                                      widget
                                                              .actDetail
                                                              .locations?[index]
                                                              .longitude ??
                                                          0.0,
                                                    );
                                                  },
                                                  child: Text(
                                                    widget
                                                            .actDetail
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
                                                            'Location dihapus'),
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
                                height:
                                    (widget.actDetail.files?.isEmpty ?? true)
                                        ? 50
                                        : 100,
                                padding:
                                    (widget.actDetail.files?.isEmpty ?? true)
                                        ? const EdgeInsets.all(10)
                                        : const EdgeInsets.only(
                                            left: 5,
                                            right: 5,
                                          ),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15)),
                                child: (fileList == [])
                                    ? Text(
                                        "Tidak ada file kegiatan",
                                        style: textStyle,
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          children: List.generate(
                                            fileList.length,
                                            (index) {
                                              return ListTile(
                                                title: GestureDetector(
                                                  onTap: () {
                                                    openFile(
                                                        fileList[index].path);
                                                  },
                                                  child: Text(
                                                      fileList[index].name),
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
                                                            'File dihapus'),
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
                                title: "Beberapa Input Tidak Sesuai",
                                message:
                                    "Terdapat beberapa input yang tidak sesuai. Mohon untuk mengisi input yang wajib. Terima kasih.");
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
                              editActivitySchedule();
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
