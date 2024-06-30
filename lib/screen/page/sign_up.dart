// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class MySignUp extends StatefulWidget {
  const MySignUp({super.key});

  @override
  State<MySignUp> createState() => _MySignUpState();
}

class _MySignUpState extends State<MySignUp> {
  final formKey = GlobalKey<FormState>();
  final GlobalKey _tooltipPassword = GlobalKey();

  final RegExp emailRegex =
      RegExp(r"^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com)$");
  final RegExp newPwdPattern = RegExp(
      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?':{}|<>]).{8,}$");

  TextEditingController email = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController rptPassword = TextEditingController();

  String path = "";
  String createdAt = "";
  String updateAt = "";

  bool obsecurePassword = true;
  bool obsecureRptPassword = true;

  Future<void> setUserAccount() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      User user = userCredential.user!;

      String fileName = '${user.uid}.jpg';
      String url = 'user_profile/$fileName';
      Reference storageReference =
          FirebaseStorage.instance.ref().child('user_profile').child(fileName);

      // Load default profile picture from assets as ByteData
      ByteData defaultImageData = await rootBundle.load(path);
      // Convert ByteData to Uint8List
      Uint8List imageDataUint8List = defaultImageData.buffer.asUint8List();
      // Upload gambar ke Firebase Storage
      await storageReference.putData(imageDataUint8List);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email.text,
        'created_at': FieldValue.serverTimestamp(),
        'update_at': FieldValue.serverTimestamp(),
        'name': name.text.isEmpty ? email.text.split('@')[0] : name.text,
        'path': url,
      });

      await user.sendEmailVerification();

      setState(() {
        email.clear();
        name.clear();
        password.clear();
        rptPassword.clear();
      });

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      AlertInformation.showDialogBox(
        context: context,
        title: "Verifikasi Akun Baru Kamu",
        message:
            "Kami telah mengirimkan pesan untuk verifikasi akun ke email kamu. Silahkan cek email kamu dan lakukan verifikasi jika ingin menggunakan akun kamu. Terima kasih!",
      );

      FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      if (e.code == 'email-already-in-use') {
        AlertInformation.showDialogBox(
          context: context,
          title: "Email Telah Digunakan",
          message:
              "Email yang kamu masukkan sudah pernah didaftarkan di aplikasi ini. Silahkan masukkan email baru. Terima kasih!",
        );
      } else if (e.code == 'invalid-email') {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Email Tidak Valid',
          message:
              "Email yang kamu masukkan tidak valid. Silahkan masukkan email yang benar. Terima kasih!",
        );
      } else {
        print(e.code);
      }
    }
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    path = "assets/Default_Photo_Profile.png";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pendaftaran Akun",
          style: headerStyleBold,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Form(
            key: formKey,
            child: Container(
              margin: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Input text email
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
                                  // readOnly: widget == null ? false : true,
                                  keyboardType: TextInputType.emailAddress,
                                  // textCapitalization: TextCapitalization.sentences,
                                  autofocus: false,
                                  // style: caption1Style,
                                  controller: email,
                                  decoration: InputDecoration(
                                    hintText: "Masukkan email baru kamu disini",
                                    hintStyle: textStyleGrey,
                                  ),
                                  validator: (value) {
                                    if (value == "" || value == null) {
                                      return 'Silahkan isi email baru kamu.';
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
                    // Input text name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nama Panggilan",
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
                                  // readOnly: widget == null ? false : true,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  autofocus: false,
                                  // style: caption1Style,
                                  controller: name,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Masukkan nama panggilanmu disini",
                                    hintStyle: textStyleGrey,
                                  ),
                                  validator: null,
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
                    // Input text password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text(
                                "Kata sandi baru",
                                style: textStyle,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              flex: 2,
                              child: Tooltip(
                                key: _tooltipPassword,
                                margin: const EdgeInsets.only(
                                  left: 80,
                                  right: 20,
                                ),
                                message:
                                    'Mohon untuk memasukkan kata sandi yang terdiri dari, huruf kecil (a-z), huruf besar (A-Z), nomor(0-9), and satu simbol (!@#%^\$&*(),.?":{}|<>).',
                                child: GestureDetector(
                                  onTap: () {
                                    final dynamic tooltip =
                                        _tooltipPassword.currentState;
                                    tooltip.ensureTooltipVisible();
                                  },
                                  child: const Icon(
                                    Icons.info,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                  autofocus: false,
                                  obscureText: obsecurePassword,
                                  controller: password,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Masukkan kata sandi baru kamu disini",
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
                                    if (value == "" || value == null) {
                                      return 'Silahkan isi kata sandi baru kamu.';
                                    } else if (value.length < 8) {
                                      return 'Kata sandi minimal memiliki 8 karakter.';
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ulangi kata sandi",
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
                                  autofocus: false,
                                  controller: rptPassword,
                                  obscureText: obsecureRptPassword,
                                  decoration: InputDecoration(
                                    hintText: "Ulangi kata sandi baru kamu",
                                    hintStyle: textStyleGrey,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obsecureRptPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obsecureRptPassword =
                                              !obsecureRptPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == "" || value == null) {
                                      return 'Silahkan ulangi kata sandi kamu.';
                                    } else if (password.text !=
                                        rptPassword.text) {
                                      return "Kata sandi kamu tidak sesuai.";
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
                      height: 40,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (formKey.currentState != null &&
                            !formKey.currentState!.validate()) {
                          return;
                        } else {
                          setUserAccount();
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
                              'Daftar Akun',
                              style: textStyleBoldWhite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Encrypt password dengan SHA-256 hash
// String encryptPwd(String pwd) {
//   // Convert password ke SHA-256 hash
//   var bytes = utf8.encode(pwd);
//   var hash = sha256.convert(bytes);

//   // Convert encrypt pwd ke string
//   return hash.toString();
// }
