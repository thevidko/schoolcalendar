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
            builder: (context) => SubjectDetailScreen(subjectId: subject.id),
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ), // Added horizontal margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ), // Increased padding for better spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${subject.name} (${subject.code})',
                style: const TextStyle(
                  fontSize: 20, // Slightly larger font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Darker text color
                ),
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                const Text(
                  'Žádné nadcházející termíny.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14, // Slightly smaller font size for subtler text
                  ),
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
