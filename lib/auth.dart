import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pickleapp/main.dart';
import 'package:pickleapp/screen/page/sign_in.dart';

String userID = "";
bool isLogin = false;

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            User? user = snapshot.data;
            if (user!.emailVerified) {
              userID = FirebaseAuth.instance.currentUser!.uid;
              return MyHomePage(
                  currentIndex: 0, isLoading: (isLogin == true ? true : false));
            } else {
              return const MySignIn();
            }
          } else {
            return const MySignIn();
          }
        },
      ),
    );
  }
}
