import 'package:flutter/material.dart';
import 'dart:async';

class TimerState extends ChangeNotifier {
  int minuteWork = 25;
  int minuteBreak = 5;
  int second = 0;
  int minute = 0;
  int secondsWorkTotals = 0;
  late Timer _timer;
  bool running = false;
  late DateTime _startTime;
  bool breakSession = false;
  bool _isStart = false;

  void startTimer() {
    minute = breakSession == false ? minuteWork : minuteBreak;
    _startTime = DateTime.now();
    _isStart = true;
    running = true;
    notifyListeners();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
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
      },
    );
  }

  void resumeTimer() {
    running = true;
    _startTime = DateTime.now();
    notifyListeners();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
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
      },
    );
  }

  void pauseTimer() {
    notifyListeners();
    _timer.cancel();

    running = false;
    if (breakSession == false) {
      secondsWorkTotals += DateTime.now().difference(_startTime).inSeconds;
      print("Work total in seconds: $secondsWorkTotals");
    }
  }

  void resetTimer() {
    _timer.cancel();
    notifyListeners();
    running = false;
    breakSession = false;
    // minuteBreak = 1;
    // minuteWork = 2;
    minute = 0; // ini nanti nilainya sama dengan minutework
    second = 0;
    _isStart = false;
  }
}
