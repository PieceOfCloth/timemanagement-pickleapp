import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/screen/class/algoritma_class_list.dart';
import 'package:pickleapp/screen/class/algorithm_schedule.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Change format time to hh:mm PM/AM
  DateTime formattedActivityTimeOnly(String inptTime) {
    DateTime formattedTime = DateFormat("hh:mm a").parse(inptTime);

    return formattedTime;
  }

  List<AddActivityList> addActivity = [
    AddActivityList(title: 'A', priority: 1, duration: 45, start: "07:00 AM"),
    AddActivityList(title: 'B', priority: 5, duration: 5, start: "09:00 AM"),
    AddActivityList(title: 'C', priority: 3, duration: 15, start: "08:00 AM"),
    AddActivityList(title: 'D', priority: 2, duration: 60, start: "07:30 AM"),
    AddActivityList(title: 'E', priority: 4, duration: 60, start: "07:45 AM"),
  ];

  List<AlgorithmSchedule> schedule = [];
  List<AddActivityList> remaining = [];

  void testAlgoritma() {
    // Sort the initial list by start time
    // AddActivity.sort((a, b) => a.start.compareTo(b.start));

    // addActivity.sort((a, b) => formattedActivityTimeOnly(a.start)
    //     .compareTo(formattedActivityTimeOnly(b.start)));

    // // int currentTime = AddActivity.isNotEmpty ? AddActivity.first.start : 0;

    // DateTime currentTime = addActivity.isNotEmpty
    //     ? formattedActivityTimeOnly(addActivity.first.start)
    //     : formattedActivityTimeOnly("06:00 AM");

    // while (addActivity.isNotEmpty) {
    //   AddActivityList currentActivity = addActivity.removeAt(0);

    //   // if (currentTime <= currentActivity.start) {
    //   // while (currentActivity.duration > 0) {
    //   //   if (AddActivity.isNotEmpty &&
    //   //       AddActivity.first.start <= currentTime + 1) {
    //   if (currentTime
    //           .isBefore(formattedActivityTimeOnly(currentActivity.start)) ||
    //       currentTime.isAtSameMomentAs(
    //           formattedActivityTimeOnly(currentActivity.start))) {
    //     while (currentActivity.duration > 0) {
    //       if (addActivity.isNotEmpty &&
    //           (formattedActivityTimeOnly(addActivity.first.start)
    //                   .isBefore(currentTime.add(const Duration(minutes: 1))) ||
    //               formattedActivityTimeOnly(addActivity.first.start)
    //                   .isAtSameMomentAs(
    //                       currentTime.add(const Duration(minutes: 1))))) {
    //         // AddActivityList nextActivity = AddActivity.first;
    //         AddActivityList nextActivity = addActivity.first;

    //         if (nextActivity.priority > currentActivity.priority) {
    //           schedule.add(AlgorithmSchedule(
    //             title: currentActivity.title,
    //             start: currentTime,
    //             end: currentTime.add(const Duration(minutes: 1)),
    //           ));
    //           remaining.add(AddActivityList(
    //             title: currentActivity.title,
    //             priority: currentActivity.priority,
    //             duration: currentActivity.duration - 1,
    //             start: "Halo",
    //           ));
    //           currentTime = currentTime.add(const Duration(minutes: 1));
    //           break;
    //         } else {
    //           currentActivity.duration -= 1;
    //           schedule.add(AlgorithmSchedule(
    //             title: currentActivity.title,
    //             start: currentTime,
    //             end: currentTime.add(const Duration(minutes: 1)),
    //           ));
    //           currentTime = currentTime.add(const Duration(minutes: 1));
    //         }
    //       } else {
    //         currentActivity.duration -= 1;
    //         schedule.add(AlgorithmSchedule(
    //           title: currentActivity.title,
    //           start: currentTime,
    //           end: currentTime.add(const Duration(minutes: 1)),
    //         ));
    //         currentTime = currentTime.add(const Duration(minutes: 1));
    //       }
    //     }
    //   } else {
    //     remaining.add(AddActivityList(
    //       title: currentActivity.title,
    //       priority: currentActivity.priority,
    //       duration: currentActivity.duration,
    //       start: "Halo",
    //     ));
    //   }
    // }

    // // Process remaining activities based on priority
    // while (remaining.isNotEmpty) {
    //   remaining.sort((a, b) => b.priority.compareTo(a.priority));
    //   AddActivityList currentActivity = remaining.removeAt(0);
    //   while (currentActivity.duration > 0) {
    //     currentActivity.duration -= 1;
    //     schedule.add(AlgorithmSchedule(
    //       title: currentActivity.title,
    //       start: currentTime,
    //       end: currentTime.add(const Duration(minutes: 1)),
    //     ));
    //     currentTime = currentTime.add(const Duration(minutes: 1));
    //   }
    // }

    // // Group and print the schedule
    // Map<String, List<AlgorithmSchedule>> groupedSchedule = {};

    // for (var s in schedule) {
    //   if (!groupedSchedule.containsKey(s.title)) {
    //     groupedSchedule[s.title] = [];
    //   }
    //   groupedSchedule[s.title]!.add(s);
    // }

    // for (var entry in groupedSchedule.entries) {
    //   String title = entry.key;
    //   List<AlgorithmSchedule> times = entry.value;

    //   DateTime start = times.first.start;
    //   DateTime end = times.first.end;

    //   for (int i = 1; i < times.length; i++) {
    //     if (times[i].start == end) {
    //       end = times[i].end;
    //     } else {
    //       print(
    //           '$title: ${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}');
    //       start = times[i].start;
    //       end = times[i].end;
    //     }
    //   }

    //   print(
    //       '$title: ${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}');
    // }

    // for (var s in schedule) {
    //   print(
    //       "${s.title}: ${DateFormat('hh:mm a').format(s.start)} - ${DateFormat('hh:mm a').format(s.end)}");
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          testAlgoritma();
        },
        child: const Text("Click this to print the result"),
      ),
    );
  }
}
