import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> signOutUser() async {
  try {
    await FirebaseAuth.instance.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    print("User signed out successfully");
  } catch (e) {
    print("Error signing out: $e");
  }
}

class Logout_button extends StatelessWidget {
  const Logout_button({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.logout),
      label: Text('Logout'),
      onPressed: () async {
        await signOutUser();
        Navigator.pushReplacementNamed(context, '/login');
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
    );
  }
}
