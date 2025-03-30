import 'package:flutter/material.dart';
import 'package:schoolcalendar/locator.dart';
import 'data/models/subject.dart';
import 'data/models/task.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const SchoolCalendarApp());
  setUp();
}

class SchoolCalendarApp extends StatelessWidget {
  const SchoolCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Školní kalendář',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
