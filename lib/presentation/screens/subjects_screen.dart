import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';
import 'package:schoolcalendar/presentation/screens/add_subject.dart';
import 'package:schoolcalendar/presentation/screens/settings.dart';
import 'package:schoolcalendar/presentation/screens/stag_login.dart';
import 'package:schoolcalendar/presentation/widgets/subject_card.dart';
import 'package:schoolcalendar/service/stag_import_service.dart';
import 'package:schoolcalendar/utils/date_formatter.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _stagImportService = StagImportService();

  // Stav pro zobrazení indikátoru načítání během importu
  bool _isImporting = false;

  void _navigateToAddSubject() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddSubject()));
  }

  /// Spustí proces přihlášení do STAGu a následný import předmětů.
  Future<void> _triggerStagImport() async {
    // Navigace na login STAG, poté kontrola úspěchu
    final loginSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const StagLoginScreen()),
    );

    if (loginSuccess == true) {
      if (!mounted) return;

      await _stagImportService.startImport(
        context: context,
        onImportStart: () {
          // zobrazíme indikátor
          if (mounted) setState(() => _isImporting = true);
        },
        onImportFinish: (success, message) {
          //zobrazíme výsledek a skryjeme indikátor
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 4),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
            setState(() => _isImporting = false); // Skrytí indikátoru
          }
        },
      );
    } else {
      // Přihlášení selhalo nebo bylo zrušeno uživatelem
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Přihlášení do STAG bylo zrušeno nebo selhalo. Import nebyl spuštěn.',
            ),
          ),
        );
        // Ujistíme se, že indikátor je skrytý, i kdyby náhodou zůstal viset
        if (_isImporting) {
          setState(() => _isImporting = false);
        }
      }
    }
  }

  /// Zpracuje výběr položky z menu v AppBaru.
  void _handleMenuSelection(String value) {
    if (value == 'import_stag') {
      _triggerStagImport();
    } else if (value == 'settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  // --- Build metoda ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Floating Action Button ---
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSubject, // Volá metodu pro navigaci
        child: const Icon(Icons.add),
      ),

      // --- AppBar ---
      appBar: AppBar(
        title: const Text("EduPlanner"),
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
          // Tlačítko menu (tři tečky)
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'import_stag',
                    child: Text('Import ze STAG'),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Nastavení'),
                  ),
                ],
            icon: const Icon(Icons.more_vert), // Ikona menu
          ),
        ],
      ),

      // --- Body ---
      body: Consumer2<SubjectProvider, TaskProvider>(
        builder: (_, subjectProvider, taskProvider, __) {
          // Získáme seznam všech předmětů z provideru
          final subjects = subjectProvider.allSubjects;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hlavička s názvem sekce a aktuálním datem
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Předměty',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      DateFormatter.formatCzechDate(DateTime.now()),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Oddělovač
              const Divider(height: 1, thickness: 0.5),

              // Seznam předmětů
              Expanded(
                child:
                    subjects.isEmpty
                        ? const Center(
                          child: Text(
                            "Zatím nemáte žádné předměty.\n Můžete je přidat ručně (+) nebo importovat ze STAGu (⋮).",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: subjects.length,
                          itemBuilder: (_, index) {
                            final subject = subjects[index];
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
