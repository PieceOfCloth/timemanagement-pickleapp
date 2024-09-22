// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter_awesome_notifications/flutter_awesome_notifications.dart';

// class NotificationController {
//   static String? _currentKegiatanId;
//   static int _duration = 0;

//   static ReceivedAction? initialAction;

//   @pragma('vm:entry-point')
//   static Future<void> onActionReceivedMethod(
//       ReceivedAction receivedAction) async {
//     if (receivedAction.channelKey == "mulai_kegiatan" &&
//         receivedAction.buttonKeyPressed == "start_button") {
//       _currentKegiatanId = receivedAction.payload?['kegiatans_id'];
//       _duration = int.parse(receivedAction.payload?['time'] ?? "0");

//       // Memulai timer atau logika yang sesuai di latar belakang
//       startBackgroundTimer();
//     } else if (receivedAction.channelKey == "mulai_kegiatan" &&
//         receivedAction.buttonKeyPressed == "complete_button") {
//       // Tambahkan logika untuk menangani aksi 'Selesai'
//       completeActivity();
//     }
//   }

//   static void startBackgroundTimer() {
//     int secondsElapsed = 0;

//     // Timer.periodic untuk menghitung waktu di latar belakang
//     Timer.periodic(Duration(seconds: 1), (timer) {
//       secondsElapsed++;
//       // Perbarui notifikasi dengan menambahkan detik yang berlalu
//       updateNotification(secondsElapsed);
//     });
//   }

//   static void updateNotification(int secondsElapsed) {
//     // Perbarui notifikasi dengan menampilkan waktu yang berlalu
//     AwesomeNotifications().updateNotification(
//       10, // Sesuaikan dengan ID notifikasi yang tepat
//       content: NotificationContent(
//         id: 10,
//         channelKey: 'mulai_kegiatan',
//         title: 'Timer Running',
//         body: '$secondsElapsed seconds elapsed',
//         notificationLayout: NotificationLayout.ProgressBar,
//       ),
//     );
//   }

//   static void completeActivity() {
//     // Tambahkan logika untuk menangani ketika kegiatan selesai
//     // Misalnya, hentikan timer, simpan data, dll.
//     print('Activity completed!');
//   }
// }
