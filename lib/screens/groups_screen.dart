import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/widgets/bottom_bar_button.dart';
import '/widgets/profile_section.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final user = FirebaseAuth.instance.currentUser!;

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
            const SizedBox(height: 16),
            Expanded(
              child: _buildGroupsList(),
            ),
            _buildGroupCreationButton(),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // Button to open group creation dialog
  Widget _buildGroupCreationButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ElevatedButton(
          onPressed: _showGroupCreationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 35, 74, 97),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Vytvořit skupinu'),
        ),
      ),
    );
  }

  // Dialog for group creation
  void _showGroupCreationDialog() {
    final TextEditingController dialogController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E181E),
          title: const Text(
            'Vytvořit Novou Skupinu',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: dialogController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Název skupiny',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Color(0xFF12222B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Zrušit', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _createGroup(dialogController.text.trim());
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
              child: const Text('Vytvořit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Create group in Firestore
  void _createGroup(String groupName) async {
    if (groupName.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('groups').add({
      'name': groupName,
      'createdBy': user.uid, // Creator of the group
      'admin': user.uid, // Admin is the creator
      'members': [user.uid], // Add creator as the first member
      'timestamp': Timestamp.now(),
    });

    setState(() {
      // Rebuild UI after group creation
    });
  }

  // Display list of groups
  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid) // Filter groups by user membership
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Chyba při načítání skupin', style: TextStyle(color: Colors.white)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupName = group['name'];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF12222B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF35535A)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.group, color: Colors.white),
                title: Text(
                  groupName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/groupDetail',
                    arguments: {
                      'groupId': group.id,
                      'groupName': groupName,
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF12222B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomBarButton(context: context, label: 'skupiny', icon: Icons.group, route: '/groups', isSpecial: true),
          BottomBarButton(context: context, label: 'cíle', icon: Icons.flag, route: '/goals'),
          BottomBarButton(context: context, label: 'úkoly', icon: Icons.task, route: '/mytasks'),
          BottomBarButton(context: context, label: 'to do', icon: Icons.chat, route: '/todo'),
          BottomBarButton(context: context, label: 'nastavení', icon: Icons.settings, route: '/settings'),
        ],
      ),
    );
  }
}
