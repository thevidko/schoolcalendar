// task_provider.dart

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/repository/task_repository.dart';

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

  Future<void> addTask(TasksCompanion task) async {
    await _taskRepository.addNewTask(task);
    await getAllTasks(); // obnovíme seznam po přidání
  }

  Future<void> deleteTask(int taskId) async {
    // Najdeme úkol a jeho index v seznamu PŘED smazáním
    final index = _tasksBySubject.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      // Uchováme si kopii úkolu pro případné vrácení při chybě
      final taskToDelete = _tasksBySubject[index];

      // --- OPTIMISTICKÝ UPDATE ---
      // 1. Okamžitě odstraníme úkol z lokálního seznamu
      _tasksBySubject.removeAt(index);

      // 2. Okamžitě notifikujeme listenery, aby se UI překreslilo BEZ smazaného úkolu
      notifyListeners();
      // --- Konec optimistického updatu ---

      try {
        // 3. Teprve teď provedeme asynchronní smazání z databáze/repository
        await _taskRepository.deleteTask(taskId);
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

  Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
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
      } catch (error) {
        print('Error updating task $taskId completion in repository: $error');
        // 4. Zpracování chyby: Vrátíme původní stav úkolu
        _tasksBySubject[index] = originalTask; // Vrátíme původní objekt
        notifyListeners(); // Notifikujeme UI o vrácení
        // throw error;
      }
    }
  }

  void clearTasksBySubject() {
    _tasksBySubject = [];
    notifyListeners();
  }
}
