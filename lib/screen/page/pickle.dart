import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class Pickle extends StatelessWidget {
  const Pickle({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(
              top: 20,
              left: 10,
              right: 10,
              bottom: 10,
            ),
            child: IntroductionScreen(
              pages: [
                PageViewModel(
                  title:
                      "Mengetahui Cara Manajemen Waktu dengan Teori Pickle Jar",
                  body:
                      "Mari kita eksplorasi Teori Pickle Jar, metafora manajemen waktu untuk prioritisasi yang lebih mudah.",
                  image: Image.asset(
                    'assets/app-logo.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Toples Kosong",
                  body:
                      "Bayangkan toples kosong menggambarkan hari kamu selama 24 jam. Terbatas dan hanya bisa diisi oleh beberapa kegiatan.",
                  image: Image.asset(
                    'assets/empty-jar.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Bola Golf, Kerikil, Pasir, dan Air",
                  body:
                      "Lalu benda-benda tersebut dapat mewakili kegiatanmu dan masing-masing memiliki prioritas, seperti Bola Golf (Prioritas utama), Kerikil (Prioritas tinggi), Pasir (Prioritas Sedang), dan Air (Prioritas rendah).",
                  image: Image.asset(
                    'assets/golf-pebbles-sand-water.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Toples Penuh dengan Bola Golf (Prioritas Utama)",
                  body:
                      "Bayangkan jika toples hanya diisi penuh oleh kegiatan-kegiatan yang membutuhkan waktu, konsentrasi tinggi, dan harus segera diselesaikan. Tentu kita akan penat dan dapat berpotensi mengalami kelelahan mental (BURNOUT).",
                  image: Image.asset(
                    'assets/golf-jar.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Toples Penuh dengan Kerikil (Prioritas Tinggi)",
                  body:
                      "Lalu bayangkan jika kita mengisi toples dengan kegiatan yang sama-sama penting tapi tidak mendesak untuk diselesaikan pada hari itu. Tentunya kita tidak akan memiliki ruang untuk dapat menyelesaikan kegiatan yang lebih mendesak.",
                  image: Image.asset(
                    'assets/pebbles-jar.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Toples Penuh dengan Pasir (Prioritas Sedang)",
                  body:
                      "Lalu jika toples atau waktu kita hanya diisi dengan kegiatan yang tidak terlalu penting tapi mendesak, seperti menjawab email atau menghadiri rapat yang dapat diwakilkan. Tentunya dapat menghalangi kita untuk dapat menyelesaikan tugas-tugas yang lebih penting dan strategis.",
                  image: Image.asset(
                    'assets/sand-jar.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Toples Penuh dengan Air (Prioritas Rendah)",
                  body:
                      "Yang terakhir, bagaimana jika toples kita hanya diisi oleh air atau kegiatan tidak produktif yang mendistraksi. Hal tersebut dapat membuat kita menunda-nuda pekerjaan sehingga kurangnya produktivitas.",
                  image: Image.asset(
                    'assets/water-jar.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                PageViewModel(
                  title: "Toples Penuh yang Seimbang",
                  body:
                      "Oleh karena itu rencanakan harimu secara seimbang, dengan memasukkan bola golf atau kegiatan yang penting dan mendesak untuk diselesaikan terlebih dahulu, lalu isi dengan kerikil atau kegiatan yang sama-sama penting tapi tidak mendesak, selanjutnya isi dengan pasir atau kegiatan yang kurang penting tetapi mendesak untuk diselesaikan agar tidak menumpuk, dan yang terakhir diisi dengan air atau kegiatan-kegiatan yang tidak produktif tetapi dapat memberikan perasaan senang dan tenang.",
                  image: Image.asset(
                    'assets/full-jar.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
              ],
              showSkipButton: false,
              showDoneButton: false,
              showNextButton: false,
              dotsDecorator: DotsDecorator(
                size: const Size.square(10.0),
                activeSize: const Size(22.0, 10.0),
                activeColor: const Color.fromARGB(255, 3, 0, 66),
                color: Colors.grey,
                spacing: const EdgeInsets.symmetric(horizontal: 1.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
