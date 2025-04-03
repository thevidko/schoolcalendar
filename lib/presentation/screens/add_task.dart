import 'package:drift/drift.dart' as db;
import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/repository/task_repository.dart';
import 'package:schoolcalendar/repository/subject_repository.dart';

class AddTaskScreen extends StatefulWidget {
  final int? subjectId;
  const AddTaskScreen({super.key, this.subjectId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  int? _selectedSubjectId;
  DateTime? _dueDate;
  final bool _isCompleted = false;
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.subjectId;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await SubjectRepository().getAllSubjects();
    setState(() {
      _subjects = subjects;
    });
  }

  Future<void> _pickDueDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Přidat nový termín")),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Kód nemůže být prázdný";
                  }
                  return null;
                },
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Název termínu",
                  hintText: "Zápočet",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: InputDecoration(
                  labelText: "Předmět",
                  border: OutlineInputBorder(),
                ),
                items:
                    _subjects.map((subject) {
                      return DropdownMenuItem<int>(
                        value: subject.id,
                        child: Text(subject.name),
                      );
                    }).toList(),
                onChanged:
                    widget.subjectId == null
                        ? (value) {
                          setState(() {
                            _selectedSubjectId = value;
                          });
                        }
                        : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickDueDate,
                      child: Text(
                        _dueDate == null
                            ? "Vybrat datum"
                            : "Datum: ${_dueDate!.toLocal()}", //TODO České datum
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      _selectedSubjectId != null &&
                      _dueDate != null) {
                    TasksCompanion newTask = TasksCompanion(
                      subjectId: db.Value(_selectedSubjectId!),
                      title: db.Value(_titleController.text),
                      dueDate: db.Value(_dueDate!),
                      isCompleted: db.Value(_isCompleted),
                    );
                    await TaskRepository().addNewTask(newTask);
                    Navigator.pop(context);
                  }
                },
                child: Text("Přidat"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
