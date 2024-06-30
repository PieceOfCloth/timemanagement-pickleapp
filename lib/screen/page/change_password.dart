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
                'Please fill with the correct current password, Thank you!',
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
        title: 'Verify Update Password',
        message:
            "We've sent you an email to change your password. Please check your email and complete the verification process before change your password. Thank you!",
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      if (e.code == 'invalid-email') {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Invalid Email',
          message:
              "Your email address is not valid, please to fill the email correctly.",
        );
      } else if (e.code == 'user-not-found') {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Email Not Found',
          message:
              "There is no account with your email, Please to fill the correct one.",
        );
      } else if (e.code == "invalid-credential") {
        AlertInformation.showDialogBox(
          context: context,
          title: 'Incorrect Input',
          message:
              "Your email address or password isn't correct, please try again.",
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
          'Change Password',
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
                              hintText: "Enter your email here",
                              hintStyle: textStyleGrey,
                            ),
                            validator: (value) {
                              if (value == "" || value == null) {
                                return 'Please fill this field';
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
                    "Current Password",
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
                              hintText:
                                  "Enter your current secret password here",
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
                                return 'Please fill this field with your current password.';
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
                            'Password Change',
                            style: subHeaderStyleBold,
                          ),
                          content: Text('Are you sure want to change it?',
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
                                  'Change it',
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
                                  'Cancel',
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
                    "Change Password",
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
