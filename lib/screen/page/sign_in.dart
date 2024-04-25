import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pickleapp/screen/page/forgot_password.dart';
import 'package:pickleapp/screen/page/sign_up.dart';
import 'package:pickleapp/theme.dart';
import 'package:pickleapp/screen/components/button_calm_blue.dart';
import 'package:pickleapp/screen/components/button_white.dart';

class MySignIn extends StatefulWidget {
  const MySignIn({super.key});

  @override
  State<MySignIn> createState() => _MySignInState();
}

class _MySignInState extends State<MySignIn> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(
          top: 40,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo aplikasi
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/app-logo.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Text(
                "Pickle Jar Planner",
                style: screenTitleStyle,
              ),
              const SizedBox(
                height: 40,
              ),
              // Input text email
              // ignore: avoid_unnecessary_containers
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
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
                              keyboardType: TextInputType.emailAddress,
                              // textCapitalization: TextCapitalization.sentences,
                              autofocus: false,
                              controller: _email,
                              style: textStyle,
                              decoration: InputDecoration(
                                hintText: "Enter your email here",
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
                      "Password",
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
                              controller: _password,
                              style: textStyle,
                              decoration: InputDecoration(
                                hintText: "Enter your secret password here",
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
                height: 20,
              ),
              // ignore: sized_box_for_whitespace
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Forgot password? ",
                    ),
                    GestureDetector(
                      onTap: () {
                        // print("tes klik forgot password");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyForgotPassword(),
                          ),
                        );
                      },
                      child: const Text(
                        "Click here",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              MyButtonCalmBlue(
                label: "Sign In",
                onTap: () {
                  submit();
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text(error_login),
                  //   ),
                  // );
                  // print(encryptPwd(_password.text));
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Or",
                style: textStyle,
              ),
              const SizedBox(
                height: 10,
              ),
              MyButtonWhite(
                label: "Sign Up",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MySignUp(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void submit() async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text,
        password: encryptPwd(_password.text),
      );

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful."),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code),
        ),
      );
    }
  }
  //   final response = await http.post(
  //     Uri.parse("http://192.168.1.13:8012/picklePHP/signIn.php"),
  //     body: {
  //       "email": _email.text,
  //       "pwd": encryptPwd(_password.text),
  //     },
  //   );
  //   if (response.statusCode == 200) {
  //     Map json = jsonDecode(response.body);
  //     message = json["message"];
  //     if (json["result"] == "success") {
  //       final prefs = await SharedPreferences.getInstance();
  //       prefs.setString("user_id", _email.text);
  //       // ignore: use_build_context_synchronously
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(message),
  //         ),
  //       );
  //       main();
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(message),
  //         ),
  //       );
  //     }
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }
}
