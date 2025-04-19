import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/provider/settings_provider.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';
import 'package:schoolcalendar/provider/task_provider.dart';
import 'package:schoolcalendar/provider/theme_provider.dart';
import 'package:schoolcalendar/service/notification_service.dart';

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
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    // Read pro akce
    // final settingsNotifier = context.read<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // --- Vzhled ---
          ListTile(
            title: Text(
              'Vzhled',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Tmavý režim'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme(value);
              },
            ),
            onTap: () {
              final currentMode = themeProvider.themeMode;
              context.read<ThemeProvider>().toggleTheme(
                currentMode != ThemeMode.dark,
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // --- Sekce Notifikace ---
          ListTile(
            title: Text(
              'Připomenutí termínů',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            dense: true,
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.hourglass_top_outlined),
            title: const Text('Hodinu předem'),
            value: settingsProvider.notifyOneHourBefore,
            onChanged: (value) {
              context.read<SettingsProvider>().setNotifyOneHour(value ?? false);
            },
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.calendar_today_outlined),
            title: const Text('Den předem'),
            value: settingsProvider.notifyOneDayBefore,
            onChanged: (value) {
              context.read<SettingsProvider>().setNotifyOneDay(value ?? false);
            },
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.calendar_month_outlined),
            title: const Text('Týden předem'),
            value: settingsProvider.notifyOneWeekBefore,
            onChanged: (value) {
              context.read<SettingsProvider>().setNotifyOneWeek(value ?? false);
            },
          ),

          // --- Test Notifikace ---
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Otestovat notifikaci'),
            subtitle: const Text('Zobrazí ukázkovou notifikaci ihned'),
            onTap: () {
              AwesomeNotificationService.showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Testovací notifikace odeslána. Měla by se brzy objevit.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // --- Sekce Data ---
          ListTile(
            title: Text(
              'Správa dat',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            dense: true,
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Colors.red.shade400,
            ),
            title: Text(
              'Smazat všechna data',
              style: TextStyle(color: Colors.red.shade400),
            ),
            onTap: () async {
              final bool? confirmed = await _showDeleteConfirmationDialog(
                context,
              );
              if (confirmed == true) {
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
