// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/theme.dart';

// ignore: must_be_immutable
class ChangePassword extends StatefulWidget {
  const ChangePassword({
    super.key,
  });

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();

  // final RegExp _newPwdPattern = RegExp(
  //     r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?':{}|<>]).{8,}$");

  TextEditingController email = TextEditingController();
  TextEditingController oldPass = TextEditingController();

  String message = "";

  bool obsecurePassword = true;

  // Encrypt password dengan SHA-256 hash
  // String encryptPwd(String pwd) {
  //   // Convert password ke SHA-256 hash
  //   var bytes = utf8.encode(pwd);
  //   var hash = sha256.convert(bytes);

  //   // Convert encrypt pwd ke string
  //   return hash.toString();
  // }

  Future<void> reauthenticateUser(String email, String currentPassword) async {
    try {
      await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(
          EmailAuthProvider.credential(
              email: email, password: currentPassword));
      print('User re-authenticated');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
            message:
                'Silahkan isi dengan kata sandi lama yang benar. Terima kasih.',
            code: e.code);
      } else {
        rethrow;
      }
    }
  }

  Future<void> updatedPassword() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Re-authenticate the user
      await reauthenticateUser(email.text, oldPass.text);

      // Update the password
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.pop(context, true);

      AlertInformation.showDialogBox(
        context: context,
        title: 'Ubah kata sandi Diproses',
        message:
            "Kami telah mengirimkanmu pesan untuk mengubah kata sandi melalui email, silahkan diproses untuk dapat mengubah kata sandi kamu. Terima kasih.",
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      if (e.code == 'invalid-email') {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Email Tidak Valid',
          message:
              "Email kamu tidak valid, Silahkan isi dengan email yang benar. Terima kasih.",
        );
      } else if (e.code == 'user-not-found') {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Email Tidak Ditemukan',
          message:
              "Akun dengan email tersebut tidak dapat ditemukan. Silahkan coba lagi. Terima kasih.",
        );
      } else if (e.code == "invalid-credential") {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Input Tidak Sesuai',
          message:
              "Kata sandi atau email yang kamu masukkan tidak sesuai. Silahkan masukkan data yang benar. Terima kasih.",
        );
      } else {
        AlertInformation.showDialogBox(
          context: context,
          title: '$e.code',
          message: "${e.message}.",
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Ubah Kata Sandi',
          style: subHeaderStyleBold,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          margin: const EdgeInsets.only(
            left: 20,
            top: 20,
            right: 20,
            bottom: 20,
          ),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Email",
                    style: textStyle,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                    ),
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            autofocus: false,
                            controller: email,
                            decoration: InputDecoration(
                              hintText: "Masukkan email kamu disini",
                              hintStyle: textStyleGrey,
                            ),
                            validator: (value) {
                              if (value == "" || value == null) {
                                return 'Silahkan isi email kamu';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              // Input password text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kata sandi lama",
                    textDirection: TextDirection.ltr,
                    style: textStyle,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                    ),
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.text,
                            obscureText: obsecurePassword,
                            autofocus: false,
                            controller: oldPass,
                            decoration: InputDecoration(
                              hintText: "Masukkan kata sandi lama kamu",
                              hintStyle: textStyleGrey,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obsecurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obsecurePassword = !obsecurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value == "") {
                                return 'Silahkan isi kata sandi lama kamu.';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 60,
              ),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState != null &&
                      !_formKey.currentState!.validate()) {
                    return;
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Proses Ubah Kata sandi',
                            style: subHeaderStyleBold,
                          ),
                          content: Text(
                              'Apakah kamu yakin untuk melanjutkan proses ubah kata sandi?',
                              style: textStyle),
                          actions: <Widget>[
                            GestureDetector(
                              onTap: () {
                                updatedPassword();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    width: 1,
                                    color: const Color.fromARGB(255, 3, 0, 66),
                                  ),
                                ),
                                child: // Space between icon and text
                                    Text(
                                  'Lanjutkan',
                                  style: textStyleBold,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: const Color.fromARGB(255, 3, 0, 66),
                                ),
                                child: // Space between icon and text
                                    Text(
                                  'Batal',
                                  style: textStyleBoldWhite,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 3, 0, 66),
                  ),
                  child: Text(
                    "Ubah Kata Sandi",
                    style: textStyleBoldWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//   void submitChanged() async {
//     final response = await http.post(
//       Uri.parse("http://192.168.1.5:8012/picklePHP/changePassword.php"),
//       body: {
//         "newPassword": encryptPwd(_newPass.text),
//         "email": activeUser,
//         "oldPassword": encryptPwd(_oldPass.text),
//       },
//     );
//     if (response.statusCode == 200) {
//       Map json = jsonDecode(response.body);
//       message = json["message"];
//       if (json["result"] == "success") {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//           ),
//         );
//       } else {
//         // ignore: use_build_context_synchronously
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//           ),
//         );
//       }
//     } else {
//       throw Exception("Failed to read API");
//     }
//   }
// }

// Encrypt password dengan SHA-256 hash
// String encryptPwd(String pwd) {
//   // Convert password ke SHA-256 hash
//   var bytes = utf8.encode(pwd);
//   var hash = sha256.convert(bytes);

//   // Convert encrypt pwd ke string
//   return hash.toString();
// }

// // Confirmation Dialog
// Future<bool?> confirmationBox(BuildContext context) async {
//   return showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text("Confirmation!"),
//         content: const Text("Are you sure you want to change your password?"),
//         actions: <Widget>[
//           MyButtonWhite(
//               label: "Cancel",
//               onTap: () {
//                 Navigator.of(context).pop(false);
//               }),
//           MyButtonCalmBlue(
//             label: "Change it",
//             onTap: () {
//               Navigator.of(context).pop(true);
//             },
//           ),
//         ],
//       );
//     },
//   );
}
