import 'package:flutter/material.dart';
import '/widgets/bottom_bar_button.dart';
import '/widgets/profile_section.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:table_calendar/table_calendar.dart';

class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});

  @override
  _MyTaskScreenState createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime _selectedDay = DateTime.now();
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  void _fetchUserName() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      userName = userDoc['name'] ?? 'Unknown';
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
            _buildCalendar(),
            Expanded(child: _buildTaskList(context)),
            _buildAddTaskButton(context),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(8.0),
      child: TableCalendar(
        locale: 'cs_CZ',
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _selectedDay,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
          });
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color.fromARGB(255, 35, 74, 97),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white),
          weekendStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final tasks = snapshot.data!.docs.where((task) {
        DateTime taskDate = DateTime.parse(task['dueDate']);
        String repeat = task['repeat'] ?? 'none';

        if (repeat == 'none') {
          return isSameDay(_selectedDay, taskDate);
        }
        
        // Opakované úkoly začínají ode dne, kdy byly vytvořeny
        if (_selectedDay.isBefore(taskDate)) return false;

        if (repeat == 'daily') return true;
        if (repeat == 'weekly' && _selectedDay.weekday == taskDate.weekday) return true;
        if (repeat == 'monthly' && _selectedDay.day == taskDate.day) return true;

        return false;
      }).toList();

      if (tasks.isEmpty) {
        return const Center(
          child: Text('Žádné úkoly', style: TextStyle(color: Colors.white)),
        );
      }

      return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          var task = tasks[index];
          return ListTile(
            title: Text(
              task['title'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['dueTime'] ?? 'Bez času',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (task['note'] != null && task['note']!.isNotEmpty)
                  Text(
                    "Poznámka: ${task['note']}",
                    style: const TextStyle(color: Colors.amber),
                  ),
              ],
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
                  onPressed: () => _deleteTask(task.id, task['title'], task['repeat']),
                ),
              ],
            ),
          );         
        },
      );
    },
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

  void _deleteTask(String taskId, String taskTitle, String repeat) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Smazat úkol'),
        content: const Text('Chcete smazat pouze tento výskyt nebo všechny?'),
        actions: [
          // Pouze tento výskyt (smaže konkrétní úkol podle ID)
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .doc(taskId)
                  .delete();
              Navigator.of(context).pop();
            },
            child: const Text('Pouze tento'),
          ),

          // Smazat všechny opakované úkoly (s názvem a stejným opakováním)
          if (repeat != 'none')
            TextButton(
              onPressed: () async {
                QuerySnapshot tasks = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('tasks')
                    .where('title', isEqualTo: taskTitle) 
                    .where('repeat', isEqualTo: repeat)  
                    .get();

                for (var doc in tasks.docs) {
                  await doc.reference.delete();
                }
                Navigator.of(context).pop();
              },
              child: const Text('Všechny'),
            ),
        ],
      );
    },
  );
}


  Widget _buildAddTaskButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton(
        onPressed: () => _showAddTaskDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 35, 74, 97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Přidat úkol'),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  String selectedRepeat = 'none'; 
  TimeOfDay? selectedTime; 

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Přidat úkol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Název úkolu'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Poznámka'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }
              },
              child: Text(
                selectedTime != null
                    ? 'Čas: ${selectedTime!.format(context)}'
                    : 'Vybrat čas',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedRepeat,
              decoration: const InputDecoration(labelText: 'Opakování'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Neopakovat')),
                DropdownMenuItem(value: 'daily', child: Text('Denně')),
                DropdownMenuItem(value: 'weekly', child: Text('Týdně')),
                DropdownMenuItem(value: 'monthly', child: Text('Měsíčně')),
              ],
              onChanged: (value) {
                selectedRepeat = value!;
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _addTask(
                titleController.text,
                selectedTime,
                noteController.text,
                selectedRepeat,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Přidat'),
          ),
        ],
      );
    },
  );
}



  Future<void> _addTask(String title, TimeOfDay? dueTime, String note, String repeat) async {
  if (title.isEmpty) {
    print("Title cannot be empty");
    return;
  }

  final taskData = {
    'title': title,
    'dueDate': _selectedDay.toIso8601String().split('T').first,
    'dueTime': dueTime != null
        ? '${dueTime.hour.toString().padLeft(2, '0')}:${dueTime.minute.toString().padLeft(2, '0')}'
        : null,
    'note': note,
    'repeat': repeat,
  };

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .add(taskData);
    print("Task added successfully");
  } catch (e) {
    print("Error adding task: $e");
  }
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
          BottomBarButton(context: context, label: 'úkoly', icon: Icons.task, route: '/mytasks', isSpecial: true),
          BottomBarButton(context: context, label: 'to do', icon: Icons.chat, route: '/todo'),
          BottomBarButton(context: context, label: 'nastavení', icon: Icons.settings, route: '/settings'),
        ],
      ),
    );
  }
}
