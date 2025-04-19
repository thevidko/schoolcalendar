import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/locator.dart';

class TaskRepository {
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

  Future<Task> addNewTask(TasksCompanion companion) async {
    try {
      // 1. Vložíme companion objekt a získáme ID nově vloženého řádku
      // Metoda insert vrací Future<int>, což je ID (obvykle rowid).
      final int newId = await db.into(db.tasks).insert(companion);
      log('Task companion inserted, received ID: $newId');

      // 2. Okamžitě po vložení načteme celý objekt Task pomocí získaného ID
      // Použijeme getSingle(), protože očekáváme právě jeden záznam s tímto ID.
      final newTask =
          await (db.select(db.tasks)..where(
            (tbl) => tbl.id.equals(newId),
          )).getSingle(); // Získáme konkrétní Task objekt

      log(
        'Task added and fetched successfully: ID $newId, Title: ${newTask.title}',
      );
      return newTask;
    } catch (e) {
      log('Failed to add task or fetch it back: ${e.toString()}');
      throw Exception('Nepodařilo se přidat úkol: $e');
    }
  }

  Future<int> updateTask(int id, TasksCompanion entry) {
    return (db.update(db.tasks)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> updateTaskCompletion(int taskId, bool isCompleted) {
    final companion = TasksCompanion(isCompleted: Value(isCompleted));
    return updateTask(taskId, companion);
  }

  Future<int> deleteTask(int id) {
    return (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
  }
}
