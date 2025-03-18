import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  TimeOfDay? _selectedTime;
  DateTime _selectedDay = DateTime.now();
  String selectedRepeat = 'none';

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final groupId = arguments['groupId'];
    final groupName = arguments['groupName'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF12222B),
        title: Text(
          groupName,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/groupInfo',
                arguments: {'groupId': groupId, 'groupName': groupName},
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0E181E),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildCalendar(),
            _buildTaskSection(groupId),
            _buildChatSection(groupId),
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

  Widget _buildTaskSection(String groupId) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => _showAddTaskDialog(groupId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 35, 74, 97),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Přidat úkol'),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('tasks')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Žádné úkoly pro tento den',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final tasks = snapshot.data!.docs;

              // Seřazení úkolů podle času
              tasks.sort((a, b) {
                final timeA = a['dueTime'] as String?;
                final timeB = b['dueTime'] as String?;
                if (timeA == null) return 1;
                if (timeB == null) return -1;
                return timeA.compareTo(timeB);
              });

              final filteredTasks = tasks.where((task) {
                DateTime taskDate = DateTime.parse(task['dueDate']);
                String repeat = task['repeat'] ?? 'none';

                if (repeat == 'none') {
                  return isSameDay(_selectedDay, taskDate);
                }

                if (_selectedDay.isBefore(taskDate)) return false;

                if (repeat == 'daily') return true;
                if (repeat == 'weekly' && _selectedDay.weekday == taskDate.weekday) return true;
                if (repeat == 'monthly' && _selectedDay.day == taskDate.day) return true;

                return false;
              }).toList();

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  var task = filteredTasks[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(
                        task['note'] != null && task['note'] != ''
                            ? '${task['title']} - Poznámka: ${task['note']}'
                            : task['title'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        task['dueTime'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.note_add, color: Colors.amber),
                            onPressed: () => _showEditNoteDialog(context, groupId, task.id, task['note'] ?? ''),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteTask(groupId, task.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(String groupId) async {
    _titleController.clear();
    _noteController.clear();
    _selectedTime = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Přidat úkol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Název úkolu'),
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
                      _selectedTime = pickedTime;
                    });
                  }
                },
                child: Text(
                  _selectedTime != null
                      ? 'Čas: ${_selectedTime!.format(context)}'
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
                  setState(() {
                    selectedRepeat = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _addTask(groupId, _titleController.text, _selectedTime, _noteController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Přidat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTask(String groupId, String title, TimeOfDay? time, String note) async {
    if (title.isEmpty) return;

    final taskData = {
      'title': title,
      'dueDate': _selectedDay.toIso8601String().split('T').first,
      'dueTime': time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : null,
      'note': note,
      'repeat': selectedRepeat,
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .add(taskData);
  }

  Future<void> _deleteTask(String groupId, String taskId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  void _showEditNoteDialog(BuildContext context, String groupId, String taskId, String currentNote) {
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
                await _updateTaskNote(groupId, taskId, noteController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTaskNote(String groupId, String taskId, String note) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'note': note,
    });
  }

  Widget _buildChatSection(String groupId) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF12222B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Text(
              'Skupinový chat',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(message['senderId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          String senderName = 'Neznámý';

                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            senderName = userData['name'] ?? 'Neznámý';
                          }

                          return ListTile(
                            title: Text(
                              senderName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              message['content'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Napište zprávu...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _sendMessage(groupId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String groupId) async {
    if (_taskController.text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'content': _taskController.text,
      'senderId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _taskController.clear();
  }
}
