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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 16,
          color:
              isOverdue
                  ? Colors.red
                  : Colors.black, // Červená pro starší termíny
        ),
      ),
      subtitle: Text(
        'Termín: ${DateFormat('dd.MM.yyyy').format(task.dueDate)}',
        style: TextStyle(
          color:
              isOverdue
                  ? Colors.red
                  : Colors.black, // Červená pro starší termíny
        ),
      ),
      trailing:
          task.isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
    );
  }
}
