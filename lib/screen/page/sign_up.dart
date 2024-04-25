import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:pickleapp/theme.dart';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:pickleapp/screen/components/button_calm_blue.dart';

class MySignUp extends StatefulWidget {
  const MySignUp({super.key});

  @override
  State<MySignUp> createState() => _MySignUpState();
}

class _MySignUpState extends State<MySignUp> {
  final _formKey = GlobalKey<FormState>();

  final RegExp _emailRegex =
      RegExp(r"^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com)$");
  final RegExp _lowCasePwd = RegExp(r'[a-z]');
  final RegExp _upperCasePwd = RegExp(r'[A-Z]');
  final RegExp _numPwd = RegExp(r'\d');
  final RegExp _symbolPwd = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _rptPassword = TextEditingController();
  String _path = "";
  String _createdAt = "";
  String _updateAt = "";

  Future<void> submit() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text,
        password: encryptPwd(_password.text),
      );

      User user = userCredential.user!;

      // Simpan gambar profil default di Firebase Storage
      String defaultProfilePicUrl = await uploadDefaultProfilePic(user.uid);

      // Simpan URL gambar profil default di Firebase Database
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': _email.text,
        'created_at': FieldValue.serverTimestamp(),
        'update_at': FieldValue.serverTimestamp(),
        'name': _name.text,
        'password': encryptPwd(_password.text),
        'path': defaultProfilePicUrl,
      });

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Your account has been successfully registered. Please back to the login page."),
        ),
      );

      setState(() {
        _email.clear();
        _name.clear();
        _password.clear();
        _rptPassword.clear();
      });
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code),
        ),
      );
    }
    // final response = await http.post(
    //   Uri.parse("http://192.168.1.134:8012/picklePHP/signUp.php"),
    //   body: {
    //     "name": _name.text,
    //     "path": _path,
    //     "email": _email.text,
    //     "password": encryptPwd(_password.text),
    //     "created_at": _createdAt,
    //     "updated_at": _updateAt,
    //   },
    // );
    // if (response.statusCode == 200) {
    //   Map json = jsonDecode(response.body);
    //   if (json["result"] == "success") {
    //     if (!mounted) return;
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text("Sukses Menambah Data"),
    //       ),
    //     );
    //   }
    // } else {
    //   throw Exception("Failed to read API");
    // }
  }

  // Function to upload default profile picture to Firebase Storage
  Future<String> uploadDefaultProfilePic(String userId) async {
    // Save default profile picture to Firebase Storage with the appropriate file name and path
    String fileName = '$userId.jpg';
    Reference storageReference =
        FirebaseStorage.instance.ref().child('user_profile').child(fileName);

    // Load default profile picture from assets as ByteData
    ByteData defaultImageData = await rootBundle.load(_path);

    // Convert ByteData to Uint8List
    Uint8List imageDataUint8List = defaultImageData.buffer.asUint8List();

    // Upload gambar ke Firebase Storage
    UploadTask uploadTask = storageReference.putData(imageDataUint8List);

    // Wait until the upload process is completed and get the image URL
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  /* ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    _path = "assets/Default_Photo_Profile.png";
    _createdAt = "${DateTime.now()}";
    _updateAt = "${DateTime.now()}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sign Up",
          style: screenTitleStyle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          margin: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Input text email
                // ignore: avoid_unnecessary_containers
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email",
                        style: subHeaderStyle,
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
                        height: 40,
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
                                // readOnly: widget == null ? false : true,
                                keyboardType: TextInputType.emailAddress,
                                // textCapitalization: TextCapitalization.sentences,
                                autofocus: false,
                                controller: _email,
                                style: textStyle,
                                decoration: InputDecoration(
                                  hintText: "Enter your email here",
                                  hintStyle: textStyle,
                                ),
                                validator: (value) {
                                  if (_email.text == "" ||
                                      _email.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please email is a must, for account sign in purpose!'),
                                      ),
                                    );
                                  } else if (_emailRegex
                                      .hasMatch(_email.text)) {
                                    return null;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Please enter a valid email!'),
                                      ),
                                    );
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Input text name
                // ignore: avoid_unnecessary_containers
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Preferred name",
                        style: subHeaderStyle,
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
                        height: 40,
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
                                // readOnly: widget == null ? false : true,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autofocus: false,
                                controller: _name,
                                style: textStyle,
                                decoration: InputDecoration(
                                  hintText: "Enter your preferred name here!",
                                  hintStyle: textStyle,
                                ),
                                validator: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Input text password
                // ignore: avoid_unnecessary_containers
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Password",
                        style: subHeaderStyle,
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
                        height: 40,
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
                                // readOnly: widget == null ? false : true,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autofocus: false,
                                controller: _password,
                                style: textStyle,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Enter your password here",
                                  hintStyle: textStyle,
                                ),
                                validator: (value) {
                                  if (_password.text == "" ||
                                      _password.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please password is a must, for account sign in purpose!'),
                                      ),
                                    );
                                  } else if (_password.text.length < 8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please, password must have a minimum of 8 character!'),
                                      ),
                                    );
                                  } else if (!_lowCasePwd
                                          .hasMatch(_password.text) ||
                                      !_upperCasePwd.hasMatch(_password.text) ||
                                      !_numPwd.hasMatch(_password.text) ||
                                      !_symbolPwd.hasMatch(_password.text)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please, password must have at least a lowercase (a-z), uppercase (A-Z), number(0-9), and symbol (!@#%^\$&*(),.?":{}|<>)!'),
                                      ),
                                    );
                                  } else {
                                    return null;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Input text repat password
                // ignore: avoid_unnecessary_containers
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Repeat password",
                        style: subHeaderStyle,
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
                        height: 40,
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
                                // readOnly: widget == null ? false : true,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autofocus: false,
                                controller: _rptPassword,
                                style: textStyle,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Repeat your password above",
                                  hintStyle: textStyle,
                                ),
                                onChanged: (value) {},
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please repeat password is a must!'),
                                      ),
                                    );
                                  } else if (value != _password.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Please, your password isn't match!"),
                                      ),
                                    );
                                  } else {
                                    return null;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const SizedBox(
                  height: 30,
                ),
                MyButtonCalmBlue(
                  label: "Submit",
                  onTap: () {
                    if (_formKey.currentState != null &&
                        !_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("None"),
                        ),
                      );
                    } else {
                      if (_name.text.isEmpty) {
                        _name.text = "Pickle";
                      }
                      // ignore: avoid_print
                      print(
                        "${_email.text}, ${_name.text}, ${_password.text}, ${_rptPassword.text},${_path},${_createdAt},${_updateAt}",
                      );
                      submit();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Encrypt password dengan SHA-256 hash
String encryptPwd(String pwd) {
  // Convert password ke SHA-256 hash
  var bytes = utf8.encode(pwd);
  var hash = sha256.convert(bytes);

  // Convert encrypt pwd ke string
  return hash.toString();
}
