import 'package:flutter/material.dart';
import '/widgets/bottom_bar_button.dart';
import '/widgets/profile_section.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ToDoScreen extends StatelessWidget {
  ToDoScreen({super.key});
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
            Expanded(child: _buildUpcomingTasksAndPastWeekTasks(context)), 
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTasksAndPastWeekTasks(BuildContext context) {
    final now = DateTime.now();
    final pastWeekStart = now.subtract(const Duration(days: 7)); 

    return Column(
      children: [
        _buildTaskSection(
          context,
          title: 'Nadcházející úkoly',
          query: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('tasks')
              .orderBy('dueDate')
              .snapshots(),
          emptyMessage: 'Žádné nadcházející úkoly',
          color: Colors.white,
          isFutureTasks: true,
        ),
        const SizedBox(height: 16),
        _buildTaskSection(
          context,
          title: 'Úkoly z posledního týdne',
          query: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('tasks')
              .where('dueDate', isGreaterThanOrEqualTo: pastWeekStart.toIso8601String().split('T').first) 
              .where('dueDate', isLessThanOrEqualTo: now.toIso8601String().split('T').first)
              .orderBy('dueDate', descending: true)
              .snapshots(),
          emptyMessage: 'Žádné úkoly z posledního týdne',
          color: Colors.redAccent,
          isFutureTasks: false,
        ),
      ],
    );
  }

  Widget _buildTaskSection(
  BuildContext context, {
  required String title,
  required Stream<QuerySnapshot> query,
  required String emptyMessage,
  required Color color,
  required bool isFutureTasks, 
}) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print("Error fetching tasks: ${snapshot.error}");
                return const Center(
                  child: Text(
                    'Chyba při načítání úkolů',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: color),
                  ),
                );
              }

              final tasks = snapshot.data!.docs.where((task) {
                DateTime taskDate = DateTime.parse(task['dueDate']);
                String repeat = task['repeat'] ?? 'none';

                if (isFutureTasks) {
                  // Nadcházející úkoly – zobrazíme pouze budoucí úkoly a opakované
                  if (taskDate.isBefore(DateTime.now()) && repeat == 'none') return false;

                  if (repeat == 'daily') return true;
                  if (repeat == 'weekly' && DateTime.now().weekday == taskDate.weekday) return true;
                  if (repeat == 'monthly' && DateTime.now().day == taskDate.day) return true;

                  return taskDate.isAfter(DateTime.now());
                } else {
                  // Úkoly z minulého týdne – zobrazíme pouze úkoly v rozmezí posledních 7 dnů
                  final pastWeekStart = DateTime.now().subtract(const Duration(days: 7));

                  if (taskDate.isBefore(pastWeekStart) && repeat == 'none') return false;

                  if (repeat == 'daily') return true;
                  if (repeat == 'weekly' && pastWeekStart.weekday == taskDate.weekday) return true;
                  if (repeat == 'monthly' && pastWeekStart.day == taskDate.day) return true;

                  return taskDate.isBefore(DateTime.now());
                }
              }).toList();

              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: color),
                  ),
                );
              }

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var task = tasks[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: color,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(
                        task['note'] != null && task['note'] != ''
                            ? '${task['title']} - Poznámka: ${task['note']}'
                            : task['title'],
                        style: TextStyle(color: color),
                      ),
                      subtitle: Text(
                        'Datum: ${task['dueDate']} - Čas: ${task['dueTime'] ?? "neuvedeno"}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.note_add, color: Colors.amber),
                            onPressed: () => _showEditNoteDialog(context, task.id, task['note'] ?? ''),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteTask(task.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}


  void _showEditNoteDialog(BuildContext context, String taskId, String currentNote) {
    final noteController = TextEditingController(text: currentNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upravit poznámku'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Poznámka'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _updateTaskNote(taskId, noteController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTaskNote(String taskId, String note) async {
    final userUid = user.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('tasks')
        .doc(taskId)
        .update({'note': note});
  }

  void _deleteTask(String taskId) async {
    final userUid = user.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('tasks')
        .doc(taskId)
        .delete();
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
          BottomBarButton(context: context, label: 'to do', icon: Icons.chat, route: '/todo', isSpecial: true),
          BottomBarButton(context: context, label: 'nastavení', icon: Icons.settings, route: '/settings'),
        ],
      ),
    );
  }
}
