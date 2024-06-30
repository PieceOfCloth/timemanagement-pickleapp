// ignore_for_file: avoid_print, avoid_types_as_parameter_names

import 'dart:core';
import 'dart:ffi';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/class/activity_log.dart';
import 'package:pickleapp/screen/class/log.dart';
import 'package:pickleapp/theme.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:table_calendar/table_calendar.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  ReportState createState() => ReportState();
}

class ReportState extends State<Report> {
  String timeFrame = "All";
  int touchedIndex = 0;
  // String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime theDay = DateTime.now();

  CalendarFormat calendarFormat = CalendarFormat.week;

  List<ActivityLog> logActivity = [];
  List<PriorityLog> logPriority = [];

  String getPriorityCategory(String importance, String urgent) {
    if (importance == "Important" && urgent == "Urgent") {
      return "Golf";
    } else if (importance == "Important" && urgent == "Not Urgent") {
      return "Pebbles";
    } else if (importance == "Not Important" && urgent == "Urgent") {
      return "Sand";
    } else {
      return "Water";
    }
  }

  Color getPriorityColor(String priorityType) {
    if (priorityType == 'Golf') {
      return Colors.red;
    } else if (priorityType == 'Pebbles') {
      return Colors.yellow;
    } else if (priorityType == 'Sand') {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  Color? getPriorityColorBurem(String priorityType) {
    if (priorityType == 'Golf') {
      return Colors.red[200];
    } else if (priorityType == 'Pebbles') {
      return Colors.yellow[200];
    } else if (priorityType == 'Sand') {
      return Colors.green[200];
    } else {
      return Colors.blue[200];
    }
  }

  String getPriorityScale(String priority) {
    if (priority == 'Golf') {
      return "Critical Priority";
    } else if (priority == 'Pebbles') {
      return "High Priority";
    } else if (priority == 'Sand') {
      return "Medium Priority";
    } else {
      return "Low Priority";
    }
  }

  Future<List<ActivityLog>> getActivityDailyLog() async {
    logActivity.clear();

    if (timeFrame == "All") {
      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_id', isEqualTo: userID)
          .get();
      for (var act in actSnap.docs) {
        var actID = act.id;
        var impt = act['important_type'];
        var urgnt = act['urgent_type'];

        QuerySnapshot schedSnap = await FirebaseFirestore.instance
            .collection('scheduled_activities')
            .where('activities_id', isEqualTo: actID)
            .get();

        int totalPlannedTime = 0;

        for (var sched in schedSnap.docs) {
          var start = (sched['actual_start_time'] as Timestamp).toDate();
          var end = (sched['actual_end_time'] as Timestamp).toDate();

          totalPlannedTime += end.difference(start).inSeconds;
        }

        if (totalPlannedTime > 0) {
          QuerySnapshot logActSnap = await FirebaseFirestore.instance
              .collection('logs')
              .where('activities_id', isEqualTo: actID)
              .get();

          if (logActSnap.docs.isNotEmpty) {
            for (var log in logActSnap.docs) {
              // var logID = log.id;
              // var priority =
              //     getPriorityCategory(impt.toString(), urgnt.toString());
              var sec = log['actual_time_spent'];

              logActivity.add(ActivityLog(
                title: act['title'],
                timePlan: totalPlannedTime,
                timeSpent: sec,
                type: getPriorityCategory(impt, urgnt),
              ));
            }
          }
        }
      }
    } else {
      DateTime startOfDay = DateTime(theDay.year, theDay.month, theDay.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_id', isEqualTo: userID)
          .get();
      for (var act in actSnap.docs) {
        var actID = act.id;
        var impt = act['important_type'];
        var urgnt = act['urgent_type'];

        int totalPlannedTime = 0;

        QuerySnapshot schedSnap = await FirebaseFirestore.instance
            .collection('scheduled_activities')
            .where('activities_id', isEqualTo: actID)
            .where('actual_start_time',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('actual_start_time',
                isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (var sched in schedSnap.docs) {
          var start = (sched['actual_start_time'] as Timestamp).toDate();
          var end = (sched['actual_end_time'] as Timestamp).toDate();

          totalPlannedTime += end.difference(start).inSeconds;
        }

        if (totalPlannedTime > 0) {
          QuerySnapshot logActSnap = await FirebaseFirestore.instance
              .collection('logs')
              .where('activities_id', isEqualTo: actID)
              .get();

          if (logActSnap.docs.isNotEmpty) {
            for (var log in logActSnap.docs) {
              // var logID = log.id;
              // var priority =
              //     getPriorityCategory(impt.toString(), urgnt.toString());
              var sec = log['actual_time_spent'];

              logActivity.add(ActivityLog(
                title: act['title'],
                timePlan: totalPlannedTime,
                timeSpent: sec,
                type: getPriorityCategory(impt, urgnt),
              ));
            }
          }
        }
      }
    }

    return logActivity;
  }

  Future<List<PriorityLog>> getPriorityLog() async {
    logPriority.clear();

    logPriority = [
      PriorityLog(type: 'Golf', timeSpent: 0),
      PriorityLog(type: 'Pebbles', timeSpent: 0),
      PriorityLog(type: 'Sand', timeSpent: 0),
      PriorityLog(type: 'Water', timeSpent: 0),
    ];

    if (timeFrame == "All") {
      QuerySnapshot logSnap =
          await FirebaseFirestore.instance.collection('logs').get();
      QuerySnapshot actSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_id', isEqualTo: userID)
          .get();

      Map<String, Map<String, String>> activityMap = {};
      for (var doc in actSnap.docs) {
        activityMap[doc.id] = {
          'important_type': doc['important_type'],
          'urgent_type': doc['urgent_type'],
        };
      }

      for (var logDoc in logSnap.docs) {
        String activityId = logDoc['activities_id'];
        int actualTimeSpent = logDoc['actual_time_spent'];

        if (activityMap.containsKey(activityId)) {
          String importantType = activityMap[activityId]!['important_type']!;
          String urgentType = activityMap[activityId]!['urgent_type']!;
          String priorityCategory =
              getPriorityCategory(importantType, urgentType);

          for (var priorityLog in logPriority) {
            if (priorityLog.type == priorityCategory) {
              priorityLog.timeSpent += actualTimeSpent;
            }
          }
        }
      }
    } else {
      DateTime startOfDay = DateTime(theDay.year, theDay.month, theDay.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot schedSnap = await FirebaseFirestore.instance
          .collection('scheduled_activities')
          .where('actual_start_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('actual_start_time', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var schedDoc in schedSnap.docs) {
        var actID = schedDoc['activities_id'];
        print(actID);

        QuerySnapshot actSnap = await FirebaseFirestore.instance
            .collection('activities')
            .where('user_id', isEqualTo: userID)
            .get();

        Map<String, Map<String, String>> activityMap = {};
        for (var doc in actSnap.docs) {
          if (actID == doc.id) {
            activityMap[doc.id] = {
              'important_type': doc['important_type'],
              'urgent_type': doc['urgent_type'],
            };
          }
        }

        print(activityMap);

        QuerySnapshot logSnap = await FirebaseFirestore.instance
            .collection('logs')
            .where("activities_id")
            .get();

        for (var logDoc in logSnap.docs) {
          String activityId = logDoc['activities_id'];
          int actualTimeSpent = logDoc['actual_time_spent'];
          print("actual time spent: $actualTimeSpent");

          if (activityMap.containsKey(activityId)) {
            String importantType = activityMap[activityId]!['important_type']!;
            String urgentType = activityMap[activityId]!['urgent_type']!;
            String priorityCategory =
                getPriorityCategory(importantType, urgentType);

            for (var priorityLog in logPriority) {
              if (priorityLog.type == priorityCategory) {
                priorityLog.timeSpent += actualTimeSpent;
              }
            }
          }
        }
      }
    }
    return logPriority;
  }

  int calculateTotalTimeSpent(List<PriorityLog> logPriority) {
    int totalTimeSpent = 0;
    for (PriorityLog log in logPriority) {
      totalTimeSpent += log.timeSpent;
    }
    return totalTimeSpent;
  }

  String formatTime(int detik) {
    // int hour = detik ~/ 3600;
    int minute = detik ~/ 60;
    int second = detik % 60;

    // if (minute >= 60) {
    //   minute = minute % 60;
    // }

    return '${minute.toString().padLeft(2, '0')} m : ${second.toString().padLeft(2, '0')} s';
  }

  Widget radialChart(BuildContext context) {
    return FutureBuilder<List<PriorityLog>>(
        future: getPriorityLog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pie_chart),
                Text("No Data", style: subHeaderStyle),
              ],
            );
          } else {
            final logPri = snapshot.data!;
            print(logPri);
            int totalTime = calculateTotalTimeSpent(logPri);
            print("Total Time: $totalTime");
            bool allZero = logPri.every((log) => log.timeSpent == 0);

            if (allZero) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pie_chart),
                  Text("No Data", style: subHeaderStyle),
                ],
              );
            } else {
              return Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.width * 0.6,
                    child: PieChart(
                      PieChartData(
                        borderData: FlBorderData(
                          show: false,
                        ),
                        sectionsSpace: 0,
                        centerSpaceRadius: 0,
                        sections: logPri.map((log) {
                          return PieChartSectionData(
                            color: getPriorityColor(log.type),
                            value: log.timeSpent / totalTime * 100,
                            title:
                                '${(log.timeSpent / totalTime * 100).toStringAsFixed(1)}%',
                            titleStyle: textStyleBold,
                            radius: 100.0,
                            badgePositionPercentageOffset: 0.98,
                            badgeWidget: AnimatedContainer(
                              duration: PieChart.defaultDuration,
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.5),
                                    offset: const Offset(3, 3),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(40 * .15),
                              child: Center(
                                child: Image.asset(
                                  getPriorityImage(log.type),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      bottom: 5,
                    ),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: logPri.map((log) {
                          return Container(
                            margin: const EdgeInsets.only(
                              right: 5,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(10),
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.width * 0.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: getPriorityColor(log.type),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    getPriorityImage(log.type),
                                  ),
                                ),
                                Text(
                                  "${log.type} (${getPriorityScale(log.type)})",
                                  style: textStyle,
                                ),
                                Expanded(
                                  child: Text(
                                    formatTime(log.timeSpent),
                                    style: textStyleBold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }
          }
        });
  }

  Widget verticalBarChart(BuildContext context) {
    return FutureBuilder(
        future: getActivityDailyLog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == []) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pie_chart),
                Text("No Data", style: subHeaderStyle),
              ],
            );
          } else {
            final actPri = snapshot.data!;
            print(actPri);
            bool allZero = actPri.isEmpty;

            if (allZero) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pie_chart),
                  Text("No Data", style: subHeaderStyle),
                ],
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: actPri.length *
                      120.0, // Adjust the width based on the number of bars
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.white,
                          tooltipHorizontalAlignment:
                              FLHorizontalAlignment.right,
                          tooltipMargin: -10,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final act = actPri[groupIndex];
                            String tooltipText = '';

                            // Determine which bar was clicked based on rodIndex
                            if (rodIndex == 0) {
                              // First bar (timePlan)
                              tooltipText =
                                  'Time Plan:\n${formatTime(rod.toY.toInt())}';
                            } else if (rodIndex == 1) {
                              tooltipText =
                                  'Actual Spent:\n${formatTime(rod.toY.toInt())}';
                            }
                            return BarTooltipItem(
                              '${act.title}\n',
                              textStyleBold,
                              children: <TextSpan>[
                                TextSpan(
                                  text: tooltipText,
                                  style: textStyle,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      alignment: BarChartAlignment.spaceBetween,
                      borderData: FlBorderData(
                        show: true,
                        border: const Border.symmetric(
                          horizontal: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          drawBelowEverything: true,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 90,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                formatTime(value.toInt()),
                                textAlign: TextAlign.left,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              );
                              Widget text;
                              if (value.toInt() >= 0 &&
                                  value.toInt() < actPri.length) {
                                text = Text(
                                  actPri[value.toInt()].title ?? "",
                                  style: style,
                                );
                              } else {
                                text = const Text("", style: style);
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 16,
                                child: text,
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 120, // Adjust as per your design
                            getTitlesWidget: (value, meta) {
                              // Return the title text based on the
                              return const Text("");
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60, // Adjust as per your design
                            getTitlesWidget: (value, meta) {
                              // Return the title text based on the
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Colors.grey,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(
                        actPri.length,
                        (i) {
                          final act = actPri[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: act.timePlan!.toDouble(),
                                color: getPriorityColor(act.type ?? ""),
                                width: 30,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 20,
                                  color: Colors.yellow.withOpacity(0.3),
                                ),
                              ),
                              BarChartRodData(
                                toY: act.timeSpent!.toDouble(),
                                color: getPriorityColorBurem(act.type ?? ""),
                                width: 30,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 20,
                                  color: Colors.yellow.withOpacity(0.3),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        });
  }

  String getPriorityImage(String type) {
    if (type == 'Golf') {
      return 'assets/golfBall_1.png';
    } else if (type == 'Pebbles') {
      return 'assets/pebbles_1.png';
    } else if (type == 'Sand') {
      return 'assets/sand_1.png';
    } else {
      return 'assets/water_1.png';
    }
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    if (value.toInt() >= 0 && value.toInt() < logActivity.length) {
      text = Text(
        logActivity[value.toInt()].title ?? "",
        style: style,
      );
    } else {
      text = const Text("", style: style);
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: text,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // int totalTime = logPriority.fold(0, (sum, item) => sum + item.timeSpent);
    // String formattedTotalTime = formatTime(totalTime);
    bool allTimeSpentZero = logPriority.every((log) => log.timeSpent == 0);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 66),
      body: Container(
        margin: const EdgeInsets.only(
          top: 40,
          left: 20,
          right: 20,
        ),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  "Activity Reports",
                  style: screenTitleStyleWhite,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                ),
                alignment: Alignment.centerLeft,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField(
                  isExpanded: true,
                  value: timeFrame,
                  hint: Text(
                    "Choose the time frame",
                    style: textStyleWhite,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: "All",
                      child: Text(
                        "All",
                        style: textStyle,
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Daily",
                      child: Text(
                        "Daily",
                        style: textStyle,
                      ),
                    ),
                  ],
                  onChanged: (v) async {
                    setState(() {
                      timeFrame = v!;
                      theDay = DateTime.now();
                      print(timeFrame);
                    });
                  },
                ),
              ),
              timeFrame == "All"
                  ? const SizedBox()
                  : Container(
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      child: TableCalendar(
                        focusedDay: _focusedDay,
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        calendarFormat: calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            theDay = _selectedDay;
                            // _selectedDate =
                            //     DateFormat("yyyy-MM-dd").format(selectedDay);
                            // getActivityDailyLog();
                            // getPriorityLog();
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle: subHeaderStyleBoldWhite,
                          weekendTextStyle: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          selectedTextStyle: subHeaderStyleBold,
                          todayTextStyle: subHeaderStyleBold,
                          todayDecoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerVisible: true,
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          titleTextStyle: subHeaderStyleBoldWhite,
                          formatButtonVisible: false,
                          formatButtonShowsNext: false,
                        ),
                      ),
                    ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                padding: const EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Priority Time Usage",
                        style: subHeaderStyleBold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.width * 0.85,
                        child: radialChart(context),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Time Usage by Activities",
                  style: subHeaderStyleBoldWhite,
                ),
              ),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: verticalBarChart(context),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
