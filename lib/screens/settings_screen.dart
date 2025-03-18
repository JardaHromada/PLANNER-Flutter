import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/widgets/bottom_bar_button.dart';
import '/widgets/profile_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = snapshot.data();
    final displayName = userData?['name'] ?? '';
    setState(() {
      _nameController.text = displayName;
    });
  }

  Future<void> _updateUserName() async {
    setState(() {
      _isSaving = true;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jméno bylo úspěšně změněno')),
      );
    } catch (e) {
      print('Error updating name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepodařilo se změnit jméno')),
      );
    }
    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _updateUserPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesla se neshodují')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await user.updatePassword(_newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heslo bylo úspěšně změněno')),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      print('Error updating password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepodařilo se změnit heslo')),
      );
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0E181E),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ProfileSection(user: user),
          const SizedBox(height: 20),
          _buildUserNameForm(),
          const SizedBox(height: 20),
          _buildPasswordForm(),
          const Spacer(), 
          _buildAboutAppButton(context), 
          const SizedBox(height: 20),
          _buildBottomBar(context), 
        ],
      ),
    ),
  );
}

  // Formulář pro změnu uživatelského jména
  Widget _buildUserNameForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Změnit uživatelské jméno:',
            style: TextStyle(
              color: Color(0xFFE0F0FF),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Color(0xFFE0F0FF)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF12222B),
              hintText: 'Zadejte nové jméno',
              hintStyle: const TextStyle(color: Color(0xFF8A9BAE)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _updateUserName,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12222B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Uložit změny'),
          ),
        ],
      ),
    );
  }

  // Formulář pro změnu hesla
  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Změnit heslo:',
            style: TextStyle(
              color: Color(0xFFE0F0FF),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            style: const TextStyle(color: Color(0xFFE0F0FF)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF12222B),
              hintText: 'Nové heslo',
              hintStyle: const TextStyle(color: Color(0xFF8A9BAE)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Color(0xFFE0F0FF)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF12222B),
              hintText: 'Potvrďte nové heslo',
              hintStyle: const TextStyle(color: Color(0xFF8A9BAE)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _updateUserPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12222B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Změnit heslo'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutAppButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/aboutapp'); 
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF12222B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: const Text('O aplikaci'),
    ),
  );
}

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF12222B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomBarButton(context: context, label: 'skupiny', icon: Icons.group, route: '/groups'),
          BottomBarButton(context: context, label: 'cíle', icon: Icons.flag, route: '/goals'),
          BottomBarButton(context: context, label: 'úkoly', icon: Icons.task, route: '/mytasks'),
          BottomBarButton(context: context, label: 'to do', icon: Icons.chat, route: '/todo'),
          BottomBarButton(context: context, label: 'nastavení', icon: Icons.settings, route: '/settings', isSpecial: true),
        ],
      ),
    );
  }
}
