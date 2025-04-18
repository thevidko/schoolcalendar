import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/api/stag_api_service.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/data/models/stag_subject_model.dart';
import 'package:schoolcalendar/presentation/screens/add_subject.dart';
import 'package:schoolcalendar/presentation/screens/settings.dart';
import 'package:schoolcalendar/presentation/screens/stag_login.dart';
import 'package:schoolcalendar/presentation/widgets/subject_card.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';
import 'package:schoolcalendar/presentation/widgets/subject_import_dialog.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _stagApiService = StagApiService(); // Instance API služby
  bool _isImporting = false; // zobrazení indikátoru načítání

  // Metoda pro spuštění celého importního procesu
  Future<void> _startStagImport() async {
    setState(() => _isImporting = true); // Zobrazit indikátor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Načítám předměty ze STAG...')),
    );

    try {
      // 1. Získat přihlašovací údaje
      final ticket = await _secureStorage.read(key: 'stag_user_ticket');
      final identifier = await _secureStorage.read(
        key: 'stag_student_identifier',
      );

      if (ticket == null || identifier == null) {
        throw Exception('Přihlašovací údaje STAG nebyly nalezeny.');
      }

      // 2. Načíst předměty z API
      final List<StagSubject> stagSubjects = await _stagApiService
          .fetchStudentSubjects(ticket, identifier);

      // 3. Zobrazit dialog pro výběr (pokud jsou nějaké předměty)
      if (!mounted) return; //Kontrola, zda je widget stále ve stromu
      if (stagSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ze STAGu nebyly načteny žádné předměty.'),
          ),
        );
        setState(() => _isImporting = false);
        return;
      }

      final List<StagSubject>? selectedSubjects = await showSubjectImportDialog(
        context,
        stagSubjects,
      );

      // 4. Zpracovat vybrané předměty
      if (selectedSubjects != null && selectedSubjects.isNotEmpty) {
        if (!mounted) return;
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );
        int importCount = 0;
        int errorCount = 0;

        setState(
          () => _isImporting = true,
        ); // Znovu zobrazit indikátor pro ukládání
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importuji ${selectedSubjects.length} předmětů...'),
          ),
        );

        // Projdeme vybrané předměty a přidáme je do DB
        for (final subject in selectedSubjects) {
          if (subject.zkratka != null && subject.nazev != null) {
            final companion = SubjectsCompanion.insert(
              name: subject.nazev!,
              code: subject.zkratka!,
            );
            try {
              await subjectProvider.addSubject(companion);
              importCount++;
            } catch (e) {
              print("Error importing subject ${subject.zkratka}: $e");
              errorCount++;
              // řešení duplicit?
            }
          }
        }

        // Zobrazit výsledek importu
        String resultMessage =
            'Import dokončen. Bylo importováno $importCount předmětů.';
        if (errorCount > 0) {
          resultMessage += ' Při importu $errorCount předmětů nastala chyba.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultMessage),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (selectedSubjects != null && selectedSubjects.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nebyly vybrány žádné předměty k importu.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import předmětů byl zrušen.')),
          );
        }
      }
    } catch (e) {
      print("STAG Import Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při importu ze STAG: $e')),
        );
      }
    } finally {
      // Ukončení indikatoru načítaní
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d. MMMM yyyy', 'cs_CZ');
    return formatter.format(now);
  }

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
      appBar: AppBar(
        title: Text("EduPlanner"),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import_stag') {
                // Navigace na login obrazovku
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StagLoginScreen()),
                ).then((loginResult) {
                  if (loginResult == true) {
                    _startStagImport();
                  } else if (loginResult == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Přihlášení do STAG bylo zrušeno nebo selhalo.',
                        ),
                      ),
                    );
                  }
                });
              } else if (value == 'settings') {
                print('Vybrána položka Nastavení'); // Pro kontrolu v konzoli
                // Zde přidejte navigaci na vaši obrazovku nastavení
                // Předpokládáme, že máte obrazovku s názvem SettingsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ), // Vytvořte si SettingsScreen
                );
              }
              // Nastavení  ?
              // else if (value == 'settings') { ... }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'import_stag',
                    child: Text('Import ze STAG'),
                  ),
                  const PopupMenuItem(
                    value: 'settings', // Unikátní hodnota pro tuto položku
                    child: Text('Nastavení'), // Zobrazený text
                  ),
                ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Consumer2<SubjectProvider, TaskProvider>(
        builder: (_, subjectProvider, taskProvider, __) {
          final subjects = subjectProvider.allSubjects;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween, // Zarovná děti na opačné konce
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .center, // Vertikální zarovnání na střed
                  children: [
                    // Levý text: "Předměty"
                    Text(
                      'Předměty',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    // Pravý text: Datum
                    Text(
                      _getFormattedDate(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              Expanded(
                child:
                    subjects.isEmpty
                        ? const Center(child: Text("Žádné předměty"))
                        : ListView.builder(
                          itemCount: subjects.length,
                          itemBuilder: (_, index) {
                            final subject = subjects[index];
                            // Získání úkolů pro předmět
                            final tasks =
                                taskProvider.allTasks
                                    .where(
                                      (task) => task.subjectId == subject.id,
                                    )
                                    .toList();

                            return SubjectCard(subject: subject, tasks: tasks);
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
