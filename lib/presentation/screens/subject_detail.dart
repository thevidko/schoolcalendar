// subject_detail_screen.dart (nebo jak se jmenuje váš soubor)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/db/database.dart'; // Import Task
import 'package:schoolcalendar/presentation/screens/add_task.dart';
import 'package:schoolcalendar/presentation/widgets/task_item_detail.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectIdString;

  const SubjectDetailScreen({Key? key, required this.subjectIdString})
    : super(key: key);

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  late Future<void> _subjectFuture;
  int? _subjectIdInt; // ID předmětu jako integer pro TaskProvider

  @override
  void initState() {
    super.initState();
    // Inicializujeme načtení předmětu jednou
    _subjectFuture = _loadSubjectAndTasks();
  }

  Future<void> _loadSubjectAndTasks() async {
    // Použijeme provider s listen: false pro jednorázové načtení v initState/future
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // 1. Pokusíme se převést String ID na int
    _subjectIdInt = int.tryParse(widget.subjectIdString);

    // 2. Zkontrolujeme, zda převod proběhl úspěšně
    if (_subjectIdInt == null) {
      print(
        "Error: Could not parse subject ID '${widget.subjectIdString}' to an integer.",
      );
      // Nastavíme chybový stav nebo vyčistíme data
      subjectProvider
          .clearSelectedSubject(); // Metoda pro vyčištění v SubjectProvider
      taskProvider.clearTasksBySubject();

      return; // Ukončíme načítání, pokud ID není validní int
    }

    print("Parsed Subject ID (int): $_subjectIdInt"); // Debug print

    try {
      // 3. Načti předmět pomocí INT ID
      await subjectProvider.getSubjectById(
        _subjectIdInt!,
      ); // Nyní předáváme int

      // 4. Zkontroluj, zda se předmět načetl
      final subject = subjectProvider.selectedSubject;
      if (subject != null) {
        print('Subject loaded: ${subject.name}'); // Debug print
        // 5. Načti úkoly pomocí INT ID (už ho máme v _subjectIdInt)
        await taskProvider.getTasksBySubjectId(_subjectIdInt!);
      } else {
        print("Error: Subject with ID $_subjectIdInt not found after loading.");
        // Předmět se nenašel, i když ID bylo validní int
        taskProvider.clearTasksBySubject();
      }
    } catch (error) {
      print("Error loading subject or tasks: $error");
      // Zpracování obecné chyby při načítání
      subjectProvider.clearSelectedSubject();
      taskProvider.clearTasksBySubject();
    }
  }

  // Metoda pro smazání předmětu (přesunuta sem z build metody)
  void _confirmDelete(BuildContext context, Subject subjectToDelete) {
    // Získání providerů s listen: false pro akce
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(
      context,
    ); // Uložení navigatoru před async operací

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Smazat předmět?'),
            content: Text(
              'Opravdu si přejete smazat předmět "${subjectToDelete.name}" a všechny jeho úkoly? Tato akce je nevratná.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Zrušit'),
                onPressed: () => Navigator.of(ctx).pop(), // Zavřít dialog
              ),
              TextButton(
                child: Text('Smazat', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Zavřít dialog hned
                  try {
                    await subjectProvider.deleteSubject(subjectToDelete.id);

                    navigator.pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Předmět "${subjectToDelete.name}" smazán.',
                        ),
                      ),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chyba při mazání předmětu: $error'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //AddTaskScreen potřebuje subjectId (int)
          if (_subjectIdInt != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AddTaskScreen(
                      subjectId: _subjectIdInt!,
                    ), // Předáme INT ID
              ),
            ).then((_) {
              // Po návratu z AddTaskScreen znovu načteme úkoly
              if (_subjectIdInt != null) {
                Provider.of<TaskProvider>(
                  context,
                  listen: false,
                ).getTasksBySubjectId(_subjectIdInt!);
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Nelze přidat termín, ID předmětu není dostupné.',
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Přidat termín',
      ),
      appBar: AppBar(
        title: const Text("Detail předmětu"),
        // Actions se zobrazí jen pokud máme načtený předmět
        actions: [
          Consumer<SubjectProvider>(
            // Použijeme Consumer pro přístup k subject
            builder: (context, subjectData, child) {
              final subject = subjectData.selectedSubject;
              if (subject != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(
                        context,
                        subject,
                      ); // Předáme načtený subjekt
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Smazat předmět',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                );
              } else {
                return const SizedBox.shrink(); // Nezobrazovat nic, pokud předmět není načten
              }
            },
          ),
        ],
      ),
      //FutureBuilder pro počáteční načtení předmětu a úkolů
      body: FutureBuilder(
        future: _subjectFuture, // Použijeme future inicializované v initState
        builder: (context, snapshot) {
          // --- Stav načítání ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Chyba při načítání ---
          if (snapshot.hasError) {
            print("Error in FutureBuilder: ${snapshot.error}"); // Debug print
            return Center(
              child: Text("Chyba při načítání dat: ${snapshot.error}"),
            );
          }

          // --- Načteno (nebo chyba po načtení) ---
          return Consumer2<SubjectProvider, TaskProvider>(
            builder: (context, subjectData, taskData, child) {
              final subject = subjectData.selectedSubject;
              final subjectTasks = taskData.tasksBySubject;

              // Pokud se předmět nenačetl (kontrola i po Future)
              if (subject == null) {
                return const Center(child: Text("Předmět nenalezen"));
              }

              // Rozdělení úkolů na splněné a nesplněné
              final uncompletedTasks =
                  subjectTasks.where((task) => !task.isCompleted).toList();
              final completedTasks =
                  subjectTasks.where((task) => task.isCompleted).toList();

              // --- Vykreslení UI ---
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Karta s detailem předmětu
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            subject.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subject.code,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Větší mezera
                  // 2. Sekce nesplněných úkolů
                  if (uncompletedTasks.isNotEmpty) ...[
                    Text(
                      "Nesplněné termíny (${uncompletedTasks.length})",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 2b. Column pro nesplněné úkoly VYKRESLÍME VŽDY,
                  //     ale její obsah bude generován jen pokud seznam není prázdný.
                  //     Tím zajistíme, že Column existuje, i když se seznam vyprázdní.
                  Column(
                    children:
                        uncompletedTasks // Podmíněně mapujeme obsah
                            .map(
                              (task) => TaskItemDetail(
                                key: ValueKey(task.id), // Klíč je zde důležitý
                                task: task,
                              ),
                            )
                            .toList(), // Pokud je uncompletedTasks prázdný, výsledkem je prázdný List<Widget>
                  ),

                  // 2c. Mezera mezi sekcemi (můžeme ji nechat fixní nebo podmíněnou)
                  //     Nechme ji zde pro konzistentní vzhled.
                  const SizedBox(height: 24),

                  // --- KONEC ZMĚNY V SEKCI NESPLNĚNÝCH ÚKOLŮ ---

                  // 3. Sekce splněných úkolů (můžeme použít stejný princip)

                  // 3a. Nadpis jen pokud jsou splněné úkoly
                  if (completedTasks.isNotEmpty) ...[
                    Text(
                      "Splněné termíny (${completedTasks.length})",
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 3b. Column pro splněné úkoly vykreslíme vždy
                  Column(
                    children:
                        completedTasks
                            .map(
                              (task) => TaskItemDetail(
                                key: ValueKey(task.id),
                                task: task,
                              ),
                            )
                            .toList(),
                  ),

                  // 4. Zpráva, pokud nejsou žádné úkoly celkem
                  if (subjectTasks
                      .isEmpty) // Můžeme použít subjectTasks, je to jednodušší
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text("Pro tento předmět nejsou žádné termíny."),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
