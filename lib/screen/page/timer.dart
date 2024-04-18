import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pickleapp/theme.dart';

class Timers extends StatefulWidget {
  @override
  TimersState createState() => TimersState();
}

class TimersState extends State<Timers> {
  int minuteWork = 2;
  int minuteBreak = 1;
  int second = 0;
  int minute = 0;
  late Timer _timer;
  bool running = false;
  bool _isChecked = false;
  late DateTime _startTime;
  bool breakSession = false;
  int secondsWorkTotals = 0;
  int secondsBreakTotals = 0;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  /* ------------------------------------------------------------------------------------------------------------------- */

  void startTimer() {
    setState(() {
      minute = breakSession == false ? minuteWork : minuteBreak;
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
              secondsBreakTotals +=
                  DateTime.now().difference(_startTime).inSeconds;
              breakSession = false;
              second = 0;
              running = false;
              print("Break total in seconds: $secondsBreakTotals");
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
      } else {
        secondsBreakTotals += DateTime.now().difference(_startTime).inSeconds;
        print("break total in seconds: $secondsBreakTotals");
      }
    });
  }

  void resetTimer() {
    pauseTimer();
    setState(() {
      breakSession = false;
      minuteBreak = 5;
      minuteWork = 25;
      second = 0;
    });
  }

  /* ------------------------------------------------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String minutesStr = minute < 10 ? '0$minute' : '$minute';
    String secondsStr = second < 10 ? '0$second' : '$second';
    return Scaffold(
      body: Container(
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
              child: Expanded(
                child: Text(
                  breakSession
                      ? "Let's Break From Activity Name"
                      : "Let's Focus - Activity Name",
                  style: headerStyle,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      width: 200,
                      alignment: Alignment.centerLeft,
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
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text("Task 1",
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    decoration: _isChecked == true
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Container(
                      width: 250,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(10),
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
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Task 1",
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Container(
                      width: 250,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(10),
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
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Task 1",
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Container(
                      width: 250,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(10),
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
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Task 1",
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 300,
                        height: 300,
                        child: CircularProgressIndicator(
                          value: second /
                              60, // calculates the progress as a value between 0 and 1
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            breakSession ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 100,
                        left: 70,
                        child: Text('$minutesStr : $secondsStr',
                            style: headerStyle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (running == true) {
                    pauseTimer();
                    running = false;
                  } else {
                    startTimer();
                    running = true;
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
                          color: const Color.fromARGB(255, 166, 204, 255),
                        ),
                      ),
                      child: Text(
                        "Pause",
                        style: subHeaderStyle,
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(255, 166, 204, 255),
                      ),
                      child: Text(
                        "Start",
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
                  if (!running) {
                    _startTime = DateTime.now();
                  }
                });
              },
              child: running == true
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
                          color: Color.fromARGB(255, 166, 204, 255),
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
                    onTap: () {},
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
                    onTap: () {},
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
    );
  }
}
