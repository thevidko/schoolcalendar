import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/presentation/screens/subject_detail.dart';
import 'task_item.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final List<Task> tasks;

  const SubjectCard({super.key, required this.subject, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    SubjectDetailScreen(subjectIdString: subject.id.toString()),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Color.fromARGB(255, 59, 59, 59),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${subject.name} (${subject.code})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                const Text(
                  'Žádné nadcházející termíny.',
                  style: TextStyle(fontSize: 14),
                )
              else
                Column(
                  children: tasks.map((task) => TaskItem(task: task)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
