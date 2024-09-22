// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pickleapp/screen/class/file.dart';
import 'package:pickleapp/screen/class/location.dart';
import 'package:pickleapp/screen/class/notification.dart';
import 'package:pickleapp/screen/class/task.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/page/activity_edit_detail.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:pickleapp/theme.dart';
import 'package:intl/intl.dart';

import 'package:pickleapp/screen/class/activity_detail.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailActivity extends StatefulWidget {
  final String scheduledID;
  const DetailActivity({super.key, required this.scheduledID});

  @override
  State<DetailActivity> createState() => _DetailActivityState();
}

class _DetailActivityState extends State<DetailActivity> {
  late Future<DetailActivities?> detailAct;
  Color? colorTheme;
  Color? colorCategory;

  /* ------------------------------------------------------------------------------------------------------------------- */

  // Get Priority from important n urgent
  String formattedPriority(String impt, String urgt) {
    if (impt == "Penting" && urgt == "Mendesak") {
      return "Utama";
    } else if (impt == "Penting" && urgt == "Tidak Mendesak") {
      return "Tinggi";
    } else if (impt == "Tidak Penting" && urgt == "Mendesak") {
      return "Sedang";
    } else {
      return "Rendah";
    }
  }

  Color getPriorityColor(String important, String urgent) {
    if (important == "Penting" && urgent == "Mendesak") {
      return Colors.red;
    } else if (important == "Penting" && urgent == "Tidak Mendesak") {
      return Colors.yellow;
    } else if (important == "Tidak Penting" && urgent == "Mendesak") {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  // Image for priority type to use it in containers
  String getPriorityImage(important, urgent) {
    if (important == "Penting" && urgent == "Mendesak") {
      return 'assets/golfBall_1.png';
    } else if (important == "Penting" && urgent == "Tidak Mendesak") {
      return 'assets/pebbles_1.png';
    } else if (important == "Tidak Penting" && urgent == "Mendesak") {
      return 'assets/sand_1.png';
    } else {
      return 'assets/water_1.png';
    }
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityTimeOnly(DateTime inptTime) {
    DateTime time = inptTime;

    String formattedTime = DateFormat("hh:mm a").format(time);

    return formattedTime;
  }

  // Change format time to hh:mm PM/AM
  String formattedActivityDateOnly(DateTime inptTime) {
    DateTime time = inptTime;

    String formattedTime = DateFormat("dd MMM yyyy").format(time);

    return formattedTime;
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Future<DetailActivities?> getDetailActivity(String id) async {
    try {
      final actDoc = await FirebaseFirestore.instance
          .collection('kegiatans')
          .doc(id)
          .get();

      String catID = actDoc['kategoris_id'];

      DocumentSnapshot? catDoc;
      if (catID.isNotEmpty) {
        catDoc = await FirebaseFirestore.instance
            .collection('kategoris')
            .doc(catID)
            .get();
      }

      final fileQuery = await FirebaseFirestore.instance
          .collection('files')
          .where('kegiatans_id', isEqualTo: id)
          .get();
      List<Files> files = [];
      if (fileQuery.docs.isNotEmpty) {
        for (var doc in fileQuery.docs) {
          files.add(Files(
            name: doc['nama'],
            path: doc['path'],
          ));
        }
      }

      QuerySnapshot locQuery = await FirebaseFirestore.instance
          .collection('lokasis')
          .where('kegiatans_id', isEqualTo: id)
          .get();
      List<Locations> locs = [];
      for (var doc in locQuery.docs) {
        locs.add(Locations(
          address: doc['alamat'],
          latitude: doc['latitude'],
          longitude: doc['longitude'],
        ));
      }

      QuerySnapshot notifQuery = await FirebaseFirestore.instance
          .collection('notifikasis')
          .where('kegiatans_id', isEqualTo: id)
          .get();
      List<Notifications>? notifs = [];
      for (var doc in notifQuery.docs) {
        notifs.add(Notifications(
          minute: doc['menit_sebelum'],
        ));
      }

      final taskQuery = await FirebaseFirestore.instance
          .collection('subtugass')
          .where('kegiatans_id', isEqualTo: id)
          .get();
      List<Tasks> tasks = [];
      for (var doc in taskQuery.docs) {
        tasks.add(Tasks(task: doc['nama'], status: doc['status']));
      }

      Timestamp startTime = actDoc['waktu_mulai'];
      DateTime dateTimeStr = startTime.toDate();

      Timestamp endTime = actDoc['waktu_akhir'];
      DateTime dateTimeEnd = endTime.toDate();

      return DetailActivities(
        idAct: id,
        idAct2: actDoc['kegiatans_id'],
        status: actDoc['status'],
        isFixed: actDoc['fixed'],
        title: actDoc['nama'],
        impType: actDoc['tipe_kepentingan'],
        urgType: actDoc['tipe_mendesak'],
        rptFreq: actDoc['interval_pengulangan'],
        rptDur: actDoc['durasi_pengulangan'],
        catName: catDoc?['nama'],
        idCat: catID,
        clrA: catDoc?['warna_a'],
        clrR: catDoc?['warna_r'],
        clrG: catDoc?['warna_g'],
        clrB: catDoc?['warna_b'],
        strTime: dateTimeStr,
        endTime: dateTimeEnd,
        tasks: tasks,
        files: files,
        locations: locs,
        notif: notifs,
      );
    } catch (e) {
      print("Error di getDetailActivity: $e");
    }
    return null;
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  void openFile(String path) {
    OpenFile.open(path);
  }

  Future<void> fileDownloadOpen(String path, String name) async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

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
      Navigator.of(context).pop();
      // Open the file
      await OpenFile.open(tempFile.path);
    } catch (e) {
      Navigator.of(context).pop();
      print(e);
    }
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

  /* ------------------------------------------------------------------------------------------------------------------- */

  Future<void> deleteScheduledActivity(String activityID) async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      DocumentReference actRef =
          FirebaseFirestore.instance.collection('kegiatans').doc(activityID);

      await actRef.delete();

      QuerySnapshot taskSnap = await FirebaseFirestore.instance
          .collection('subtugass')
          .where('kegiatans_id', isEqualTo: activityID)
          .get();

      for (DocumentSnapshot doc in taskSnap.docs) {
        await FirebaseFirestore.instance
            .collection('subtugass')
            .doc(doc.id)
            .delete();
      }

      QuerySnapshot notifSnap = await FirebaseFirestore.instance
          .collection('notifikasis')
          .where('kegiatans_id', isEqualTo: activityID)
          .get();

      for (DocumentSnapshot doc in notifSnap.docs) {
        await FirebaseFirestore.instance
            .collection('notifikasis')
            .doc(doc.id)
            .delete();
      }

      QuerySnapshot logSnap = await FirebaseFirestore.instance
          .collection('logs')
          .where('kegiatans_id', isEqualTo: activityID)
          .get();

      for (DocumentSnapshot doc in logSnap.docs) {
        await FirebaseFirestore.instance
            .collection('logs')
            .doc(doc.id)
            .delete();
      }

      QuerySnapshot locSnap = await FirebaseFirestore.instance
          .collection('lokasis')
          .where('kegiatans_id', isEqualTo: activityID)
          .get();

      for (DocumentSnapshot doc in locSnap.docs) {
        await FirebaseFirestore.instance
            .collection('lokasis')
            .doc(doc.id)
            .delete();
      }

      QuerySnapshot fileSnap = await FirebaseFirestore.instance
          .collection('files')
          .where('kegiatans_id', isEqualTo: activityID)
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

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
        context: context,
        title: "Hapus Jadwal Kegiatan Berhasil",
        message:
            "Jadwal kegiatan yang kamu pilih telah berhasil dihapus. Terima kasih",
      );
    } on Exception catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
        context: context,
        title: "Hapus Jadwal Kegiatan Tidak Berhasil",
        message:
            "Jadwal kegiatan yang kamu pilih tidak berhasil dihapus. Mohon cek koneksi internet kamu. $e",
      );
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    setState(() {
      detailAct = getDetailActivity(widget.scheduledID);
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 66),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 3, 0, 66),
        title: Text(
          'Detail Jadwal Kegiatan',
          style: subHeaderStyleBoldWhite,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<DetailActivities?>(
        future: detailAct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Detail Kegiatan Tidak Ditemukan, mohon keluar dari halaman detail, lalu cek koneksi internet kamu, dan masuk kembali.',
                style: textStyleBoldWhite,
              ),
            );
          } else {
            DetailActivities detail = snapshot.data!;
            colorTheme = getPriorityColor(detail.impType, detail.urgType);
            colorCategory = Color.fromARGB(
                detail.clrA, detail.clrR, detail.clrG, detail.clrB);

            return SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Title activity
                    Container(
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            getPriorityImage(detail.impType, detail.urgType),
                            width: MediaQuery.of(context).size.width * 0.1,
                            height: MediaQuery.of(context).size.width * 0.1,
                          ),
                          Text(
                            detail.title,
                            style: screenTitleStyleWhite,
                          ),
                          Text(
                            formattedActivityDateOnly(detail.strTime),
                            style: subHeaderStyleGrey,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth,
                      height: MediaQuery.of(context).size.height * 0.7,
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 20,
                        left: 20,
                        right: 20,
                      ),
                      decoration: BoxDecoration(
                        color: colorTheme,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Start time, end time, priority, total task, category, repeat
                            Container(
                              width: constraints.maxWidth,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              // Left side and right side
                              child: Row(
                                children: [
                                  // Left
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        // Start time
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.blue,
                                                ),
                                                child: Icon(
                                                  Icons.timer,
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Waktu Mulai",
                                                    style: textStyleGrey,
                                                  ),
                                                  Text(
                                                    formattedActivityTimeOnly(
                                                        detail.strTime),
                                                    style: textStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        // Priority
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.red,
                                                ),
                                                child: Icon(
                                                  Icons.priority_high,
                                                  color: Colors.red[900],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Prioritas",
                                                    style: textStyleGrey,
                                                  ),
                                                  Text(
                                                    formattedPriority(
                                                        detail.impType,
                                                        detail.urgType),
                                                    style: textStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        // Category
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.purple[400],
                                                ),
                                                child: Icon(
                                                  Icons.category_rounded,
                                                  color: Colors.purple[900],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Kategori",
                                                    style: textStyleGrey,
                                                  ),
                                                  Text(
                                                    detail.catName == ""
                                                        ? "Tidak ada"
                                                        : detail.catName,
                                                    style: textStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        // End time
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.yellow,
                                                ),
                                                child: Icon(
                                                  Icons.timelapse,
                                                  color: Colors.yellow[900],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Waktu selesai",
                                                    style: textStyleGrey,
                                                  ),
                                                  Text(
                                                    formattedActivityTimeOnly(
                                                        detail.endTime),
                                                    style: textStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        // Total task
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.green[100],
                                                ),
                                                child: Icon(
                                                  Icons.task_outlined,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Total sub tugas",
                                                    style: textStyleGrey,
                                                  ),
                                                  Text(
                                                    "${detail.tasks?.length ?? 0} sub tugas",
                                                    style: textStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        // Repeat (daily, never, etc)
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.cyan,
                                                ),
                                                child: Icon(
                                                  Icons.repeat,
                                                  color: Colors.cyan[900],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Ulangi",
                                                    style: textStyleGrey,
                                                  ),
                                                  Text(
                                                    detail.rptFreq == "Tidak"
                                                        ? detail.rptFreq
                                                        : "${detail.rptFreq} ${detail.rptDur}X",
                                                    style: textStyle,
                                                  ),
                                                ],
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
                            // Attachment Files - Title
                            Container(
                              margin: const EdgeInsets.only(
                                top: 5,
                              ),
                              width: constraints.maxWidth,
                              child: Text(
                                "File",
                                style: textStyleBold,
                              ),
                            ),
                            // Attachment Files - Content
                            SizedBox(
                              width: constraints.maxWidth,
                              // Wrap with SingleChildScrollView
                              child: detail.files!.isNotEmpty
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: detail.files!.map((file) {
                                          return GestureDetector(
                                            onTap: () {
                                              fileDownloadOpen(
                                                  file.path, file.name);
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              margin: const EdgeInsets.only(
                                                  right: 5),
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: Colors.white,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 2,
                                                    child: Icon(
                                                      Icons
                                                          .file_present_rounded,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    flex: 6,
                                                    child: Text(
                                                      file.name,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(), // Corrected here
                                      ),
                                    )
                                  : Container(
                                      width: constraints.maxWidth,
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                        right: 10,
                                        left: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        "Tidak ada file yang ditambahkan",
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                            // Task Activity - Title
                            Container(
                              margin: const EdgeInsets.only(
                                top: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Sub tugas",
                                style: textStyleBold,
                              ),
                            ),
                            // Task Activity - Content
                            SizedBox(
                              width: constraints.maxWidth,
                              child: detail.tasks!.isNotEmpty
                                  ? Container(
                                      width: constraints.maxWidth,
                                      padding: const EdgeInsets.all(10),
                                      alignment: Alignment.topLeft,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                      ),
                                      child: Column(
                                        children: detail.tasks!.map(
                                          (task) {
                                            // Task
                                            return Text(
                                              "- ${task.task}",
                                              style: textStyle,
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    )
                                  : Container(
                                      width: constraints.maxWidth,
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                        left: 10,
                                        right: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        "Tidak ada sub tugas yang ditambahkan",
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                            // Location Activity - Title
                            Container(
                              margin: const EdgeInsets.only(
                                top: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Lokasi",
                                style: textStyleBold,
                              ),
                            ),
                            // Location Activity - Content
                            SizedBox(
                              width: constraints.maxWidth,
                              child: detail.locations!.isNotEmpty
                                  ? Column(
                                      children: detail.locations!.map(
                                        (location) {
                                          // Address
                                          return Container(
                                            width: constraints.maxWidth,
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                              bottom: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: Colors.white,
                                            ),
                                            child: GestureDetector(
                                              // Link to open gmap and location address
                                              onTap: () {
                                                openGoogleMaps(
                                                    location.latitude,
                                                    location.longitude);
                                              },
                                              child: Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 2,
                                                    child: Icon(
                                                      Icons.location_on_sharp,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                    flex: 6,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          location.address,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ).toList(),
                                    )
                                  : Container(
                                      width: constraints.maxWidth,
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                        left: 10,
                                        right: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        "Tidak ada lokasi yang ditambahkan",
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                            // Notifications - Title
                            Container(
                              margin: const EdgeInsets.only(
                                top: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Pengingat kegiatan (Reminder)",
                                style: textStyleBold,
                              ),
                            ),
                            // Notifications - Content
                            SizedBox(
                              width: constraints.maxWidth,
                              child: detail.notif!.isNotEmpty
                                  ? Container(
                                      width: constraints.maxWidth,
                                      padding: const EdgeInsets.all(10),
                                      alignment: Alignment.topLeft,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                      ),
                                      child: Column(
                                        children: detail.notif!.map(
                                          (notif) {
                                            // Task
                                            return Text(
                                              "- Pengingat kegiatan ${notif.minute} menit",
                                              style: textStyle,
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    )
                                  : Container(
                                      width: constraints.maxWidth,
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                        left: 10,
                                        right: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        "Tidak ada pengingat kegiatan yang ditambahkan",
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Hapus Jadwal Kegiatan",
                                                style: subHeaderStyleBold,
                                              ),
                                              content: Text(
                                                'Apakah kamu yakin untuk menghapus jadwal kegiatan ini?',
                                                style: textStyle,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Batal',
                                                      style: textStyleBold),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteScheduledActivity(
                                                        detail.idAct);
                                                  },
                                                  child: Text(
                                                    'Hapus',
                                                    style: textStyleBold,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: constraints.maxWidth,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.white,
                                          border: Border.all(
                                            width: 1,
                                            color: const Color.fromARGB(
                                                255, 3, 0, 66),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.delete,
                                              color: Colors.black,
                                            ),
                                            Text(
                                              "Hapus",
                                              style: textStyleBold,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    flex: 4,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: ((context) =>
                                                    ActivityEditDetails(
                                                      actDetail: detail,
                                                    )))).then((result) {
                                          if (result == true) {
                                            // Data was added, refresh timer.dart
                                            Provider.of<ActivityTaskToday>(
                                                    context,
                                                    listen: false)
                                                .resetDataLoaded();
                                            Provider.of<ActivityTaskToday>(
                                                    context,
                                                    listen: false)
                                                .getListOfTodayActivities();
                                          }
                                        });
                                        setState(() {
                                          detailAct = getDetailActivity(
                                              widget.scheduledID);
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: constraints.maxWidth,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: const Color.fromARGB(
                                              255, 3, 0, 66),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                            ),
                                            Text(
                                              "Ubah Kegiatan",
                                              style: textStyleBoldWhite,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            );
          }
        },
      ),
    );
  }
}
