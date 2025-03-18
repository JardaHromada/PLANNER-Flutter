import 'package:flutter/material.dart';
import '/widgets/profile_section.dart';
import '/widgets/bottom_bar_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalNoteController = TextEditingController();

  DateTime? _selectedDate;

  List<Map<String, dynamic>> activeGoals = [];
  List<Map<String, dynamic>> completedGoals = [];
  List<String> _groupList = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadGroups(); 
  }

  // Načtení cílů z Firestore
  void _loadGoals() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .orderBy('order')
        .get();

    final List<Map<String, dynamic>> active = [];
    final List<Map<String, dynamic>> completed = [];

    for (var doc in snapshot.docs) {
      final goal = {
        'id': doc.id,
        ...doc.data(),
      };

      if (goal['isChecked'] == true) {
        completed.add(goal);
      } else {
        active.add(goal);
      }
    }

    setState(() {
      activeGoals = active;
      completedGoals = completed;
    });
  }

  // Načítání seznamu skupin z Firestore
  void _loadGroups() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goalGroups')
        .get();

    setState(() {
      _groupList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  void _addGroup() async {
    final TextEditingController _groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Přidat novou skupinu'),
          content: TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(labelText: 'Název skupiny'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String groupName = _groupNameController.text.trim();

                if (groupName.isNotEmpty) {
                
                  final docRef = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('goalGroups')
                      .add({'name': groupName});

                  
                  setState(() {
                    _selectedGroup = groupName;
                  });

                  print("Nová skupina přidána s ID: ${docRef.id}"); 

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Přidat'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGroup(String groupName) async {
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goalGroups')
        .where('name', isEqualTo: groupName)
        .get();

    if (querySnapshot.docs.isEmpty) return; // Pokud skupina neexistuje, nic se nestane

    final docId = querySnapshot.docs.first.id; // ID skupiny

    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .where('group', isEqualTo: groupName)
        .get();

    for (var doc in tasksSnapshot.docs) {
      await doc.reference.delete();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goalGroups')
        .doc(docId)
        .delete();

    _loadGroups();

    setState(() {
      if (_selectedGroup == groupName) {
        _selectedGroup = _groupList.isNotEmpty ? _groupList.first : 'Obecné';
      }
    });
  }

  Widget _buildGroupDropdown() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('goalGroups')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final groups = snapshot.data!.docs.map((doc) => doc['name'] as String).toList();

              if (!groups.contains(_selectedGroup)) {
                _selectedGroup = groups.isNotEmpty ? groups.first : "Obecné";
              }

              return DropdownButtonFormField<String>(
                value: _selectedGroup,
                items: groups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Skupina',
                  filled: true,
                  fillColor: const Color(0xFF12222B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8), 
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            if (_groupList.isNotEmpty) {
              _deleteGroup(_selectedGroup);
            }
          },
        ),
      ],
    );
  }

  void _addGoal() async {
    final String title = _goalTitleController.text.trim();
    final String note = _goalNoteController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplňte název cíle.')),
      );
      return;
    }

    final newGoal = {
      'title': title,
      'note': note,
      'date': _selectedDate?.toIso8601String(),
      'isChecked': false,
      'createdAt': DateTime.now().toIso8601String(),
      'order': activeGoals.length, 
      'group': _selectedGroup, 
    };


    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .add(newGoal);

      setState(() {
        activeGoals.add({'id': doc.id, ...newGoal});
      });

      _goalTitleController.clear();
      _goalNoteController.clear();
      _selectedDate = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chyba při vytváření cíle.')),
      );
    }
  }

  void _toggleGoal(String id, bool isChecked) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc(id)
        .update({'isChecked': isChecked});

    _loadGoals();
  }

  void _deleteGoal(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc(id)
        .delete();

    _loadGoals();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _reorderGoals(int oldIndex, int newIndex, bool isCompleted) {
    setState(() {
      final List<Map<String, dynamic>> goals = isCompleted ? completedGoals : activeGoals;
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final goal = goals.removeAt(oldIndex);
      goals.insert(newIndex, goal);
    });

    for (int i = 0; i < activeGoals.length; i++) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(activeGoals[i]['id'])
          .update({'order': i});
    }
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
            const SizedBox(height: 10),
            _buildGoalInputForm(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildGoalLists(),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // Formulář pro přidání cíle
  String _selectedGroup = 'Obecné'; // Výchozí skupina

  Widget _buildGoalInputForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nový cíl:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _goalTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Název cíle',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF12222B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _goalNoteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Poznámka',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF12222B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildGroupDropdown()), // Výběr skupiny
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueAccent),
                onPressed: _addGroup, // Otevře dialog pro přidání skupiny
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _selectDate, // Odkaz na metodu
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 35, 74, 97),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _selectedDate != null
                  ? 'Datum: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}'
                  : 'Vyberte datum',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 35, 74, 97),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Přidat cíl'),
          ),
        ],
      ),
    );
  }


  // Zobrazení seznamu cílů
  Widget _buildGoalLists() {
    Map<String, List<Map<String, dynamic>>> groupedGoals = {};

    for (var goal in activeGoals) {
      String group = goal['group'] ?? 'Obecné';
      groupedGoals.putIfAbsent(group, () => []);
      groupedGoals[group]!.add(goal);
    }

    for (var goal in completedGoals) {
      String group = goal['group'] ?? 'Obecné';
      groupedGoals.putIfAbsent(group, () => []);
      groupedGoals[group]!.add(goal);
    }

    return ListView(
      children: groupedGoals.entries.map((entry) {
        bool isCompleted = entry.value.every((goal) => goal['isChecked'] == true);
        return _buildDraggableGoalSection(entry.key, entry.value, isCompleted);
      }).toList(),
    );
  }

  void _changeGoalGroup(String taskId, String newGroupName) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc(taskId)
        .update({'group': newGroupName});

    _loadGoals(); // Aktualizace úkolů
  }

  Widget _buildDraggableGoalSection(
    String title, List<Map<String, dynamic>> goals, bool isCompleted) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) => _reorderGoals(oldIndex, newIndex, isCompleted),
          children: goals.map((goal) {
            return Padding(
              key: ValueKey(goal['id']),
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF12222B), 
                  borderRadius: BorderRadius.circular(12.0), 
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  title: Text(
                    goal['title'],
                    style: TextStyle(
                      color: goal['isChecked'] ? Colors.grey : Colors.white,
                      decoration: goal['isChecked'] ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (goal['note'] != null && goal['note']!.isNotEmpty)
                        Text(
                          goal['note'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      if (goal['date'] != null)
                        Text(
                          'Datum: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(goal['date']))}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 130, // Zvýšeno pro přidání tlačítka na přesun skupiny
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Checkbox(
                          value: goal['isChecked'],
                          onChanged: (value) => _toggleGoal(goal['id'], value!),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.swap_horiz, color: Colors.blueAccent),
                          onSelected: (newGroup) => _changeGoalGroup(goal['id'], newGroup),
                          itemBuilder: (context) => _groupList
                              .where((group) => group != goal['group']) // Skryje aktuální skupinu
                              .map((group) => PopupMenuItem(value: group, child: Text(group)))
                              .toList(),
                        ),
                        GestureDetector(
                          onTap: () => _deleteGoal(goal['id']),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          BottomBarButton(context: context, label: 'cíle', icon: Icons.flag, route: '/goals', isSpecial: true),
          BottomBarButton(context: context, label: 'úkoly', icon: Icons.task, route: '/mytasks'),
          BottomBarButton(context: context, label: 'to do', icon: Icons.chat, route: '/todo'),
          BottomBarButton(context: context, label: 'nastavení', icon: Icons.settings, route: '/settings'),
        ],
      ),
    );
  }
}

