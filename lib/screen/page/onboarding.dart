// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.white,
              child: IntroductionScreen(
                pages: [
                  PageViewModel(
                    title: "Selamat Datang di Pickle App",
                    body:
                        'Rencanakan hari kamu untuk tetap produktif dengan penjadwalan dan alat fokus kami.',
                    image: Image.asset(
                      "assets/intro.jpeg",
                      width: MediaQuery.of(context).size.width * 1,
                      height: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.fill,
                    ),
                    decoration: PageDecoration(
                      titleTextStyle: screenTitleStyle,
                      bodyTextStyle: textStyle,
                    ),
                  ),
                  PageViewModel(
                    title:
                        "Kuasai Prioritisasi Kegiatan dengan Teori Pickle Jar",
                    body:
                        "Belajar memprioritaskan tugas-tugas dengan memahami apa yang benar-benar penting. Rencanakan harimu seperti sedang mengisi sebuah toples dengan bola golf, kerikil, pasir, dan air.",
                    image: Image.asset(
                      "assets/theory.jpeg",
                      width: MediaQuery.of(context).size.width * 1,
                      height: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.fill,
                    ),
                    decoration: PageDecoration(
                      titleTextStyle: screenTitleStyle,
                      bodyTextStyle: textStyle,
                    ),
                  ),
                  PageViewModel(
                    title: "Rekomendasi Jadwal Menggunakan Algoritma",
                    body:
                        "Algoritma kami akan membantu kamu dalam membuat jadwal kegiatan dengan memberikan rekomendasi jadwal berdasarkan daftar kegiatan yang kamu buat.",
                    image: Image.asset(
                      "assets/algorithm.jpeg",
                      width: MediaQuery.of(context).size.width * 1,
                      height: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.fill,
                    ),
                    decoration: PageDecoration(
                      titleTextStyle: screenTitleStyle,
                      bodyTextStyle: textStyle,
                    ),
                  ),
                  PageViewModel(
                    title: "Tingkatkan Fokus Kamu",
                    body:
                        "Gunakan Timer untuk membagi waktu kerjamu menjadi interval fokus dengan istirahat singkat, agar dapat meningkatkan produktivitas dan konsentrasi kamu.",
                    image: Image.asset(
                      "assets/timer.jpeg",
                      width: MediaQuery.of(context).size.width * 1,
                      height: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.fill,
                    ),
                    decoration: PageDecoration(
                      titleTextStyle: screenTitleStyle,
                      bodyTextStyle: textStyle,
                    ),
                  ),
                  PageViewModel(
                    title: "Lacak Kemajuan Kamu",
                    body:
                        "Tinjau aktivitas harianmu dan lihat bagaimana kamu menghabiskan waktu. Identifikasi pola kegiatan yang berguna dan tidak produktif untuk dapat mengoptimalkan alur kerjamu.",
                    image: Image.asset(
                      "assets/daily-report.jpeg",
                      width: MediaQuery.of(context).size.width * 1,
                      height: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.fill,
                    ),
                    decoration: PageDecoration(
                      titleTextStyle: screenTitleStyle,
                      bodyTextStyle: textStyle,
                    ),
                  ),
                  PageViewModel(
                    title: "Mulai Sekarang",
                    body:
                        "Mulai perjalananmu menuju manajemen waktu yang lebih baik. Yuk buat hari ini lebih produktif :)",
                    image: Image.asset(
                      "assets/use-app.jpeg",
                      width: MediaQuery.of(context).size.width * 1,
                      height: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.fill,
                    ),
                    decoration: PageDecoration(
                      titleTextStyle: screenTitleStyle,
                      bodyTextStyle: textStyle,
                    ),
                  ),
                ],
                onDone: () async {
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  preferences.setBool('isDone', true);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Authentication()),
                  );
                },
                showSkipButton: false,
                done: Text(
                  "Done",
                  style: textStyleBold,
                ),
                next: const Icon(Icons.arrow_circle_right, color: Colors.black),
              ),
            );
          },
        ),
      ),
    );
  }
}
