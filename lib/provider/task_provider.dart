// task_provider.dart

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/provider/settings_provider.dart';
import 'package:schoolcalendar/repository/task_repository.dart';
import 'package:schoolcalendar/service/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

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
    print('Fetching tasks for subject ID: $subjectId'); // Debug print
    _tasksBySubject = await _taskRepository.getTasksBySubjectId(subjectId);
    // Seřadíme úkoly i zde, například podle termínu
    _tasksBySubject.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    print('Tasks fetched: ${_tasksBySubject.length}'); // Debug print
    notifyListeners(); // Informuje widgety o změně seznamu
  }

  Future<void> addTask(BuildContext context, TasksCompanion companion) async {
    // Uložíme si ScaffoldMessenger pro případné zobrazení chyb
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Zavoláme metodu repository, která nyní vrací Future<Task>
      final Task insertedTask = await _taskRepository.addNewTask(companion);

      // 2. Obnovíme seznamy úkolů (po úspěšném vložení)
      if (companion.subjectId.present) {
        await getTasksBySubjectId(companion.subjectId.value);
      }
      await getAllTasks(); // Aktualizuje _allTasks

      // 3. Přímo použijeme vrácený Task objekt pro plánování notifikací
      //    Žádná záložní logika není potřeba.
      await _scheduleNotificationsForTask(context, insertedTask);

      log('Task ${insertedTask.id} added and notifications scheduled.');
    } catch (e) {
      log('Error adding task in provider: $e');
      // Zobrazíme chybu uživateli pomocí uloženého messengeru
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Chyba při přidávání úkolu: $e')),
      );
      // Můžete zvážit re-throw, pokud má UI reagovat dál
      // throw e;
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
      // --- Konec optimistického updatu ---

      try {
        // 3. Teprve teď provedeme asynchronní smazání z databáze/repository
        await _taskRepository.deleteTask(taskId);
        // --- Zrušení naplánovaných notifikací ---
        await AwesomeNotificationService.cancelTaskNotifications(taskId);
        getAllTasks();
        print('Task $taskId deleted successfully from repository.');
        // Není už potřeba volat getTasksBySubjectId, UI je aktuální
      } catch (error) {
        print('Error deleting task $taskId from repository: $error');
        // 4. Zpracování chyby: Pokud smazání selhalo, vrátíme úkol zpět do seznamu
        //    na původní pozici, aby byla zachována konzistence UI a dat
        _tasksBySubject.insert(index, taskToDelete);
        // Notifikujeme UI o vrácení úkolu
        notifyListeners();
        // Můžete zde uživateli zobrazit chybovou hlášku nebo error dále zpracovat
        // throw error; // Pokud chcete chybu propagovat dál
      }
    } else {
      print('Task $taskId not found in the local list for deletion.');
      // Zde můžete zvážit, zda se přesto pokusit smazat z DB, pokud by task nebyl v seznamu
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

      // --- OPTIMISTICKÝ UPDATE ---
      // 1. Vytvoříme "nový" stav úkolu (zde nahradíme objekt v seznamu)
      //    POZOR: Toto předpokládá, že Task je datová třída, kde můžeme vytvořit novou instanci.
      //    Pokud používáš drift, Task bude pravděpodobně immutable DataClass.
      final updatedTask = Task(
        id: originalTask.id,
        subjectId: originalTask.subjectId,
        title: originalTask.title,
        dueDate: originalTask.dueDate,
        isCompleted: isCompleted, // Změněná hodnota
      );
      // Nahradíme původní úkol v seznamu novým (aktualizovaným)
      _tasksBySubject[index] = updatedTask;

      // 2. Okamžitě notifikujeme listenery
      notifyListeners();
      // --- Konec optimistického updatu ---

      try {
        // 3. Provedeme asynchronní update v databázi
        await _taskRepository.updateTaskCompletion(taskId, isCompleted);
        print('Task $taskId completion updated successfully in repository.');

        // --- Zrušení nebo přeplánování notifikací ---
        if (isCompleted) {
          // Pokud je úkol označen jako splněný, zrušíme jeho notifikace
          await AwesomeNotificationService.cancelTaskNotifications(taskId);
        } else {
          // Pokud je úkol označen zpět jako nesplněný, přeplánujeme notifikace
          // (Použijeme updatedTask, který má isCompleted=false)
          await _scheduleNotificationsForTask(context, updatedTask);
        }
        // ------------------------------------------
      } catch (error) {
        print('Error updating task $taskId completion in repository: $error');
        // 4. Zpracování chyby: Vrátíme původní stav úkolu
        _tasksBySubject[index] = originalTask; // Vrátíme původní objekt
        notifyListeners(); // Notifikujeme UI o vrácení
        // throw error;
      }
    }
  }

  // --- Pomocná metoda pro plánování ---
  // BuildContext je potřeba pro přístup k SettingsProvider
  Future<void> _scheduleNotificationsForTask(
    BuildContext context,
    Task task,
  ) async {
    final settings = context.read<SettingsProvider>();
    final now = DateTime.now(); // Použijeme DateTime.now() pro isAfter check

    print("Awesome Scheduling for Task ID: ${task.id}, Due: ${task.dueDate}");

    await AwesomeNotificationService.cancelTaskNotifications(task.id);

    const bool usePrecise =
        false; // <-- ROZHODNUTÍ ZDE (false = bez speciálního oprávnění)

    if (settings.notifyOneHourBefore) {
      final scheduleTime = task.dueDate.subtract(const Duration(hours: 1));
      if (scheduleTime.isAfter(now)) {
        // Jednoduchá kontrola
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
        print("[1h] Skipped (past)");
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
        print("[1d] Skipped (past)");
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
        print("[1w] Skipped (past)");
      }
    }
    print("Awesome Scheduling finished for Task ID: ${task.id}");
  }

  // Nezapomeňte aktualizovat i volání cancel v deleteTask a updateTaskCompletion
  // na AwesomeNotificationService.cancelTaskNotifications(taskId);

  void clearTasksBySubject() {
    _tasksBySubject = [];
    notifyListeners();
  }
}
