import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pickleapp/main.dart';
import 'package:pickleapp/screen/page/signIn.dart';

String userID = "";

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for auth state
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            // User is signed in
            userID = FirebaseAuth.instance.currentUser!.uid;
            return MyHomePage();
          } else {
            // User is not signed in, show sign-in page
            return MySignIn();
          }
        },
      ),
    );
  }
}
