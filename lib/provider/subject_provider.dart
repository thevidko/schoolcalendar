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
}

extension SubjectProviderActions on SubjectProvider {
  Future<void> deleteSubject(dynamic subjectId, BuildContext context) async {
    // Zde implementujte logiku smazání předmětu v repository/DB
    // např. await _subjectRepository.deleteSubjectById(subjectId);
    print('Deleting subject with ID: $subjectId');
    await Future.delayed(Duration(seconds: 1)); // Simulace
    // Po smazání resetujte selectedSubject a notifikujte
    _selectedSubject = null;
    notifyListeners();
    // Návrat zpět není potřeba řešit zde, řeší se v UI po await
  }
}
