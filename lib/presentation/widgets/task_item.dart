import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolcalendar/data/db/database.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    // Kontrola, zda je termín úkolu starší než dnešní datum
    bool isOverdue = task.dueDate.isBefore(DateTime.now());

    // Výpočet zbývajícího času
    Duration remainingTime = task.dueDate.difference(DateTime.now());

    // Formátování zbývajícího času pro zobrazení
    String timeRemaining =
        isOverdue
            ? 'Po termínu'
            : [
              if (remainingTime.inDays > 0) '${remainingTime.inDays} dní',
              if (remainingTime.inHours % 24 > 0)
                '${remainingTime.inHours % 24} hodin',
              if (remainingTime.inMinutes % 60 > 0)
                '${remainingTime.inMinutes % 60} minut',
            ].join(' ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 16,
          color:
              isOverdue
                  ? Colors.red
                  : Theme.of(
                    context,
                  ).colorScheme.primary, // Červená pro starší termíny
        ),
      ),
      subtitle: Text(
        'Termín: ${DateFormat('dd.MM.yyyy').format(task.dueDate)}',
        style: TextStyle(
          color:
              isOverdue
                  ? Colors.red
                  : Theme.of(
                    context,
                  ).colorScheme.primary, // Červená pro starší termíny
        ),
      ),
      trailing:
          isOverdue
              ? Text(
                timeRemaining,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
              : Text(
                timeRemaining,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }
}
