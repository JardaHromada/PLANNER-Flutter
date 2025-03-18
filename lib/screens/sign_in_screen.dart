import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/my_textfield.dart';
import '/widgets/my_button.dart';
import '/screens/auth_page.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  final nameController = TextEditingController(); 

  // sign up method
  void signUserUp(BuildContext context) async {
    try {
      if (passwordController.text == confirmpasswordController.text) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Uložení jména do Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': nameController.text,
          'email': emailController.text,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 52,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: const BoxDecoration(color: Color(0xFF0E181E)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Vytvořit účet',
                      style: TextStyle(
                        color: Color(0xFFE0F0FF),
                        fontSize: 22,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: ShapeDecoration(
                  color: const Color(0xFF0E181E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    MyTextField(
                      controller: nameController,
                      hintText: "Jméno",
                      obscureText: false,), 
                    const SizedBox(height: 24),
                    MyTextField(
                        controller: emailController,
                        hintText: "Email",
                        obscureText: false),
                    const SizedBox(height: 24),
                    MyTextField(
                        controller: passwordController,
                        hintText: "Heslo",
                        obscureText: true),
                    const SizedBox(height: 24),
                    MyTextField(
                        controller: confirmpasswordController,
                        hintText: "Potvrdit heslo",
                        obscureText: true),
                    const SizedBox(height: 24),
                    MyButton(
                        text: "Registrovat se",
                        onTap: () => signUserUp(context)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
