// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:numberpicker/numberpicker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:pickleapp/screen/services/timer_state.dart';
import 'package:pickleapp/theme.dart';
import 'package:provider/provider.dart';

class Timers extends StatefulWidget {
  const Timers({super.key});

  @override
  TimersState createState() => TimersState();
}

class TimersState extends State<Timers> {
  bool isFullScreen = false;
  bool isLocked = false;
  // final bool _isLocked = false;
  bool isDropDownDisable = false;

  // late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  /* ------------------------------------------------------------------------------------------------------------------- */

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

  // Show theory infographic in a alertdialog
  void showTimerPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<TimerState>(builder: (context, tmr, child) {
              return AlertDialog(
                title: Text(
                  "Atur timer (Dalam menit)",
                  style: subHeaderStyleBold,
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: DefaultTabController(
                    length: 2, // Number of tabs
                    child: Column(
                      children: <Widget>[
                        const TabBar(
                          tabs: [
                            Tab(
                              text: 'Waktu fokus',
                              icon: Icon(Icons.work),
                            ),
                            Tab(
                              text: 'Waktu istirahat',
                              icon: Icon(Icons.single_bed),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: <Widget>[
                              // Work Minutes Picker
                              NumberPicker(
                                  value: tmr.minuteWork,
                                  minValue: 1,
                                  maxValue: 180,
                                  onChanged: (val) {
                                    setState(() {
                                      tmr.minuteWork = val;
                                    });
                                  }),
                              // Break Minutes Picker
                              NumberPicker(
                                value: tmr.minuteBreak,
                                minValue: 1,
                                maxValue: 180,
                                onChanged: (val) {
                                  setState(() {
                                    tmr.minuteBreak = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Tutup", style: textStyleBold),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  void showLockedChoice(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mode Fokus",
                  style: subHeaderStyleBold,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.05,
              child: Row(
                children: [
                  Checkbox(
                    value: isLocked,
                    onChanged: (v) {
                      setState(() {
                        isLocked = v!;
                      });
                    },
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Kunci perangkat',
                    style: textStyle,
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  void enterFullScreen() {
    setState(() {
      isFullScreen = true;
    });
  }

  void exitFullScreen() {
    setState(() {
      isFullScreen = false;
    });
  }

  void _showLockScreen(
      BuildContext context, String code, String menit, String detik) {
    screenLock(
      context: context,
      correctString: code,
      title: Text(
        'Silahkan tunggu hingga waktu habis untuk mendapatkan kode buka',
        style: subHeaderStyleBoldWhite,
      ),
      onUnlocked: () async {
        setState(() {
          // _isLocked = false;
        });
        Navigator.of(context).pop();
      },
      canCancel: false,
    );
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Widget formattedActivityOption(BuildContext context) {
    return Consumer<ActivityTaskToday>(
      builder: (context, actState, child) {
        if (actState.todayActivities.isEmpty) {
          return Container(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
            ),
            alignment: Alignment.center,
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "Tidak ada aktivitas untuk hari ini",
              style: textStyleBold,
              textAlign: TextAlign.center,
            ),
          );
        } else {
          String? validScheduleId = actState.todayActivities
                  .map((act) => act.idActivity)
                  .contains(actState.scheduleId)
              ? actState.scheduleId
              : null;

          return validScheduleId == ""
              ? Container(
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
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButton<String>(
                    value: validScheduleId,
                    isExpanded: true,
                    hint: Text(
                      "Pilih aktivitas kamu",
                      style: textStyleGrey,
                    ),
                    items: actState.todayActivities.map((act) {
                      return DropdownMenuItem<String>(
                        value: act.idActivity,
                        child: Text(
                          "${act.title} (${act.startTime} - ${act.startTime})",
                          style: textStyle,
                        ),
                      );
                    }).toList(),
                    onChanged: isDropDownDisable
                        ? null
                        : (v) {
                            setState(() {
                              actState.selectSchedule(v);
                            });
                            actState.getTaskListOfTodayActivities();
                            actState.getFileListOfTodayActivities();
                          },
                  ),
                )
              : Row(
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
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButton<String>(
                          value: validScheduleId,
                          isExpanded: true,
                          hint: Text(
                            "Pilih aktivitas kamu",
                            style: textStyleGrey,
                          ),
                          items: actState.todayActivities.map((act) {
                            return DropdownMenuItem<String>(
                              value: act.idActivity,
                              child: Text(
                                "${act.title} (${act.startTime} - ${act.endTime})",
                                style: textStyle,
                              ),
                            );
                          }).toList(),
                          onChanged: isDropDownDisable
                              ? null
                              : (v) {
                                  setState(() {
                                    actState.selectSchedule(v);
                                  });
                                  actState.getTaskListOfTodayActivities();
                                  actState.getFileListOfTodayActivities();
                                },
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selesai?",
                            style: textStyle,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Container(
                            alignment: Alignment.center,
                            child: Consumer<ActivityTaskToday>(
                              builder: (context, actState, child) {
                                var scheduleId = actState.scheduleId;
                                var activity = scheduleId == null
                                    ? null
                                    : actState.todayActivities.firstWhere(
                                        (act) =>
                                            act.idActivity ==
                                            actState.scheduleId);
                                return Checkbox(
                                  value: activity?.status ?? false,
                                  onChanged: activity == null
                                      ? null
                                      : (value) {
                                          setState(() {
                                            activity.status = value!;
                                            actState.updateStatusKegiatans(
                                                actState.scheduleId!,
                                                activity.status);
                                          });
                                        },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
        }
      },
    );
  }

  Widget formattedListofTask(BuildContext context) {
    return Consumer<ActivityTaskToday>(builder: (context, actState, child) {
      if (actState.tasks.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 10),
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: actState.tasks.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: actState.tasks[index].status,
                      onChanged: (value) {
                        setState(() {
                          actState.tasks[index].status = value!;
                        });
                        actState.updateStatusTask(
                            actState.tasks[index].id, value);
                      },
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      actState.tasks[index].task,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          decoration: actState.tasks[index].status == true
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        return const SizedBox(width: double.infinity);
      }
    });
  }

  Widget formattedListofFile(BuildContext context) {
    return Consumer<ActivityTaskToday>(builder: (context, actState, child) {
      if (actState.files.isNotEmpty) {
        print(actState.files);
        return Container(
          margin: const EdgeInsets.only(top: 5),
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: actState.files.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color.fromARGB(255, 3, 0, 66),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GestureDetector(
                  onTap: () {
                    fileDownloadOpen(
                        actState.files[index].path, actState.files[index].name);
                  },
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Icon(
                          Icons.file_present_rounded,
                          color: Colors.black,
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          actState.files[index].name,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      } else {
        return const SizedBox(width: double.infinity);
      }
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    // Provider.of<ActivityTaskToday>(context, listen: false).resetDataLoaded();
    Provider.of<ActivityTaskToday>(context, listen: false)
        .getListOfTodayActivities();
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    final act = Provider.of<ActivityTaskToday>(context, listen: false);
    return Consumer<TimerState>(builder: (context, tmr, child) {
      String minutesStr = tmr.minute < 10 ? '0${tmr.minute}' : '${tmr.minute}';
      String secondsStr = tmr.second < 10 ? '0${tmr.second}' : '${tmr.second}';
      return GestureDetector(
        onTap: isFullScreen == true ? exitFullScreen : null,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: isFullScreen == true
              ? SafeArea(
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Container(
                      color: tmr.breakSession == false
                          ? const Color.fromARGB(255, 3, 0, 66)
                          : Colors.white, // Set background color
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              tmr.breakSession == true
                                  ? "Waktunya Istirahat"
                                  : "Ayo Fokus",
                              style: tmr.breakSession == true
                                  ? headerStyleBold
                                  : headerStyleBoldWhite,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    left: 10,
                                    right: 10,
                                    bottom: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: tmr.breakSession == false
                                        ? Colors.white
                                        : const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                  child: Text(
                                    minutesStr,
                                    style: TextStyle(
                                      fontSize: 130,
                                      fontWeight: FontWeight.bold,
                                      color: tmr.breakSession == false
                                          ? const Color.fromARGB(255, 3, 0, 66)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  ":",
                                  style: TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.bold,
                                    color: tmr.breakSession == false
                                        ? Colors.white
                                        : const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    left: 10,
                                    right: 10,
                                    bottom: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: tmr.breakSession == false
                                        ? Colors.white
                                        : const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                  child: Text(
                                    secondsStr,
                                    style: TextStyle(
                                      fontSize: 130,
                                      fontWeight: FontWeight.bold,
                                      color: tmr.breakSession == false
                                          ? const Color.fromARGB(255, 3, 0, 66)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                )
              : SafeArea(
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      margin: const EdgeInsets.only(
                        top: 10,
                        left: 20,
                        right: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        children: [
                          formattedActivityOption(context),
                          formattedListofTask(context),
                          formattedListofFile(context),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: constraints.maxWidth,
                            child: Text(
                              tmr.breakSession == true
                                  ? "Waktunya Istirahat"
                                  : "Ayo Fokus",
                              style: screenTitleStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              top: 10,
                              bottom: 50,
                            ),
                            width: constraints.maxWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      width: 1,
                                      color: tmr.breakSession == false
                                          ? Colors.white
                                          : const Color.fromARGB(255, 3, 0, 66),
                                    ),
                                    color: tmr.breakSession == false
                                        ? const Color.fromARGB(255, 3, 0, 66)
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    minutesStr,
                                    style: TextStyle(
                                      fontSize: 130,
                                      fontWeight: FontWeight.bold,
                                      color: tmr.breakSession == false
                                          ? Colors.white
                                          : const Color.fromARGB(255, 3, 0, 66),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Text(
                                  ":",
                                  style: TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 3, 0, 66),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      width: 1,
                                      color: tmr.breakSession == false
                                          ? Colors.white
                                          : const Color.fromARGB(255, 3, 0, 66),
                                    ),
                                    color: tmr.breakSession == false
                                        ? const Color.fromARGB(255, 3, 0, 66)
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    secondsStr,
                                    style: TextStyle(
                                      fontSize: 130,
                                      fontWeight: FontWeight.bold,
                                      color: tmr.breakSession == false
                                          ? Colors.white
                                          : const Color.fromARGB(255, 3, 0, 66),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                if (tmr.running == true) {
                                  tmr.pauseTimer(context);
                                } else {
                                  if (act.scheduleId != null) {
                                    if (tmr.isStart == false) {
                                      if (tmr.breakSession == false) {
                                        tmr.isLocked = isLocked;
                                        tmr.generateRandomScreenCode();
                                        if (isLocked == true) {
                                          _showLockScreen(
                                              context,
                                              tmr.code ?? "1234",
                                              minutesStr,
                                              secondsStr);
                                        }
                                        tmr.startTimer(context);
                                        isDropDownDisable =
                                            tmr.isDropDownDisable;
                                      } else {
                                        tmr.startTimer(context);
                                        isDropDownDisable =
                                            tmr.isDropDownDisable;
                                      }
                                    } else {
                                      if (tmr.breakSession == false) {
                                        tmr.isLocked = isLocked;
                                        tmr.generateRandomScreenCode();
                                        if (isLocked == true) {
                                          _showLockScreen(
                                              context,
                                              tmr.code ?? "1234",
                                              minutesStr,
                                              secondsStr);
                                        }
                                        tmr.resumeTimer(context);
                                      } else {
                                        tmr.resumeTimer(context);
                                      }
                                    }
                                  } else {
                                    AlertInformation.showDialogBox(
                                      context: context,
                                      title: "Timer Tidak Dapat Dimulai",
                                      message:
                                          "Silahkan menambah aktivitasmu untuk dapat menggunakan timer.",
                                    );
                                  }
                                }
                              });
                            },
                            child: tmr.running == true
                                ? Container(
                                    alignment: Alignment.center,
                                    width: constraints.maxWidth,
                                    margin: const EdgeInsets.only(
                                      left: 80,
                                      right: 80,
                                    ),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color:
                                            const Color.fromARGB(255, 3, 0, 66),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.pause,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Jeda',
                                          style: textStyleBold,
                                        ),
                                      ],
                                    ),
                                  )
                                : act.scheduleId != null
                                    ? tmr.isStart == false
                                        ? Container(
                                            alignment: Alignment.center,
                                            width: constraints.maxWidth,
                                            margin: const EdgeInsets.only(
                                              left: 80,
                                              right: 80,
                                            ),
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: const Color.fromARGB(
                                                  255, 3, 0, 66),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Mulai',
                                                  style: textStyleBoldWhite,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container(
                                            alignment: Alignment.center,
                                            width: constraints.maxWidth,
                                            margin: const EdgeInsets.only(
                                              left: 80,
                                              right: 80,
                                            ),
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: const Color.fromARGB(
                                                  255, 3, 0, 66),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Lanjutkan',
                                                  style: textStyleBoldWhite,
                                                ),
                                              ],
                                            ),
                                          )
                                    : Container(
                                        alignment: Alignment.center,
                                        width: constraints.maxWidth,
                                        margin: const EdgeInsets.only(
                                          left: 80,
                                          right: 80,
                                        ),
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: const Color.fromARGB(
                                              255, 3, 0, 66),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Mulai',
                                              style: textStyleBoldWhite,
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (tmr.running == false) {
                                  tmr.resetTimer();
                                  isDropDownDisable = tmr.isDropDownDisable;
                                }
                              });
                            },
                            child: tmr.running == true
                                ? SizedBox(width: constraints.maxWidth)
                                : tmr.isStart == false
                                    ? SizedBox(width: constraints.maxWidth)
                                    : Container(
                                        alignment: Alignment.center,
                                        width: constraints.maxWidth,
                                        margin: const EdgeInsets.only(
                                          top: 10,
                                          left: 80,
                                          right: 80,
                                        ),
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                                255, 3, 0, 66),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.replay,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Reset',
                                              style: textStyleBold,
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                          Expanded(child: Container()),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: act.scheduleId != null
                                    ? [
                                        GestureDetector(
                                          onTap: tmr.breakSession == true
                                              ? () {
                                                  AlertInformation
                                                      .showDialogBox(
                                                    context: context,
                                                    title:
                                                        "Fitur Tidak Dapat Digunakan",
                                                    message:
                                                        "Kamu tidak dapat menggunakan fitur ini ketika sedang istirahat. Terima kasih.",
                                                  );
                                                }
                                              : () {
                                                  showLockedChoice(context);
                                                },
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.info,
                                                color: Colors.black,
                                              ),
                                              Text(
                                                "Mode Ketat",
                                                style: textStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            showTimerPicker(context);
                                          },
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.timer,
                                                color: Colors.black,
                                              ),
                                              Text(
                                                "Atur Timer",
                                                style: textStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            enterFullScreen();
                                          },
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.fullscreen,
                                                color: Colors.black,
                                              ),
                                              Text(
                                                "Layar Penuh",
                                                style: textStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                    : [
                                        GestureDetector(
                                          onTap: () {
                                            AlertInformation.showDialogBox(
                                              context: context,
                                              title:
                                                  "Timer Tidak Dapat Dimulai",
                                              message:
                                                  "Silahkan menambah aktivitasmu untuk dapat menggunakan timer.",
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.info,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                "Mode Ketat",
                                                style: textStyleGrey,
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            AlertInformation.showDialogBox(
                                              context: context,
                                              title:
                                                  "Timer Tidak Dapat Dimulai",
                                              message:
                                                  "Silahkan menambah aktivitasmu untuk dapat menggunakan timer.",
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.timer,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                "Atur Timer",
                                                style: textStyleGrey,
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            AlertInformation.showDialogBox(
                                              context: context,
                                              title:
                                                  "Timer Tidak Dapat Dimulai",
                                              message:
                                                  "Silahkan menambah aktivitasmu untuk dapat menggunakan timer.",
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.fullscreen,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                "Layar Penuh",
                                                style: textStyleGrey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      );
    });
  }
}
