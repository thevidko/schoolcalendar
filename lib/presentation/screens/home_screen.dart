import 'package:flutter/material.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../widgets/subject_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mockovaná data
    final subjects = [
      Subject(id: '1', name: 'Matematika', code: 'MAT101'),
      Subject(id: '2', name: 'Dějepis', code: 'HIS102'),
    ];

    final tasks = [
      Task(
        id: '1',
        subjectId: '1',
        title: 'Test z algebry',
        dueDate: DateTime.now().add(const Duration(days: 3)),
      ),
      Task(
        id: '2',
        subjectId: '1',
        title: 'Odevzdání domácího úkolu',
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      Task(
        id: '3',
        subjectId: '2',
        title: 'Esej o Husitech',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Školní kalendář')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children:
            subjects.map((subject) {
              final subjectTasks =
                  tasks.where((task) => task.subjectId == subject.id).toList();
              return SubjectCard(subject: subject, tasks: subjectTasks);
            }).toList(),
      ),
    );
  }
}
