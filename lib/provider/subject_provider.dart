import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/repository/subject_repository.dart';

class SubjectProvider extends ChangeNotifier {
  SubjectRepository _subjectRepository = SubjectRepository();
  List<Subject> _allSubjects = [];
  List<Subject> get allSubjects => _allSubjects;

  getAllSubjects() async {
    _allSubjects = await _subjectRepository.getAllSubjects();
    notifyListeners();
  }
}
