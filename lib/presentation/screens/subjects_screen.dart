import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/presentation/screens/add_subject.dart';
import 'package:schoolcalendar/presentation/widgets/subject_card.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddSubject()),
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(title: Text("Předměty")),
      body: Consumer2<SubjectProvider, TaskProvider>(
        builder: (_, subjectProvider, taskProvider, __) {
          final subjects = subjectProvider.allSubjects;

          if (subjects.isEmpty) {
            return Center(child: Text("Žádné předměty"));
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (_, index) {
              final subject = subjects[index];
              final tasks =
                  taskProvider.allTasks
                      .where((task) => task.subjectId == subject.id)
                      .toList();

              return SubjectCard(subject: subject, tasks: tasks);
            },
          );
        },
      ),
    );
  }
}
