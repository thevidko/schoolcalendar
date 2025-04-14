import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/locator.dart';
import 'package:schoolcalendar/presentation/screens/subjects_screen.dart';
import 'package:schoolcalendar/presentation/theme/theme.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubjectProvider>(
          create: (_) => SubjectProvider(),
        ),
        ChangeNotifierProvider<TaskProvider>(create: (_) => TaskProvider()),
      ],
      child: SchoolCalendarApp(),
    ),
  );
  setUp();
}

class SchoolCalendarApp extends StatelessWidget {
  const SchoolCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Školní kalendář',
      theme: buildDarkBlueTheme(),
      home: const SubjectsScreen(),
    );
  }
}
