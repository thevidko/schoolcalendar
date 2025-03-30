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
}
