import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/locator.dart';
import 'package:schoolcalendar/presentation/screens/subjects_screen.dart';
import 'package:schoolcalendar/presentation/theme/theme.dart';
import 'package:schoolcalendar/provider/settings_provider.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:schoolcalendar/provider/theme_provider.dart';
import 'package:schoolcalendar/service/notification_service.dart';

void main() async {
  // Zajistí inicializaci Flutteru před voláním platformních věcí
  WidgetsFlutterBinding.ensureInitialized();

  // ---- INICIALIZACE LOKALIZACE ----
  // Zavolejte jednou zde pro češtinu
  await initializeDateFormatting('cs_CZ', null);
  // ---------------------------------
  // ---- Inicializace Notifikační Služby ----
  await AwesomeNotificationService.initialize();
  // Počkeáme chvilku a pak zkusíme požádat o oprávnění
  // Můžete toto přesunout na vhodnější místo (např. po prvním spuštění, v nastavení)
  Future.delayed(const Duration(seconds: 3), () {
    AwesomeNotificationService.requestPermissions();
  });
  // ---------------------------------------
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubjectProvider>(
          create: (_) => SubjectProvider(),
        ),
        ChangeNotifierProvider<TaskProvider>(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EduPlanner',
          //theme: buildDarkBlueTheme(),
          themeMode: themeProvider.themeMode,
          theme: FlexThemeData.light(scheme: FlexScheme.indigoM3),
          darkTheme: FlexThemeData.dark(scheme: FlexScheme.indigoM3),
          home: const SubjectsScreen(),
        );
      },
    );
  }
}
