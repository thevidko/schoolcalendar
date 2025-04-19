import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/db/database.dart';
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
  int? _subjectIdInt;

  @override
  void initState() {
    super.initState();
    _subjectFuture = _loadSubjectAndTasks();
  }

  Future<void> _loadSubjectAndTasks() async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // 1. Pokusíme se převést String ID na int
    _subjectIdInt = int.tryParse(widget.subjectIdString);

    // 2. Zkontrolujeme, zda převod proběhl úspěšně
    if (_subjectIdInt == null) {
      log(
        "Error: Could not parse subject ID '${widget.subjectIdString}' to an integer.",
      );
      subjectProvider.clearSelectedSubject();
      taskProvider.clearTasksBySubject();

      return;
    }
    try {
      // 3. Načti předmět
      await subjectProvider.getSubjectById(_subjectIdInt!);

      // 4. Zkontroluj, zda se předmět načetl
      final subject = subjectProvider.selectedSubject;
      if (subject != null) {
        // 5. Načti úkoly
        await taskProvider.getTasksBySubjectId(_subjectIdInt!);
      } else {
        // Předmět se nenašel, i když ID bylo validní int
        taskProvider.clearTasksBySubject();
      }
    } catch (error) {
      log("Error loading subject or tasks: $error");
      subjectProvider.clearSelectedSubject();
      taskProvider.clearTasksBySubject();
    }
  }

  /// Metoda pro smazání předmětu
  void _confirmDelete(BuildContext context, Subject subjectToDelete) {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

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
          if (_subjectIdInt != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTaskScreen(subjectId: _subjectIdInt!),
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
            builder: (context, subjectData, child) {
              final subject = subjectData.selectedSubject;
              if (subject != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context, subject);
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
      body: FutureBuilder(
        future: _subjectFuture,
        builder: (context, snapshot) {
          // --- Stav načítání ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Chyba při načítání ---
          if (snapshot.hasError) {
            log("Error in FutureBuilder: ${snapshot.error}");
            return Center(
              child: Text("Chyba při načítání dat: ${snapshot.error}"),
            );
          }

          // --- Načteno ---
          return Consumer2<SubjectProvider, TaskProvider>(
            builder: (context, subjectData, taskData, child) {
              final subject = subjectData.selectedSubject;
              final subjectTasks = taskData.tasksBySubject;

              // Pokud se předmět nenačetl
              if (subject == null) {
                return const Center(child: Text("Předmět nenalezen"));
              }

              // Rozdělení úkolů na splněné a nesplněné
              final uncompletedTasks =
                  subjectTasks.where((task) => !task.isCompleted).toList();
              final completedTasks =
                  subjectTasks.where((task) => task.isCompleted).toList();

              final headlineSmallStyle =
                  Theme.of(context).textTheme.headlineSmall;
              final headlineLarge = Theme.of(context).textTheme.headlineLarge;
              // --- Vykreslení UI ---
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Karta s detailem předmětu
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).primaryColor),
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
                            style: headlineLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subject.code,
                            textAlign: TextAlign.center,
                            style: headlineSmallStyle?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 2. Sekce nesplněných úkolů
                  if (uncompletedTasks.isNotEmpty) ...[
                    Text(
                      "Nesplněné termíny (${uncompletedTasks.length})",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Column(
                    children:
                        uncompletedTasks
                            .map(
                              (task) => TaskItemDetail(
                                key: ValueKey(task.id),
                                task: task,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Sekce splněných úkolů
                  if (completedTasks.isNotEmpty) ...[
                    Text(
                      "Splněné termíny (${completedTasks.length})",
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                  ],

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
                  if (subjectTasks.isEmpty)
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
