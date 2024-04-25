import 'package:flutter/material.dart';
import 'package:pickleapp/auth.dart';
import 'package:sizer/sizer.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pickleapp/firebase_options.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'screen/page/home.dart';
import 'screen/page/timer.dart';
import 'screen/page/pickle.dart';
import 'screen/page/report.dart';
import 'screen/page/profile.dart';

String activeUser = "admin@gmail.com";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(const Duration(seconds: 10));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  runApp(const MyApp());
}

List<String> getTimezones() {
  return tz.timeZoneDatabase.locations.keys.toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return const MaterialApp(
          // title: 'Flutter Demo',
          // theme: ThemeData(
          //   scaffoldBackgroundColor: const Color.fromARGB(255, 240, 240, 240),
          // ),
          home: Authentication(),
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
  const MyHomePage({
    super.key,
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  // String active_user = "";

  // List halaman yang akan muncul di navbar, harus urut
  final List<Widget> _pages = [
    const Home(),
    Timers(),
    Pickle(),
    Report(),
    Profile(),
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
        index: _currentIndex,
        backgroundColor: Colors.white,
        buttonBackgroundColor: const Color.fromARGB(255, 3, 0, 66),
        color: const Color.fromARGB(255, 3, 0, 66),

        // List halaman untuk navbar dengan index 0 = home, dst
        items: const <Widget>[
          Icon(
            Icons.home_filled,
            color: Color.fromARGB(255, 255, 170, 0),
          ),
          Icon(
            Icons.timelapse_rounded,
            color: Color.fromARGB(255, 255, 170, 0),
          ),
          Icon(
            Icons.library_books_rounded,
            color: Color.fromARGB(255, 255, 170, 0),
          ),
          Icon(
            Icons.timeline_rounded,
            color: Color.fromARGB(255, 255, 170, 0),
          ),
          Icon(
            Icons.person_2_rounded,
            color: Color.fromARGB(255, 255, 170, 0),
          ),
        ],

        // When users tap menu it will change the page
        onTap: (int index) {
          setState(() {
            //menyesuaikan index dari isi items
            _currentIndex = index;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_titles[_pagesIndex]),
      // ),
      body: _pages[_currentIndex], bottomNavigationBar: myBottomNavBar(),
    );
  }
}

// Future<String> checkUser() async {
//   final prefs = await SharedPreferences.getInstance();
//   String user_id = prefs.getString("user_id") ?? '';
//   return user_id;
// }
