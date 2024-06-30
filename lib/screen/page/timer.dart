import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
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
  static const platform = MethodChannel('com.example.flutter_app/foreground');

  bool isFullScreen = false;
  bool isLocked = false;
  // final bool _isLocked = false;
  bool isDropDownDisable = false;

  // late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  /* ------------------------------------------------------------------------------------------------------------------- */

  Future<void> _keepAppInForeground() async {
    try {
      await platform.invokeMethod('keepAppInForeground');
    } on PlatformException catch (e) {
      print("Failed to keep app in foreground: '${e.message}'.");
    }
  }

  Color getPriorityColor(String important, String urgent) {
    if (important == "Important" && urgent == "Urgent") {
      return Colors.red;
    } else if (important == "Important" && urgent == "Not Urgent") {
      return Colors.yellow;
    } else if (important == "Not Important" && urgent == "Urgent") {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  void showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctxt) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: subHeaderStyleBold,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(ctxt).pop();
                },
              ),
            ],
          ),
          content: Text(
            message,
            style: textStyle,
          ),
        );
      },
    );
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
                  "Set a Timer (In a minutes)",
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
                              text: 'Work time',
                              icon: Icon(Icons.work),
                            ),
                            Tab(
                              text: 'Break time',
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
                    child: Text("Close", style: textStyleBold),
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
            title: Text(
              "Strict Mode",
              style: subHeaderStyleBold,
            ),
            icon: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
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
                    'Lock App',
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

  Future<void> _releaseForegroundLock() async {
    try {
      await platform.invokeMethod('releaseForegroundLock');
    } on PlatformException catch (e) {
      print("Failed to release foreground lock: '${e.message}'.");
    }
  }

  void _showLockScreen(String code) {
    screenLock(
      context: context,
      correctString: code,
      title: Text(
        'Wait till the time is up, you will get the code',
        style: subHeaderStyleBoldWhite,
      ),
      onUnlocked: () async {
        setState(() {
          // _isLocked = false;
        });
        await _releaseForegroundLock();
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
              "There aren't any activities for today",
              style: textStyleBold,
              textAlign: TextAlign.center,
            ),
          );
        } else {
          String? validActivityId = actState.todayActivities
                  .map((act) => act['id'])
                  .contains(actState.activityId)
              ? actState.activityId
              : null;

          return Container(
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
              value: validActivityId,
              isExpanded: true,
              hint: Text(
                "Choose your activity",
                style: textStyleGrey,
              ),
              items: actState.todayActivities.map((act) {
                return DropdownMenuItem<String>(
                  value: act['id'],
                  child: Text(
                    act['title'],
                    style: textStyle,
                  ),
                );
              }).toList(),
              onChanged: isDropDownDisable
                  ? null
                  : (v) {
                      setState(() {
                        actState.selectActivity(v);
                      });
                      actState.getTaskListOfTodayActivities();
                    },
            ),
          );
        }
      },
    );
  }

  Widget formattedListofTask(BuildContext context) {
    return Consumer<ActivityTaskToday>(builder: (context, actState, child) {
      if (actState.tasks.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 25),
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
                    Expanded(
                      child: Text(
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
                    ),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        return const SizedBox(width: double.infinity);
        // Container(
        //   padding: const EdgeInsets.only(
        //     left: 10,
        //     right: 10,
        //   ),
        //   alignment: Alignment.centerLeft,
        //   height: 50,
        //   width: double.infinity,
        //   decoration: BoxDecoration(
        //     border: Border.all(
        //       color: Colors.grey,
        //       width: 1.0,
        //     ),
        //     borderRadius: BorderRadius.circular(30),
        //   ),
        //   child: Text(
        //     "You haven't selected an activity or there are no tasks for your activity",
        //     style: textStyle,
        //     textAlign: TextAlign.center,
        //   ),
        // );
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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   Provider.of<ActivityTaskToday>(context, listen: false)
  //       .getListOfTodayActivities();
  // }

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
          body: isFullScreen == true
              ? SafeArea(
                  child: Container(
                    color: const Color.fromARGB(
                        255, 3, 0, 66), // Set background color
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            tmr.breakSession == true
                                ? "Time to Break"
                                : "Let's Focus",
                            // style: headlineStyleWhite,
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
                                  border: Border.all(
                                    width: 1,
                                    color: tmr.breakSession == false
                                        ? const Color.fromARGB(255, 255, 170, 0)
                                        : const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                  color: tmr.breakSession == false
                                      ? const Color.fromARGB(255, 255, 170, 0)
                                      : Colors.white,
                                ),
                                child: Text(
                                  minutesStr,
                                  style: TextStyle(
                                    fontSize: 110,
                                    fontWeight: FontWeight.bold,
                                    color: tmr.breakSession == false
                                        ? const Color.fromARGB(255, 3, 0, 66)
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
                                  color: Color.fromARGB(255, 255, 170, 0),
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
                                    color: tmr.breakSession == false
                                        ? const Color.fromARGB(255, 255, 170, 0)
                                        : const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                  color: tmr.breakSession == false
                                      ? const Color.fromARGB(255, 255, 170, 0)
                                      : Colors.white,
                                ),
                                child: Text(
                                  secondsStr,
                                  style: TextStyle(
                                    fontSize: 110,
                                    fontWeight: FontWeight.bold,
                                    color: tmr.breakSession == false
                                        ? const Color.fromARGB(255, 3, 0, 66)
                                        : const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(
                    top: 40,
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ),
                  child: Column(
                    children: [
                      formattedActivityOption(context),
                      formattedListofTask(context),
                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        width: double.infinity,
                        child: Text(
                          tmr.breakSession == true
                              ? "Time to Break"
                              : "Let's Focus",
                          style: screenTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          top: 10,
                          bottom: 100,
                        ),
                        width: double.infinity,
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
                        onTap: () {
                          setState(() {
                            if (tmr.running == true) {
                              tmr.pauseTimer(context);
                            } else {
                              if (act.activityId != null) {
                                if (tmr.isStart == false) {
                                  if (tmr.breakSession == false) {
                                    tmr.isLocked = isLocked;
                                    tmr.startTimer(context);
                                    isDropDownDisable = tmr.isDropDownDisable;
                                    if (isLocked == true) {
                                      _showLockScreen(tmr.code ?? "1234");
                                    }
                                  } else {
                                    tmr.startTimer(context);
                                    isDropDownDisable = tmr.isDropDownDisable;
                                  }
                                } else {
                                  if (tmr.breakSession == false) {
                                    tmr.isLocked = isLocked;
                                    tmr.resumeTimer(context);
                                    if (isLocked == true) {
                                      _showLockScreen(tmr.code ?? "1234");
                                    }
                                  } else {
                                    tmr.resumeTimer(context);
                                  }
                                }
                              } else {
                                showInfoDialog(
                                  "Cannot Start the Timer",
                                  "Please add any activity for today, to use the timer.",
                                );
                              }
                            }
                          });
                        },
                        child: tmr.running == true
                            ? Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                  left: 80,
                                  right: 80,
                                ),
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 3, 0, 66),
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
                                      'Pause',
                                      style: textStyleBold,
                                    ),
                                  ],
                                ),
                              )
                            : act.activityId != null
                                ? tmr.isStart == false
                                    ? Container(
                                        alignment: Alignment.center,
                                        width: double.infinity,
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
                                              'Start',
                                              style: textStyleBoldWhite,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        alignment: Alignment.center,
                                        width: double.infinity,
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
                                              'Resume',
                                              style: textStyleBoldWhite,
                                            ),
                                          ],
                                        ),
                                      )
                                : Container(
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(
                                      left: 80,
                                      right: 80,
                                    ),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color:
                                          const Color.fromARGB(255, 3, 0, 66),
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
                                          'Start',
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
                            ? const SizedBox(width: double.infinity)
                            : tmr.isStart == false
                                ? const SizedBox(width: double.infinity)
                                : Container(
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(
                                      top: 10,
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
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: act.activityId != null
                                ? [
                                    GestureDetector(
                                      onTap: tmr.breakSession == true
                                          ? () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "Can't locked the app when Break Session."),
                                                ),
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
                                            "Lock Phone",
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
                                  ]
                                : [
                                    GestureDetector(
                                      onTap: () {
                                        showInfoDialog(
                                          "Cannot Start the Timer",
                                          "Please add any activity for today, to use this timer feature.",
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.info,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            "Lock Phone",
                                            style: textStyleGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showInfoDialog(
                                          "Cannot Start the Timer",
                                          "Please add any activity for today, to use this timer feature.",
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.timer,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            "Set a Timer",
                                            style: textStyleGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showInfoDialog(
                                          "Cannot Start the Timer",
                                          "Please add any activity for today, to use this timer feature.",
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.fullscreen,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            "Full Screen",
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
                ),
        ),
      );
    });
  }
}
