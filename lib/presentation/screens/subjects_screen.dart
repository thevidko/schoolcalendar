import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/presentation/screens/add_subject.dart';
import 'package:schoolcalendar/presentation/widgets/subject_card.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';

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
      body: Consumer<SubjectProvider>(
        builder: (_, subjectProvider, __) {
          if (subjectProvider.allSubjects.isEmpty) {
            return Center(child: Text("Žádné předměty"));
          }
          return ListView.builder(
            itemCount: subjectProvider.allSubjects.length,
            itemBuilder: (_, index) {
              return SubjectCard(
                subject: subjectProvider.allSubjects[index],
                tasks: [],
              );
            },
          );
        },
      ),
    );
  }
}
