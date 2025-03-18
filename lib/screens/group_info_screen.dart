import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final groupId = arguments['groupId'];
    final groupName = arguments['groupName'];
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF12222B),
        title: Text(
          'Správa Skupiny: $groupName',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Skupina nenalezena', style: TextStyle(color: Colors.white)),
            );
          }

          final groupDataMap = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final members = groupDataMap.containsKey('members')
              ? List<String>.from(groupDataMap['members'])
              : [];
          final adminId = groupDataMap['admin'];
          final isAdmin = user!.uid == adminId;

          return Container(
            color: const Color(0xFF0E181E),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAdmin) ...[
                  _buildAddUserSection(context, groupId),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Členové skupiny',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final memberId = members[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(memberId).get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Načítání...', style: TextStyle(color: Colors.white)),
                            );
                          }
                          if (!userSnapshot.hasData || userSnapshot.data == null) {
                            return const ListTile(
                              title: Text('Uživatel nenalezen', style: TextStyle(color: Colors.white)),
                            );
                          }

                          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                          final userName = userData['name'] ?? 'Neznámý uživatel';

                          return ListTile(
                            title: Text(
                              userName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: isAdmin && memberId != adminId // Admin can't remove themselves
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _removeMember(context, groupId, memberId),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  ElevatedButton(
                    onPressed: () => _deleteGroup(context, groupId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Smazat Skupinu', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _leaveGroup(context, groupId, user.uid),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Opustit Skupinu', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddUserSection(BuildContext context, String groupId) {
    final TextEditingController emailController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Přidat člena do skupiny',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Email uživatele',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF12222B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addUserToGroup(context, groupId, emailController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
              child: const Text('Přidat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addUserToGroup(BuildContext context, String groupId, String userEmail) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uživatel s tímto emailem nebyl nalezen')),
        );
        return;
      }

      final userId = userSnapshot.docs.first.id;

      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'groups': FieldValue.arrayUnion([groupId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uživatel úspěšně přidán do skupiny')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeMember(BuildContext context, String groupId, String memberId) async {
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });

      await FirebaseFirestore.instance.collection('users').doc(memberId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Člen byl úspěšně odebrán ze skupiny')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: ${e.toString()}')),
      );
    }
  }

  void _deleteGroup(BuildContext context, String groupId) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
    Navigator.pushNamedAndRemoveUntil(context, '/groups', (route) => false);
  }

  void _leaveGroup(BuildContext context, String groupId, String userId) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'groups': FieldValue.arrayRemove([groupId]),
    });

    Navigator.pushNamedAndRemoveUntil(context, '/groups', (route) => false);
  }
}
