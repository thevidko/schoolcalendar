// task_item_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/provider/task_provider.dart'; // Upravte cestu

class TaskItemDetail extends StatelessWidget {
  final Task task;

  const TaskItemDetail({
    Key? key, // Použijte Key? key a předejte ho super konstruktoru
    required this.task,
  }) : super(key: key);

  // Metoda pro zobrazení potvrzovacího dialogu smazání
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Smazat úkol?'),
            content: Text('Opravdu si přejete smazat úkol "${task.title}"?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Zrušit'),
                onPressed:
                    () => Navigator.of(ctx).pop(false), // Zavřít a vrátit false
              ),
              TextButton(
                child: const Text(
                  'Smazat',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed:
                    () => Navigator.of(ctx).pop(true), // Zavřít a vrátit true
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Získáme TaskProvider bez listen: false, protože ho potřebujeme jen pro volání akcí
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Kontrola termínu - porovnáváme jen datum (ignorujeme čas)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    bool isOverdue = !task.isCompleted && dueDateOnly.isBefore(today);

    // Formátování zbývajícího času (zjednodušené pro přehlednost)
    String timeStatus = '';
    if (task.isCompleted) {
      timeStatus = 'Splněno';
    } else if (isOverdue) {
      timeStatus = 'Po termínu';
    } else {
      Duration remaining = task.dueDate.difference(now);
      if (remaining.inDays > 0) {
        timeStatus = 'Zbývá ${remaining.inDays} d.';
      } else if (remaining.inHours > 0) {
        timeStatus = 'Zbývá ${remaining.inHours} hod.';
      } else if (remaining.inMinutes > 0) {
        timeStatus = 'Zbývá ${remaining.inMinutes} min.';
      } else {
        timeStatus = 'Termín dnes'; // Nebo "Méně než minuta"
      }
    }

    // Barvy podle stavu
    Color defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black; // Výchozí barva textu
    Color textColor =
        task.isCompleted
            ? Colors
                .grey // Šedá pro splněné
            : (isOverdue ? Colors.red : defaultTextColor); // Červená pro prošlé
    Color statusColor =
        task.isCompleted
            ? Colors.grey
            : (isOverdue ? Colors.red : Colors.green); // Zelená pro aktivní

    return Dismissible(
      key: ValueKey(task.id), // Unikátní klíč pro Dismissible
      direction:
          DismissDirection.startToEnd, // Povolí swipe pouze zleva doprava
      background: Container(
        color: task.isCompleted ? Colors.red.shade700 : Colors.green.shade600,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(
          task.isCompleted ? Icons.delete_forever : Icons.check_circle_outline,
          color: Colors.white,
        ),
      ),
      // confirmDismiss se zavolá PŘED onDismissed
      confirmDismiss: (direction) async {
        if (task.isCompleted) {
          // Pokud je úkol splněný, zobrazíme dialog pro potvrzení smazání
          return await _showDeleteConfirmationDialog(
            context,
          ); // Vrátí true/false
        } else {
          // Pokud úkol není splněný, automaticky potvrdíme (označí se jako splněný)
          return true;
        }
      },
      // onDismissed se zavolá POUZE pokud confirmDismiss vrátil true
      onDismissed: (direction) {
        // Zobrazíme Snackbar hned
        final String message =
            task.isCompleted
                ? 'Úkol "${task.title}" smazán.'
                : 'Úkol "${task.title}" označen jako splněný.';
        ScaffoldMessenger.of(
          context,
        ).removeCurrentSnackBar(); // Odstraní případný předchozí snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );

        // --- ZMĚNA ZDE: Použití Future.delayed(Duration.zero) ---
        Future.delayed(Duration.zero, () {
          // Zkontrolujeme, zda je widget stále připojený (mounted),
          // i když by při tomto krátkém zpoždění měl být.
          if (context.mounted) {
            if (task.isCompleted) {
              // Akce smazání
              taskProvider.deleteTask(task.id);
            } else {
              // Akce označení jako splněno
              taskProvider.updateTaskCompletion(context, task.id, true);
            }
          }
        });
        // --- KONEC ZMĚNY ---
      },
      child: ListTile(
        // contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            // Přeškrtnutí pro splněné úkoly
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: Colors.grey,
          ),
        ),
        subtitle: Text(
          // Zobrazíme i čas, pokud je relevantní
          'Termín: ${DateFormat('dd.MM.yyyy HH:mm').format(task.dueDate)}',
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: Colors.grey,
          ),
        ),
        trailing: Text(
          timeStatus,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
