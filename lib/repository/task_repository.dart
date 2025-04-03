import 'dart:developer';

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

  Future<void> addNewTask(TasksCompanion task) async {
    try {
      await db.into(db.tasks).insert(task);
      log('Subject added successfully: ${task.title}');
    } catch (e) {
      log('Failed to add task: ${e.toString()}');
    }
  }
}
