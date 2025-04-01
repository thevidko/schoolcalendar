import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/presentation/screens/add_subject.dart';
import 'package:schoolcalendar/repository/subject_repository.dart';

class SubjectProvider extends ChangeNotifier {
  SubjectProvider() {
    getAllSubjects();
  }

  SubjectRepository _subjectRepository = SubjectRepository();
  List<Subject> _allSubjects = [];
  List<Subject> get allSubjects => _allSubjects;

  getAllSubjects() async {
    _allSubjects = await _subjectRepository.getAllSubjects();
    notifyListeners();
  }

  addSubject(SubjectsCompanion sc) async {
    await _subjectRepository.addNewSubject(sc);
    await getAllSubjects();
    notifyListeners();
  }

  deleteSubject(int id) async {
    //await _subjectRepository.deleteSubject(id);
    getAllSubjects();
  }
}
