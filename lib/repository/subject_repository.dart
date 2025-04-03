import 'dart:developer';

import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/locator.dart';

class SubjectRepository {
  AppDatabase db = locator.get<AppDatabase>();

  Future<List<Subject>> getAllSubjects() async {
    try {
      return await db.select(db.subjects).get();
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Future<Subject?> getSubjectById(int id) async {
    try {
      return await (db.select(db.subjects)
        ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> addNewSubject(SubjectsCompanion subject) async {
    try {
      await db.into(db.subjects).insert(subject);
      log('Subject added successfully: ${subject.name}');
    } catch (e) {
      log('Failed to add subject: ${e.toString()}');
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await (db.delete(db.subjects)..where((tbl) => tbl.id.equals(id))).go();
      log('Subject deleted successfully: ID $id');
    } catch (e) {
      log('Failed to delete subject: ${e.toString()}');
    }
  }
}
