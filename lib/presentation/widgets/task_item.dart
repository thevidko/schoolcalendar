import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolcalendar/data/db/database.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(task.title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        'Termín: ${DateFormat('dd.MM.yyyy').format(task.dueDate)}',
      ),
      trailing:
          task.isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
    );
  }
}
