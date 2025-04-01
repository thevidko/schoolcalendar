import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'task_item.dart';
import 'package:intl/intl.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final List<Task> tasks;

  const SubjectCard({super.key, required this.subject, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${subject.name} (${subject.code})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Text(
                'Žádné nadcházející termíny.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: tasks.map((task) => TaskItem(task: task)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
