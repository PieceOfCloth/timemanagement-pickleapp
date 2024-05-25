import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'dart:math';
// import 'package:intl/intl.dart';
import 'dart:async';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:pickleapp/screen/class/task.dart';

import 'package:pickleapp/theme.dart';

class Timers extends StatefulWidget {
  @override
  TimersState createState() => TimersState();
}

class TimersState extends State<Timers> {
  int minuteWork = 25;
  int minuteBreak = 5;
  int second = 0;
  int minute = 0;
  int secondsWorkTotals = 0;
  String? activityID;
  // int secondsBreakTotals = 0;
  late Timer _timer;
  bool running = false;
  bool _isChecked = false;
  late DateTime _startTime;
  bool breakSession = false;
  bool _isStart = false;
  bool isFullScreen = false;
  List<Map<String, dynamic>> todayActivities = [];
  List<Tasks> tasks = [];

  // late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  /* ------------------------------------------------------------------------------------------------------------------- */

  void startTimer() {
    setState(() {
      minute = breakSession == false ? minuteWork : minuteBreak;
      _startTime = DateTime.now();
      _isStart = true;
      running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (breakSession == false) {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              secondsWorkTotals +=
                  DateTime.now().difference(_startTime).inSeconds;
              breakSession = true;
              second = 0;
              minute = 0;
              running = false;
              _isStart = false;
              print("Work total in seconds: $secondsWorkTotals");
            } else {
              minute--;
              second = 59;
            }
          } else {
            second--;
            if (second == 59) {
              minute--;
            }
          }
        } else {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              breakSession = false;
              second = 0;
              minute = 0;
              running = false;
              _isStart = false;
            } else {
              minute--;
              second = 59;
            }
          } else {
            second--;
            if (second == 59) {
              minute--;
            }
          }
        }
      });
    });
  }

  void resumeTimer() {
    setState(() {
      running = true;
      _startTime = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (breakSession == false) {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              secondsWorkTotals +=
                  DateTime.now().difference(_startTime).inSeconds;
              breakSession = true;
              second = 0;
              running = false;
              _isStart = false;
              print("Work total in seconds: $secondsWorkTotals");
            } else {
              minute--;
              second = 59;
            }
          } else {
            second--;
            if (second == 59) {
              minute--;
            }
          }
        } else {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              breakSession = false;
              second = 0;
              running = false;
              _isStart = false;
            } else {
              minute--;
              second = 59;
            }
          } else {
            second--;
            if (second == 59) {
              minute--;
            }
          }
        }
      });
    });
  }

  void pauseTimer() {
    _timer.cancel();
    setState(() {
      running = false;
      if (breakSession == false) {
        secondsWorkTotals += DateTime.now().difference(_startTime).inSeconds;
        print("Work total in seconds: $secondsWorkTotals");
      }
    });
  }

  void resetTimer() {
    _timer.cancel();
    setState(() {
      running = false;
      breakSession = false;
      // minuteBreak = 1;
      // minuteWork = 2;
      minute = 0; // ini nanti nilainya sama dengan minutework
      second = 0;
      _isStart = false;
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  // Show theory infographic in a alertdialog
  void _showTimerPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Set a Timer (In a minutes)",
                style: subHeaderStyle,
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
                          Tab(text: 'Work time'),
                          Tab(text: 'Break time'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: <Widget>[
                            // Work Minutes Picker
                            NumberPicker(
                              value: minuteWork,
                              minValue: 1,
                              maxValue: 480,
                              onChanged: (val) => setState(() {
                                minuteWork = val;
                              }),
                            ),
                            // Break Minutes Picker
                            NumberPicker(
                              value: minuteBreak,
                              minValue: 1,
                              maxValue: 480,
                              onChanged: (val) {
                                setState(() {
                                  minuteBreak = val;
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
              actions: <Widget>[
                // Save button
                TextButton(
                  onPressed: () {
                    print('Work minutes: $minuteWork');
                    print('Break minutes: $minuteBreak');
                    Navigator.of(context).pop();
                  },
                  child: const Text("Save"),
                ),
                // Cancel button
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

  /* ------------------------------------------------------------------------------------------------------------------- */

  Future<List<Map<String, dynamic>>> getListOfTodayActivities() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    Set<String> uniqueID = <String>{};
    todayActivities = [];

    final schQuery = await FirebaseFirestore.instance
        .collection('scheduled_activities')
        .where('actual_start_time', isGreaterThanOrEqualTo: start)
        .where('actual_end_time', isLessThan: end)
        .get();
    if (schQuery.docs.isNotEmpty) {
      for (var doc in schQuery.docs) {
        var actID = doc['activities_id'];
        if (!uniqueID.contains(actID)) {
          final actDoc = await FirebaseFirestore.instance
              .collection('activities')
              .doc(actID)
              .get();
          if (actDoc.exists) {
            var actData = actDoc.data()!;
            actData['id'] = actID;

            uniqueID.add(actID);
            todayActivities.add(actData);
          }
        }
      }
    }

    return todayActivities;
  }

  Future<List<Tasks>> getTaskListOfTodayActivities(String id) async {
    tasks = [];

    final taskQuery = await FirebaseFirestore.instance
        .collection('tasks')
        .where('activities_id', isEqualTo: id)
        .get();
    if (taskQuery.docs.isNotEmpty) {
      for (var doc in taskQuery.docs) {
        tasks.add(Tasks(
          id: doc.id,
          task: doc['title'],
          status: doc['status'],
        ));
      }
    }

    return tasks;
  }

  Future<void> updateStatusTask(String? id, bool? status) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(id)
        .update({'status': status});
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  Widget formattedActivityOption() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getListOfTodayActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: double.infinity,
            child: Align(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            width: double.infinity,
            child: Align(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            width: double.infinity,
            child: Align(
              child: Text("There aren't any activities for today"),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            child: DropdownButton<String>(
              items: snapshot.data!.map((act) {
                return DropdownMenuItem<String>(
                  value: act['id'],
                  child: Text(act['title']),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  activityID = v;
                });
              },
            ),
          );
        }
      },
    );
  }

  Widget formattedListofTask() {
    if (activityID != null) {
      return FutureBuilder<List<Tasks>>(
        future: getTaskListOfTodayActivities(activityID!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: double.infinity,
              child: Align(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return SizedBox(
              width: double.infinity,
              child: Align(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox(
              width: double.infinity,
              child: Align(
                child: Text("There aren't any activities for today"),
              ),
            );
          } else {
            return SizedBox(
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.purple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: snapshot.data![index].status,
                          onChanged: (value) {
                            setState(() {
                              snapshot.data![index].status = value!;
                            });
                            updateStatusTask(snapshot.data![index].id, value);
                          },
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            snapshot.data![index].task,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                decoration: _isChecked == true
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
        },
      );
    } else {
      return const SizedBox(
        width: double.infinity,
        child: Align(
          child: Text(
              "You haven't selected an activity or there are no activities today"),
        ),
      );
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    getListOfTodayActivities();
    print(todayActivities);
  }

  @override
  Widget build(BuildContext context) {
    String minutesStr = minute < 10 ? '0$minute' : '$minute';
    String secondsStr = second < 10 ? '0$second' : '$second';
    return GestureDetector(
      onTap: isFullScreen == true ? exitFullScreen : null,
      child: Scaffold(
        body: isFullScreen == true
            ? SafeArea(
                child: Container(
                  color: Colors.black, // Set background color
                  child: Center(
                    child: Row(
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
                            border: Border.all(
                              width: 1,
                              color: breakSession == false
                                  ? const Color.fromARGB(255, 166, 204, 255)
                                  : Colors.white,
                            ),
                            color: breakSession == false
                                ? Colors.white
                                : const Color.fromARGB(255, 166, 204, 255),
                          ),
                          child: Text(
                            minutesStr,
                            style: TextStyle(
                              fontSize: 110,
                              fontWeight: FontWeight.bold,
                              color: breakSession == false
                                  ? Colors.black
                                  : Colors.white,
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
                            color: Colors.white,
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
                            border: Border.all(
                              width: 1,
                              color: breakSession == false
                                  ? const Color.fromARGB(255, 166, 204, 255)
                                  : Colors.white,
                            ),
                            color: breakSession == false
                                ? Colors.white
                                : const Color.fromARGB(255, 166, 204, 255),
                          ),
                          child: Text(
                            secondsStr,
                            style: TextStyle(
                              fontSize: 110,
                              fontWeight: FontWeight.bold,
                              color: breakSession == false
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                margin: const EdgeInsets.only(
                  top: 40,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        breakSession == true
                            ? "Let's Break From Activity Name"
                            : "Let's Focus - Activity Name",
                        style: screenTitleStyle,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    formattedActivityOption(),
                    const SizedBox(
                      height: 5,
                    ),
                    formattedListofTask(),
                    const SizedBox(
                      height: 40,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
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
                              border: Border.all(
                                width: 1,
                                color: breakSession == false
                                    ? const Color.fromARGB(255, 166, 204, 255)
                                    : Colors.white,
                              ),
                              color: breakSession == false
                                  ? Colors.white
                                  : const Color.fromARGB(255, 166, 204, 255),
                            ),
                            child: Text(
                              minutesStr,
                              style: TextStyle(
                                fontSize: 110,
                                fontWeight: FontWeight.bold,
                                color: breakSession == false
                                    ? Colors.black
                                    : Colors.white,
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
                              color: Colors.black,
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
                              border: Border.all(
                                width: 1,
                                color: breakSession == false
                                    ? const Color.fromARGB(255, 166, 204, 255)
                                    : Colors.white,
                              ),
                              color: breakSession == false
                                  ? Colors.white
                                  : const Color.fromARGB(255, 166, 204, 255),
                            ),
                            child: Text(
                              secondsStr,
                              style: TextStyle(
                                fontSize: 110,
                                fontWeight: FontWeight.bold,
                                color: breakSession == false
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (running == true) {
                            pauseTimer();
                          } else {
                            if (_isStart == false) {
                              startTimer();
                            } else {
                              resumeTimer();
                            }
                          }
                        });
                      },
                      child: running == true
                          ? Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color:
                                      const Color.fromARGB(255, 166, 204, 255),
                                ),
                              ),
                              child: Text(
                                "Pause",
                                style: subHeaderStyle,
                              ),
                            )
                          : _isStart == false
                              ? Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color.fromARGB(
                                        255, 166, 204, 255),
                                  ),
                                  child: Text(
                                    "Start",
                                    style: subHeaderStyle,
                                  ),
                                )
                              : Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color.fromARGB(
                                        255, 166, 204, 255),
                                  ),
                                  child: Text(
                                    "Resume",
                                    style: subHeaderStyle,
                                  ),
                                ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (running == false) {
                            resetTimer();
                          }
                        });
                      },
                      child: running == true
                          ? Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                            )
                          : _isStart == false
                              ? Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                )
                              : Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      width: 1,
                                      color: Color.fromARGB(255, 48, 136, 251),
                                    ),
                                  ),
                                  child: Text(
                                    "Reset",
                                    style: subHeaderStyle,
                                  ),
                                ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.info,
                                    color: Colors.black,
                                  ),
                                  Text(
                                    "Lock Phone",
                                    style: textStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showTimerPicker(context);
                            },
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  color: Colors.black,
                                ),
                                Text(
                                  "Set a Timer",
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
                                  "Full Screen",
                                  style: textStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
