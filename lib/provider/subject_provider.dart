import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/repository/subject_repository.dart';

class SubjectProvider extends ChangeNotifier {
  SubjectProvider() {
    getAllSubjects();
  }

  SubjectRepository _subjectRepository = SubjectRepository();
  List<Subject> _allSubjects = [];
  Subject? _selectedSubject;

  List<Subject> get allSubjects => _allSubjects;
  Subject? get selectedSubject => _selectedSubject;

  getAllSubjects() async {
    _allSubjects = await _subjectRepository.getAllSubjects();
    notifyListeners();
  }

  Future<void> getSubjectById(int id) async {
    _selectedSubject = await _subjectRepository.getSubjectById(id);
    notifyListeners();
  }

  addSubject(SubjectsCompanion sc) async {
    await _subjectRepository.addNewSubject(sc);
    await getAllSubjects();
    notifyListeners();
  }

  deleteSubject(int id) async {
    await _subjectRepository.deleteSubject(id);
    getAllSubjects();
  }

  void clearSelectedSubject() {
    _selectedSubject = null;
    notifyListeners();
  }

  Future<void> deleteAllSubjects() async {
    final deletedCount = await _subjectRepository.deleteAllSubjects();
    print('$deletedCount subjects deleted from DB.');
    // Vymaže lokální data v provideru
    _allSubjects = [];
    _selectedSubject = null;
    notifyListeners();
  }
}
