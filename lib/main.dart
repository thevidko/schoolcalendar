import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/locator.dart';
import 'package:schoolcalendar/presentation/screens/subjects_screen.dart';
import 'package:schoolcalendar/presentation/theme/theme.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

void main() async {
  // Zajistí inicializaci Flutteru před voláním platformních věcí
  WidgetsFlutterBinding.ensureInitialized();

  // ---- INICIALIZACE LOKALIZACE ----
  // Zavolejte jednou zde pro češtinu
  await initializeDateFormatting('cs_CZ', null);
  // ---------------------------------
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
      //theme: buildDarkBlueTheme(),
      theme: FlexThemeData.dark(scheme: FlexScheme.indigoM3),
      home: const SubjectsScreen(),
    );
  }
}
