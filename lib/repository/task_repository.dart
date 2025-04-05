import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/locator.dart';

class TaskRepository {
  // Inject database class
  AppDatabase db = locator.get<AppDatabase>();

  Future<List<Task>> allTasks() async {
    try {
      return await db.select(db.tasks).get();
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Future<List<Task>> getTasksBySubjectId(int subjectId) async {
    try {
      return await (db.select(db.tasks)
        ..where((tbl) => tbl.subjectId.equals(subjectId))).get();
    } catch (e) {
      log('Failed to load tasks by subject ID: $e');
      return [];
    }
  }

  Future<void> addNewTask(TasksCompanion task) async {
    try {
      await db.into(db.tasks).insert(task);
      log('Subject added successfully: ${task.title}');
    } catch (e) {
      log('Failed to add task: ${e.toString()}');
    }
  }

  Future<int> updateTask(int id, TasksCompanion entry) {
    return (db.update(db.tasks)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> updateTaskCompletion(int taskId, bool isCompleted) {
    final companion = TasksCompanion(isCompleted: Value(isCompleted));
    // Volání metody z databázové třídy/DAO
    return updateTask(taskId, companion);
  }

  // Metoda pro smazání tasku
  Future<int> deleteTask(int id) {
    return (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
  }
}
