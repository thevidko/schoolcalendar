import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Opravdu smazat všechna data?'),
            content: const Text(
              'Tato akce je nevratná a smaže všechny vámi přidané předměty a termíny. Chcete pokračovat?',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Zrušit'),
                onPressed: () {
                  Navigator.of(ctx).pop(false); // Zavřít dialog a vrátit false
                },
              ),
              TextButton(
                child: const Text(
                  'Smazat vše',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(true); // Zavřít dialog a vrátit true
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAllData(BuildContext context) async {
    // providery pro provedení akce
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Mažu všechna data...')),
    );

    try {
      await subjectProvider.deleteAllSubjects();

      await taskProvider
          .getAllTasks(); // Znovu načte úkoly (měly by být prázdné)

      scaffoldMessenger.removeCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Všechna data byla úspěšně smazána.')),
      );

      // vratit uživatele na předchozí obrazovku
      Navigator.of(context).pop();
    } catch (error) {
      print("Error deleting all data: $error");
      scaffoldMessenger.removeCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Nepodařilo se smazat data: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
        ), // Padding shora/zdola pro celý seznam
        children: [
          // --- Sekce Tmavý režim (zatím jen UI) ---
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined), // Ikona pro téma
            title: const Text('Tmavý režim'),
            subtitle: const Text('Přepnout vzhled aplikace'), // Popisek
            trailing: Switch(
              value:
                  Theme.of(context).brightness ==
                  Brightness.dark, // Zobrazí aktuální stav tématu
              onChanged: (value) {
                // Zde bude logika pro přepnutí tématu
                print(
                  'Přepínač tmavého režimu změněn na: $value (implementace chybí)',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Přepínání motivu zatím není funkční.'),
                  ),
                );
              },
              // Můžete přidat aktivní barvu, pokud chcete jinou než výchozí
              // activeColor: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              // Můžete také přepínat kliknutím na celou dlaždici
              // (v onChanged by pak byla logika)
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Colors.red.shade400,
            ),
            title: Text(
              'Smazat všechna data',
              style: TextStyle(color: Colors.red.shade400),
            ),
            subtitle: const Text('Smaže všechny předměty a termíny'),
            onTap: () async {
              // 1. Zobrazit potvrzovací dialog
              final bool? confirmed = await _showDeleteConfirmationDialog(
                context,
              );

              // 2. Pokud uživatel potvrdil (dialog vrátil true)
              if (confirmed == true) {
                // Zkontrolujeme 'mounted' PŘED voláním _deleteAllData,
                // protože showDialog je asynchronní.
                if (context.mounted) {
                  await _deleteAllData(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
