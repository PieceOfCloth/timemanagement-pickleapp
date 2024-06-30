// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/theme.dart';

class MyForgotPassword extends StatefulWidget {
  const MyForgotPassword({super.key});

  @override
  State<MyForgotPassword> createState() => _MyForgotPasswordState();
}

class _MyForgotPasswordState extends State<MyForgotPassword> {
  final TextEditingController email = TextEditingController();

  final formKey = GlobalKey<FormState>();

  Future<void> resetPassword() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      AlertInformation.showDialogBox(
          context: context,
          title: 'Verifikasi Atur Ulang Kata Sandi',
          message:
              "Kami sudah mengirimkan pesan ke email kamu untuk verifikasi atur ulang kata sandi. silahkan cek email kamu dan selesaikan proses verifikasi sebelum mengubah kata sandi. Terima Kasih:)");
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      if (e.code == 'user-not-found') {
        AlertInformation.showDialogBox(
            context: context,
            title: 'Akun tidak ditemukan',
            message:
                "Tidak ada akun yang memiliki email tersebut, Silahkan isi dengan email yang sesuai, terima kasih.");
      } else if (e.code == 'invalid-email') {
        AlertInformation.showDialogBox(
            context: context,
            title: "Email Tidak Sesuai",
            message:
                "Silahkan untuk mengisi email dengan benar, Terima kasih.");
      } else {
        AlertInformation.showDialogBox(
            context: context,
            title: 'Error',
            message:
                'Terjadi kesalahan saat melakukan reset password: ${e.message}.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      AlertInformation.showDialogBox(
          context: context,
          title: 'Error',
          message:
              'Terjadi kesalahan saat melakukan reset password. Silakan coba lagi nanti.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lupa Kata Sandi",
          style: headerStyleBold,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              margin: const EdgeInsets.only(
                left: 40,
                right: 40,
              ),
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Input text email
                    Form(
                      key: formKey,
                      child: Column(
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
                                width: constraints.maxWidth,
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
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofocus: false,
                                        controller: email,
                                        decoration: InputDecoration(
                                          hintText:
                                              "Masukkan email kamu disini",
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
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (formKey.currentState != null &&
                            !formKey.currentState!.validate()) {
                          return;
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Expanded(
                                  child: Text(
                                    'Atur Ulang Kata Sandi',
                                    style: subHeaderStyleBold,
                                  ),
                                ),
                                content: Text(
                                  'Apakah kamu yakin untuk mengganti kata sandi?',
                                  style: textStyle,
                                ),
                                actions: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      resetPassword();
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: constraints.maxWidth,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          width: 1,
                                          color: const Color.fromARGB(
                                              255, 3, 0, 66),
                                        ),
                                      ),
                                      child: // Space between icon and text
                                          Text(
                                        'Ganti',
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
                                      width: constraints.maxWidth,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color:
                                            const Color.fromARGB(255, 3, 0, 66),
                                      ),
                                      child: // Space between icon and text
                                          Text('Batal',
                                              style: textStyleBoldWhite),
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
                        width: constraints.maxWidth,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: const Color.fromARGB(255, 3, 0, 66),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.email,
                              color: Colors.white,
                            ), // Logout icon
                            const SizedBox(
                                width: 8.0), // Space between icon and text
                            Text(
                              'Atur Ulang Kata Sandi',
                              style: textStyleBoldWhite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
