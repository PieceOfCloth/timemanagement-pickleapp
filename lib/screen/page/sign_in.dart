// ignore_for_file: use_build_context_synchronously, avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/screen/page/forgot_password.dart';
import 'package:pickleapp/screen/page/sign_up.dart';
import 'package:pickleapp/theme.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool isLoginManual = false;

class MySignIn extends StatefulWidget {
  const MySignIn({super.key});

  @override
  State<MySignIn> createState() => _MySignInState();
}

class _MySignInState extends State<MySignIn> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  String message = '';
  String? path;
  bool obsecurePassword = true;

  Future<void> checkLogin() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      setState(() {
        isLoginManual = true;
        isLogin = true;
      });
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      if (e.code == 'invalid-email') {
        AlertInformation.showDialogBox(
            context: context,
            title: 'Email Tidak Valid',
            message:
                "Email kamu tidak valid, Silahkan untuk memberikan email yang valid.");
      } else if (e.code == 'wrong-password') {
        AlertInformation.showDialogBox(
            context: context,
            title: 'Kata Sandi Salah',
            message:
                "Kata sandi yang kamu masukkan salah, Silahkan untuk memasukkan kata sandi yang benar.");
      } else {
        AlertInformation.showDialogBox(
            context: context,
            title: 'Akun Pengguna Tidak Ditemukan',
            message:
                'Kami tidak dapat menemukan akun kamu. Mohon cek input email dan kata sandi kamu atau daftarkan akun kamu atau langsung login dengan menekan "Sign In dengan Google".');
      }
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await GoogleSignIn().signOut();

      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        isLoginManual = false;
        isLogin = true;
      });

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user?.uid);

      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        String fileName = '${userCred.user?.uid}.jpg';
        String url = 'user_profile/$fileName';
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('user_profile')
            .child(fileName);

        await FirebaseFirestore.instance.collection("kategoris").add({
          "nama": "Lainnya",
          "users_id": userCred.user?.uid,
          "warna_a": 255,
          "warna_r": 255,
          "warna_g": 255,
          "warna_b": 255,
        });

        // Load default profile picture from assets as ByteData
        ByteData defaultImageData = await rootBundle.load(path!);
        // Convert ByteData to Uint8List
        Uint8List imageDataUint8List = defaultImageData.buffer.asUint8List();
        // Upload gambar ke Firebase Storage
        await storageReference.putData(imageDataUint8List);

        await userDoc.set({
          'email': userCred.user?.email,
          'created_at': FieldValue.serverTimestamp(),
          'update_at': FieldValue.serverTimestamp(),
          'name': userCred.user?.displayName,
          'path': url,
        });
      }

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      AlertInformation.showDialogBox(
          context: context, title: e.code, message: e.message ?? e.code);
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      path = "assets/Default_Photo_Profile.png";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            margin: const EdgeInsets.only(
              // top: 40,
              left: 40,
              right: 40,
              bottom: 20,
            ),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo aplikasi
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/app-logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Text(
                    "Pickle App",
                    style: screenTitleStyle,
                  ),
                  Text(
                    "Rencanakan harimu dengan cerdas",
                    style: textStyle,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  // Input text email
                  Form(
                    key: formKey,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Email",
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
                          const SizedBox(
                            height: 10,
                          ),
                          // Input password text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kata sandi",
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
                                        keyboardType: TextInputType.text,
                                        obscureText: obsecurePassword,
                                        autofocus: false,
                                        controller: password,
                                        decoration: InputDecoration(
                                          hintText:
                                              "Masukkan kata sandi kamu disini",
                                          hintStyle: textStyleGrey,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obsecurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                obsecurePassword =
                                                    !obsecurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == "" || value == null) {
                                            return 'Silahkan isi kata sandi kamu.';
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
                            height: 10,
                          ),
                          // ignore: sized_box_for_whitespace
                          Container(
                            width: constraints.maxWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Lupa kata sandi? ",
                                  style: textStyle,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // print("tes klik forgot password");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MyForgotPassword(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Tekan disini",
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.blue,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (formKey.currentState != null &&
                                  !formKey.currentState!.validate()) {
                                return;
                              } else {
                                checkLogin();
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
                              child: Text(
                                "Login",
                                style: textStyleBoldWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: constraints.maxWidth,
                    alignment: Alignment.center,
                    child: Text(
                      "atau",
                      style: textStyle,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      loginWithGoogle();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 10,
                      ),
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color.fromARGB(255, 3, 0, 66),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset("assets/google-logo.png"), // Logout icon
                          const SizedBox(
                              width: 8.0), // Space between icon and text
                          Text(
                            'Login dengan Google',
                            style: textStyleBold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Tidak memiliki akun? ",
                          style: textStyle,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MySignUp(),
                              ),
                            );
                          },
                          child: const Text(
                            "Daftar sekarang",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
