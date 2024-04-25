import 'package:flutter/material.dart';
import 'package:pickleapp/main.dart';
import 'package:pickleapp/screen/components/button_white.dart';
import 'package:pickleapp/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

// import 'package:pickleapp/screen/components/inputText.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';

import 'package:pickleapp/screen/page/profile.dart';

class MyChangePassword extends StatefulWidget {
  const MyChangePassword({super.key});

  @override
  State<MyChangePassword> createState() => _MChangePasswordState();
}

class _MChangePasswordState extends State<MyChangePassword> {
  final _formKey = GlobalKey<FormState>();

  final RegExp _newPwdPattern = RegExp(
      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?':{}|<>]).{8,}$");

  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _rptPass = TextEditingController();
  // final TextEditingController _email = TextEditingController();
  final TextEditingController _oldPass = TextEditingController();

  String message = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Change Password',
          style: screenTitleStyle,
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
              // Input password text
              // ignore: avoid_unnecessary_containers
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Password",
                      style: subHeaderStyle,
                      textDirection: TextDirection.ltr,
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
                              // textCapitalization: TextCapitalization.sentences,
                              obscureText: true,
                              autofocus: false,
                              controller: _oldPass,

                              style: textStyle,
                              decoration: InputDecoration(
                                hintText:
                                    "Enter your current secret password here",
                                hintStyle: textStyle,
                              ),
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
              // Input password text
              // ignore: avoid_unnecessary_containers
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "New Password",
                      style: subHeaderStyle,
                      textDirection: TextDirection.ltr,
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
                              // textCapitalization: TextCapitalization.sentences,
                              obscureText: true,
                              autofocus: false,
                              controller: _newPass,
                              // validator: (value) {
                              //   if (!_newPwdPattern.hasMatch(_newPass.text)) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       SnackBar(
                              //         content: Text(
                              //             "Please, password must have at least a lowercase (a-z), uppercase (A-Z), number(0-9), and symbol (!@#%^\$&*(),.?':{}|<>)!"),
                              //       ),
                              //     );
                              //   } else {
                              //     return null;
                              //   }
                              // },
                              style: textStyle,
                              decoration: InputDecoration(
                                hintText: "Enter your New secret password here",
                                hintStyle: textStyle,
                              ),
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
              // Input password text
              // ignore: avoid_unnecessary_containers
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Repeat New Password",
                      style: subHeaderStyle,
                      textDirection: TextDirection.ltr,
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
                              // textCapitalization: TextCapitalization.sentences,
                              obscureText: true,
                              autofocus: false,
                              controller: _rptPass,
                              // validator: (value) {
                              //   if (value == null || value.isEmpty) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       const SnackBar(
                              //         content: Text(
                              //             'Please repeat password is a must!'),
                              //       ),
                              //     );
                              //   } else if (value != _newPass.text) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       const SnackBar(
                              //         content: Text(
                              //             'Your password is no the same as your new password!'),
                              //       ),
                              //     );
                              //   } else {
                              //     return null;
                              //   }
                              // },
                              style: textStyle,
                              decoration: InputDecoration(
                                hintText:
                                    "Repeat your new secret password here",
                                hintStyle: textStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 60,
              ),
              MyButtonCalmBlue(
                label: "Change Password",
                onTap: () async {
                  // if (_formKey.currentState != null &&
                  //     !_formKey.currentState!.validate()) {
                  //   submitChanged();
                  // }
                  if (_oldPass.text == "" ||
                      _newPass.text == "" ||
                      _rptPass.text == "") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Your new or current or repeat password cannot be empty"),
                      ),
                    );
                  } else if (_newPass.text == _oldPass.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Your new password cannot be the same as your current password"),
                      ),
                    );
                  } else if (!_newPwdPattern.hasMatch(_newPass.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Please, password must have at least a lowercase (a-z), uppercase (A-Z), number(0-9), and symbol (!@#%^\$&*(),.?':{}|<>)!"),
                      ),
                    );
                  } else if (_rptPass.text != _newPass.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Your repeat password is no the same as your new password!'),
                      ),
                    );
                  } else {
                    bool? confirmed = await confirmationBox(context);
                    if (confirmed != null && confirmed) {
                      // User confirmed, proceed with the desired action
                      // ignore: avoid_print
                      print('User click change it');
                      try {
                        submitChanged();
                        // ignore: avoid_print
                        print("Change password done, No Error");
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profile(),
                          ),
                        );
                      } catch (e) {
                        // ignore: avoid_print
                        print("Error when click change password : $e");
                      }
                    } else {
                      // User canceled
                      // ignore: avoid_print
                      print('User click cancel');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void submitChanged() async {
    final response = await http.post(
      Uri.parse("http://192.168.1.5:8012/picklePHP/changePassword.php"),
      body: {
        "newPassword": encryptPwd(_newPass.text),
        "email": activeUser,
        "oldPassword": encryptPwd(_oldPass.text),
      },
    );
    if (response.statusCode == 200) {
      Map json = jsonDecode(response.body);
      message = json["message"];
      if (json["result"] == "success") {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    } else {
      throw Exception("Failed to read API");
    }
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

// Confirmation Dialog
Future<bool?> confirmationBox(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirmation!"),
        content: const Text("Are you sure you want to change your password?"),
        actions: <Widget>[
          MyButtonWhite(
              label: "Cancel",
              onTap: () {
                Navigator.of(context).pop(false);
              }),
          MyButtonCalmBlue(
            label: "Change it",
            onTap: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}
