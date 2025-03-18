import 'package:flutter/material.dart';
import '/widgets/my_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            children: [
              const SizedBox(height: 74),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                decoration: ShapeDecoration(
                  color: const Color(0xFF12222B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(56),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'PLANNER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 74),
              MyButton(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                text: 'Přihlásit se',
              ),
              const SizedBox(height: 20),
              MyButton(
                onTap: () {
                  Navigator.pushNamed(context, '/signIn');
                },
                text: 'Registrovat se',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
