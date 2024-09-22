// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/services/activity_task_state.dart';
import 'package:pickleapp/screen/services/timer_state.dart';
import 'package:pickleapp/screen/page/onboarding.dart';
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
  await initializeDateFormatting('id_ID', null);
  AwesomeNotifications().initialize(
    'resource://drawable/applogo',
    [
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'activity_reminder',
        channelName: 'Channel Notifikasi Pengingat Kegiatan',
        channelDescription: "Pickle App - Pengingat Kegiatan",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.Default,
        playSound: true,
        enableVibration: false,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: false,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'timer_reminder',
        channelName: 'Channel Notifikasi Waktu Mundur',
        channelDescription: "Pickle App - Waktu Mundur",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.Max,
        playSound: false,
        enableVibration: false,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: true,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'mulai_kegiatan',
        channelName: 'Channel Notifikasi Mulai Kegiatan',
        channelDescription: "Pickle App - Mulai kegiatan",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.Default,
        playSound: false,
        enableVibration: false,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: true,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'code_reminder',
        channelName: 'Channel Notifikasi Kode Buka Kunci Layar',
        channelDescription:
            "Pickle App - Kode buka kunci layar untuk halaman timer",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: true,
      ),
      NotificationChannel(
        icon: 'resource://drawable/applogo',
        channelKey: 'daily_reminder',
        channelName: 'Channel Notifikasi Pengingat Waktu Penjadwalan',
        channelDescription:
            "Pickle App - Pengingat untuk melakukan penjadwalan kegiatan",
        defaultRingtoneType: DefaultRingtoneType.Notification,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        defaultPrivacy: NotificationPrivacy.Private,
        locked: true,
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
          locale: const Locale('id', 'ID'),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('id', 'ID'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
        title: "Waktunya Membuat Rencana Kegiatan",
        body:
            "Jangan lupa untuk merencanakan kegiatanmu hari ini. Kegiatan yang terstruktur membantu kamu untuk lebih fokus dan tetap produktif.",
        backgroundColor: const Color.fromARGB(255, 255, 170, 0),
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
        title: "Waktunya Membuat Rencana Kegiatan",
        body:
            "Jangan lupa untuk merencanakan kegiatanmu buat besok. Kegiatan yang terstruktur membantu kamu untuk lebih fokus dan tetap produktif.",
        backgroundColor: const Color.fromARGB(255, 255, 170, 0),
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
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_filled,
                color: Colors.white,
              ),
              Text(
                "Utama",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: Colors.white,
              ),
              Text(
                "Timer",
                style: TextStyle(color: Colors.white),
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
              const Text(
                "Pickle",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books,
                color: Colors.white,
              ),
              Text(
                "Laporan",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                color: Colors.white,
              ),
              Text(
                "Profil",
                style: TextStyle(color: Colors.white),
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
