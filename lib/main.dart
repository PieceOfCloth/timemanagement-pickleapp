// ignore_for_file: must_be_immutable

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:pickleapp/screen/services/timer_state.dart';
import 'package:pickleapp/screen/page/onboarding.dart';
import 'package:pickleapp/theme.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pickleapp/firebase_options.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:shared_preferences/shared_preferences.dart';

import 'screen/page/home.dart';
import 'screen/page/timer.dart';
import 'screen/page/pickle.dart';
import 'screen/page/report.dart';
import 'screen/page/profile.dart';

Future<void> main() async {
  AwesomeNotifications().initialize(
    'resource://drawable/applogo',
    [
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'activity_reminder',
        channelName: 'Activity Reminder Notification Channel',
        channelDescription: "Pickle App - activities reminder",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.Max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: false,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'timer_reminder',
        channelName: 'Timer Count Down Notification Channel',
        channelDescription: "Pickle App - timer countdown",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.Max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: true,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'code_reminder',
        channelName: 'Secret Code for Timer Count Down Notification Channel',
        channelDescription: "Pickle App - secret code for locked app",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'daily_reminder',
        channelName: 'Reminder for you to make your daily plan',
        channelDescription: "Pickle App - Remider to make a schedule",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
      ),
    ],
    debug: true,
  );
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(const Duration(seconds: 10));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate();
  FlutterNativeSplash.remove();
  // Dipakai untuk check apakah user telah login atau belum
  // checkUser().then((String result) {
  //   if (result == '')
  //     runApp(
  //       const MaterialApp(
  //         home: MySignIn(),
  //       ),
  //     );
  //   else {
  //     active_user = result;
  //     runApp(
  //       MaterialApp(
  //         home: MyApp(),
  //       ),
  //     );
  //   }
  // });
  tzdata.initializeTimeZones();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerState()),
        ChangeNotifierProvider(create: (_) => ActivityTaskToday()),
      ],
      child: const MyApp(),
    ),
  );
}

List<String> getTimezones() {
  return tz.timeZoneDatabase.locations.keys.toList();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> checkFirstInstallation() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool('isDone') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          home: FutureBuilder<bool>(
            future: checkFirstInstallation(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                bool? onboardingComplete = snapshot.data;
                if (onboardingComplete == null || !onboardingComplete) {
                  return const OnboardingScreen();
                } else {
                  return const Authentication();
                }
              }
            },
          ),
          debugShowCheckedModeBanner: false,

          // Bisa dipakai jika mau pakai sidebar
          // routes: {
          //   'setting': (context) => Setting(),
          //   'login': (context) => Login(),
          // },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  int currentIndex;
  bool isLoading;
  MyHomePage({
    super.key,
    required this.currentIndex,
    required this.isLoading,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void reminderDayDaily() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 73,
        channelKey: 'daily_reminder',
        title: "Time to Make a Schedule for Your Success",
        body:
            "Take a moment to make a schedule your daily activity. A well structured plan helps you to stay focused and productive",
        notificationLayout: NotificationLayout.BigText,
        criticalAlert: true,
        wakeUpScreen: true,
        category: NotificationCategory.Alarm,
        icon: 'resource://drawable/applogo',
      ),
      schedule: NotificationCalendar(
        hour: 8,
        minute: 0,
        second: 0,
        allowWhileIdle: true,
        repeats: true,
      ),
    );
  }

  void reminderNightDaily() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 74,
        channelKey: 'daily_reminder',
        title: "Time to Make a Schedule for Your Success",
        body:
            "Take a moment to make a schedule your daily activity. A well structured plan helps you to stay focused and productive",
        notificationLayout: NotificationLayout.BigText,
        criticalAlert: true,
        wakeUpScreen: true,
        category: NotificationCategory.Alarm,
        icon: 'resource://drawable/applogo',
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 0,
        second: 0,
        allowWhileIdle: true,
        repeats: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((value) {
      if (!value) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    setState(() {
      if (widget.isLoading == true) {
        widget.isLoading = false;
        Navigator.of(context).pop();
      }
    });
    reminderDayDaily();
    reminderNightDaily();
  }

  // List halaman yang akan muncul di navbar, harus urut
  final List<Widget> _pages = [
    const Home(),
    const Timers(),
    const Pickle(),
    const Report(),
    const Profile(),
  ];

  // Bisa digunakan jika aplikasi memakai appbar
  // final List<String> _titles = [
  //   "Home",
  //   "Pomodoro",
  //   "Pickle Jar Theory",
  //   "Report",
  //   "About",
  // ];

  Container myBottomNavBar() {
    // ignore: sized_box_for_whitespace
    return Container(
      width: double.infinity,
      child: CurvedNavigationBar(
        index: widget.currentIndex,
        height: 70,
        backgroundColor: Colors.white,
        buttonBackgroundColor: const Color.fromARGB(255, 3, 0, 66),
        color: const Color.fromARGB(255, 3, 0, 66),

        // List halaman untuk navbar dengan index 0 = home, dst
        items: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_filled,
                color: Colors.white,
              ),
              Text(
                "Home",
                style: textStyleWhite,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer,
                color: Colors.white,
              ),
              Text(
                "Timer",
                style: textStyleWhite,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app-logo.png',
                width: 24,
                height: 24,
              ),
              Text(
                "Learning",
                style: textStyleWhite,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.library_books,
                color: Colors.white,
              ),
              Text(
                "Report",
                style: textStyleWhite,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                color: Colors.white,
              ),
              Text(
                "Profile",
                style: textStyleWhite,
              ),
            ],
          ),
        ],

        // When users tap menu it will change the page
        onTap: (int index) {
          setState(() {
            //menyesuaikan index dari isi items
            widget.currentIndex = index;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[widget.currentIndex],
      bottomNavigationBar: myBottomNavBar(),
    );
  }
}

// Future<String> checkUser() async {
//   final prefs = await SharedPreferences.getInstance();
//   String user_id = prefs.getString("user_id") ?? '';
//   return user_id;
// }
