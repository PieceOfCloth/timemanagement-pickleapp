// ignore_for_file: avoid_print, use_build_context_synchronously
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'dart:async';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:provider/provider.dart';

class TimerState extends ChangeNotifier {
  int minuteWork = 25;
  int minuteBreak = 5;
  int second = 0;
  int minute = 0;
  int secondsWorkTotals = 0;
  Timer? _timer;
  bool running = false;
  late DateTime startTime;
  bool breakSession = false;
  bool isStart = false;
  String? code;
  bool isLocked = false;
  bool isDropDownDisable = false;

  notifTimer(int s, int m) {
    String menit = m < 10 ? '0$m' : '$m';
    String detik = s < 10 ? '0$s' : '$s';
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'timer_reminder',
        title: breakSession == true
            ? "Mari Istirahat Sejenak"
            : "Waktunya Untuk Fokus",
        body: "$menit : $detik",
        backgroundColor: const Color.fromARGB(255, 255, 170, 0),
        notificationLayout: NotificationLayout.BigText,
        criticalAlert: true,
        wakeUpScreen: false,
        locked: true,
        category: NotificationCategory.StopWatch,
        icon: 'resource://drawable/applogo',
      ),
    );
  }

  secretCode(String kode) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'code_reminder',
        title: 'Waktu Telah Habis',
        body:
            'Waktu fokus telah selesai. Silahkan untuk memasukkan kode: $code untuk dapat membuka kunci. Terima kasih.',
        wakeUpScreen: true,
        backgroundColor: const Color.fromARGB(255, 255, 170, 0),
        notificationLayout: NotificationLayout.BigText,
        criticalAlert: true,
        category: NotificationCategory.Message,
      ),
    );
  }

  void startTimer(BuildContext context) async {
    minute = breakSession == false ? minuteWork : minuteBreak;
    startTime = DateTime.now();
    isStart = true;
    running = true;
    isDropDownDisable = true;

    if (running == true) {
      AwesomeNotifications().dismiss(2);
    }

    if (breakSession == false) {
      if (isLocked == true) {
        await startKioskMode();
      }
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (breakSession == false) {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              if (isLocked == true) {
                await stopKioskMode();
                secretCode(code ?? "1234");
              }
              secondsWorkTotals =
                  DateTime.now().difference(startTime).inSeconds - 1;
              breakSession = true;
              // KioskModeManager.stopKioskMode();
              second = 0;
              minute = 0;
              running = false;
              isStart = false;
              print("Work total in seconds: $secondsWorkTotals");
              Provider.of<ActivityTaskToday>(context, listen: false)
                  .addActivityLog(secondsWorkTotals);
              AwesomeNotifications().dismiss(1);
            } else {
              minute--;
              second = 59;
              if (isLocked == false) {
                notifTimer(second, minute);
              }
            }
          } else {
            second--;
            if (isLocked == false) {
              notifTimer(second, minute);
            }
            if (second == 59) {
              minute--;
              if (isLocked == false) {
                notifTimer(second, minute);
              }
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
              isStart = false;
              AwesomeNotifications().dismiss(1);
              // stopSound();
              // playStopSound();
            } else {
              minute--;
              second = 59;
              notifTimer(second, minute);
            }
          } else {
            second--;
            notifTimer(second, minute);
            if (second == 59) {
              minute--;
              notifTimer(second, minute);
            }
          }
        }
        notifyListeners();
      },
    );
  }

  void resumeTimer(BuildContext context) async {
    running = true;
    startTime = DateTime.now();

    // playTimerSound()

    if (running == true) {
      AwesomeNotifications().dismiss(2);
    }

    if (breakSession == false) {
      if (isLocked == true) {
        await startKioskMode();
      }
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (breakSession == false) {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              if (isLocked == true) {
                await stopKioskMode();
                secretCode(code ?? "1234");
              }
              secondsWorkTotals =
                  DateTime.now().difference(startTime).inSeconds - 1;
              breakSession = true;
              second = 0;
              running = false;
              isStart = false;
              print("Work total in seconds: $secondsWorkTotals");
              Provider.of<ActivityTaskToday>(context, listen: false)
                  .addActivityLog(secondsWorkTotals);
              AwesomeNotifications().dismiss(1);
            } else {
              minute--;
              second = 59;
              if (isLocked == false) {
                notifTimer(second, minute);
              }
            }
          } else {
            second--;
            if (isLocked == false) {
              notifTimer(second, minute);
            }
            if (second == 59) {
              minute--;
              if (isLocked == false) {
                notifTimer(second, minute);
              }
            }
          }
        } else {
          if (second < 1) {
            if (minute < 1) {
              timer.cancel();
              breakSession = false;
              second = 0;
              running = false;
              isStart = false;
              AwesomeNotifications().dismiss(1);
              // stopSound();
              // playStopSound();
            } else {
              minute--;
              second = 59;
              notifTimer(second, minute);
            }
          } else {
            second--;
            notifTimer(second, minute);
            if (second == 59) {
              minute--;
              notifTimer(second, minute);
            }
          }
        }
        notifyListeners();
      },
    );
  }

  void pauseTimer(BuildContext context) {
    notifyListeners();
    _timer?.cancel();
    notifTimer(second, minute);

    // stopSound();
    // playStopSound();
    // _stopKioskMode();

    running = false;
    if (breakSession == false) {
      secondsWorkTotals = DateTime.now().difference(startTime).inSeconds;
      print("Work total in seconds: $secondsWorkTotals");
      Provider.of<ActivityTaskToday>(context, listen: false)
          .addActivityLog(secondsWorkTotals);
    }
  }

  void resetTimer() {
    _timer?.cancel();
    running = false;
    breakSession = false;
    isDropDownDisable = false;

    // minuteBreak = 1;
    // minuteWork = 2;
    minute = 0; // ini nanti nilainya sama dengan minutework
    second = 0;
    secondsWorkTotals = 0;
    isStart = false;
    AwesomeNotifications().dismiss(1);
    notifyListeners();
  }

  void generateRandomScreenCode() {
    Random rand = Random();
    code = List.generate(4, (_) => rand.nextInt(10).toString()).join();
  }
}
