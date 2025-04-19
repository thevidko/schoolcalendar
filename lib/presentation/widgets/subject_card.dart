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
    final theme = Theme.of(context); // Získáme aktuální téma
    final colorScheme = theme.colorScheme;

    final isDarkMode = theme.brightness == Brightness.dark;

    final cardColor =
        isDarkMode
            ? colorScheme.surfaceContainerLow
            : colorScheme.onInverseSurface;

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
        elevation: 10,
        color: cardColor,
        shadowColor: theme.shadowColor,
        borderOnForeground: true,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).primaryColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${subject.name} (${subject.code})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                Text(
                  'Žádné nadcházející termíny.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
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
