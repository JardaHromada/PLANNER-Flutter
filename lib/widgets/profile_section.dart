import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSection extends StatelessWidget {
  final User user;

  const ProfileSection({super.key, required this.user});

  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildProfileContent(context, user.email!);
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final displayName = userData?['name'] ?? user.email;

        return _buildProfileContent(context, displayName);
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFF0E181E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Přihlášen jako: $displayName',
            style: const TextStyle(
              color: Color(0xFFE0F0FF),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.15,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFE0F0FF)),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
