import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart'; 
import '/screens/home_screen.dart'; 
import '/screens/mytasks_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder:(context, snapshot) {
          // logged in
          if (snapshot.hasData){
            return const MyTaskScreen(); //go into app
          }
          // not logged in
          else {
            return const HomeScreen(); //go to the opening(home) page
          }
        },
      ),
    );
  }
}