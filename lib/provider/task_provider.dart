// task_provider.dart

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
    _tasksBySubject = await _taskRepository.getTasksBySubjectId(subjectId);
    notifyListeners();
  }

  Future<void> addTask(TasksCompanion task) async {
    await _taskRepository.addNewTask(task);
    await getAllTasks(); // obnovíme seznam po přidání
  }
}
