import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/presentation/screens/add_task.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';

class SubjectDetailScreen extends StatelessWidget {
  final int subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Smazat předmět"),
          content: Text("Opravdu chcete smazat tento předmět?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Zrušit"),
            ),
            TextButton(
              onPressed: () {
                Provider.of<SubjectProvider>(
                  context,
                  listen: false,
                ).deleteSubject(subjectId);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text("Smazat", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTaskScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text("Detail předmětu"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Smazat předmět',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: Provider.of<SubjectProvider>(
          context,
          listen: false,
        ).getSubjectById(subjectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subject = Provider.of<SubjectProvider>(context).selectedSubject;
          if (subject == null) {
            return const Center(child: Text("Předmět nenalezen"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  subject.code,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
