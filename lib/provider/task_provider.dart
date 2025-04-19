import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/provider/settings_provider.dart';
import 'package:schoolcalendar/repository/task_repository.dart';
import 'package:schoolcalendar/service/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider() {
    getAllTasks();
  }

  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _allTasks = [];
  List<Task> _tasksBySubject = [];

  List<Task> get allTasks => _allTasks;
  List<Task> get tasksBySubject => _tasksBySubject;

  Future<void> getAllTasks() async {
    _allTasks = await _taskRepository.allTasks();

    // Seřadíme seznam úkolů podle dueDate (od nejstaršího k nejnovějšímu)
    _allTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    notifyListeners();
  }

  Future<void> getTasksBySubjectId(int subjectId) async {
    _tasksBySubject = await _taskRepository.getTasksBySubjectId(subjectId);
    // Seřadíme úkoly
    _tasksBySubject.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners(); // Informuje widgety o změně seznamu
  }

  Future<void> addTask(BuildContext context, TasksCompanion companion) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Zavoláme metodu repository
      final Task insertedTask = await _taskRepository.addNewTask(companion);

      // 2. Obnovíme seznamy úkolů
      if (companion.subjectId.present) {
        await getTasksBySubjectId(companion.subjectId.value);
      }
      await getAllTasks(); // Aktualizuje _allTasks

      // 3. Přímo použijeme vrácený Task objekt pro plánování notifikací
      await _scheduleNotificationsForTask(context, insertedTask);

      log('Task ${insertedTask.id} added and notifications scheduled.');
    } catch (e) {
      log('Error adding task in provider: $e');
      // Zobrazíme chybu uživateli pomocí uloženého messengeru
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Chyba při přidávání úkolu: $e')),
      );
    }
  }

  Future<void> deleteTask(int taskId) async {
    // Najdeme úkol a jeho index v seznamu PŘED smazáním
    final index = _tasksBySubject.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      // Uchováme si kopii úkolu pro případné vrácení při chybě
      final taskToDelete = _tasksBySubject[index];
      // 1. Okamžitě odstraníme úkol z lokálního seznamu
      _tasksBySubject.removeAt(index);

      // 2. Okamžitě notifikujeme listenery, aby se UI překreslilo BEZ smazaného úkolu
      notifyListeners();

      try {
        // 3. Teprve teď provedeme asynchronní smazání z databáze/repository
        await _taskRepository.deleteTask(taskId);
        // Zrušení naplánovaných notifikací
        await AwesomeNotificationService.cancelTaskNotifications(taskId);
        getAllTasks();
      } catch (error) {
        log('Error deleting task $taskId from repository: $error');
        _tasksBySubject.insert(index, taskToDelete);
        notifyListeners();
      }
    } else {
      log('Task $taskId not found in the local list for deletion.');
      // smazat task i přes to že nebyl v listu?
      // await _taskRepository.deleteTask(taskId);
    }
  }

  Future<void> updateTaskCompletion(
    BuildContext context,
    int taskId,
    bool isCompleted,
  ) async {
    final index = _tasksBySubject.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final originalTask = _tasksBySubject[index];

      // 1. Vytvoříme "nový" stav úkolu (zde nahradíme objekt v seznamu)
      final updatedTask = Task(
        id: originalTask.id,
        subjectId: originalTask.subjectId,
        title: originalTask.title,
        dueDate: originalTask.dueDate,
        isCompleted: isCompleted,
      );
      // Nahradíme původní úkol v seznamu novým
      _tasksBySubject[index] = updatedTask;

      // 2. notifikujeme listenery
      notifyListeners();

      try {
        // 3. Provedeme update v databázi
        await _taskRepository.updateTaskCompletion(taskId, isCompleted);
        log('Task $taskId completion updated successfully in repository.');

        if (isCompleted) {
          // Pokud je úkol označen jako splněný, zrušíme jeho notifikace
          await AwesomeNotificationService.cancelTaskNotifications(taskId);
        } else {
          // Pokud je úkol označen zpět jako nesplněný, přeplánujeme notifikace
          // (Použijeme updatedTask, který má isCompleted=false)
          await _scheduleNotificationsForTask(context, updatedTask);
        }
      } catch (error) {
        log('Error updating task $taskId completion in repository: $error');
        // 4. Zpracování chyby: Vrátíme původní stav úkolu
        _tasksBySubject[index] = originalTask;
        notifyListeners();
      }
    }
  }

  //  Pomocná metoda pro plánování
  Future<void> _scheduleNotificationsForTask(
    BuildContext context,
    Task task,
  ) async {
    final settings = context.read<SettingsProvider>();
    final now = DateTime.now();

    log("Awesome Scheduling for Task ID: ${task.id}, Due: ${task.dueDate}");

    await AwesomeNotificationService.cancelTaskNotifications(task.id);

    const bool usePrecise =
        false; // False - nepřesné notifikace, problém s oprávněnými při true

    if (settings.notifyOneHourBefore) {
      final scheduleTime = task.dueDate.subtract(const Duration(hours: 1));
      if (scheduleTime.isAfter(now)) {
        await AwesomeNotificationService.scheduleNotification(
          id: AwesomeNotificationService.generateNotificationId(task.id, 1),
          title: 'Připomenutí: ${task.title}',
          body:
              'Termín je za hodinu (${DateFormat('HH:mm').format(task.dueDate)}).',
          scheduledDateTime: scheduleTime,
          payload: {
            'taskId': task.id.toString(),
            'interval': '1h',
          }, // Příklad payloadu
          usePreciseAlarm: usePrecise,
        );
      } else {
        log("[1h] Skipped (past)");
      }
    }
    if (settings.notifyOneDayBefore) {
      final scheduleTime = task.dueDate.subtract(const Duration(days: 1));
      if (scheduleTime.isAfter(now)) {
        await AwesomeNotificationService.scheduleNotification(
          id: AwesomeNotificationService.generateNotificationId(task.id, 2),
          title: 'Připomenutí: ${task.title}',
          body:
              'Termín je zítra (${DateFormat('d.M. HH:mm').format(task.dueDate)}).',
          scheduledDateTime: scheduleTime,
          payload: {'taskId': task.id.toString(), 'interval': '1d'},
          usePreciseAlarm: usePrecise,
        );
      } else {
        log("[1d] Skipped (past)");
      }
    }
    if (settings.notifyOneWeekBefore) {
      final scheduleTime = task.dueDate.subtract(const Duration(days: 7));
      if (scheduleTime.isAfter(now)) {
        await AwesomeNotificationService.scheduleNotification(
          id: AwesomeNotificationService.generateNotificationId(task.id, 3),
          title: 'Připomenutí: ${task.title}',
          body:
              'Termín je za týden (${DateFormat('d.M.yyyy HH:mm').format(task.dueDate)}).',
          scheduledDateTime: scheduleTime,
          payload: {'taskId': task.id.toString(), 'interval': '1w'},
          usePreciseAlarm: usePrecise,
        );
      } else {
        log("[1w] Skipped (past)");
      }
    }
    log("Awesome Scheduling finished for Task ID: ${task.id}");
  }

  void clearTasksBySubject() {
    _tasksBySubject = [];
    notifyListeners();
  }
}
