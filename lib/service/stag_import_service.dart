import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/api/stag_api_service.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/data/models/stag_subject_model.dart';
import 'package:schoolcalendar/presentation/widgets/subject_import_dialog.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';

class StagImportService {
  final _secureStorage = const FlutterSecureStorage();
  final _stagApiService = StagApiService();

  /// Spustí proces importu předmětů ze STAGu.
  Future<void> startImport({
    required BuildContext context,
    required VoidCallback onImportStart,
    required Function(bool success, String message) onImportFinish,
  }) async {
    // 1. Signalizace začátku a zobrazení úvodní zprávy
    onImportStart();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ověřuji přihlášení a načítám předměty...')),
    );

    try {
      // 2. Získání přihlašovacích údajů
      final ticket = await _secureStorage.read(key: 'stag_user_ticket');
      final identifier = await _secureStorage.read(
        key: 'stag_student_identifier',
      );

      if (ticket == null || identifier == null) {
        throw Exception(
          'Přihlašovací údaje STAG nebyly nalezeny. Přihlaste se prosím znovu v menu.',
        );
      }

      // 3. Načtení předmětů z API
      final List<StagSubject> stagSubjects = await _stagApiService
          .fetchStudentSubjects(ticket, identifier);

      // 4. Zpracování načtených předmětů - zobrazení dialogu pro výběr
      if (!context.mounted) return;

      if (stagSubjects.isEmpty) {
        onImportFinish(
          true,
          'Nebyly nalezeny žádné předměty zapsané v tomto semestru na STAGu.',
        );
        return;
      }

      // Zobrazíme dialog pro výběr předmětů k importu
      final List<StagSubject>? selectedSubjects = await showSubjectImportDialog(
        context,
        stagSubjects,
      );

      // 5. Zpracování výběru uživatele
      if (selectedSubjects == null) {
        // Uživatel zavřel dialog (zrušil import)
        onImportFinish(false, 'Import předmětů byl zrušen.');
        return;
      }

      if (selectedSubjects.isEmpty) {
        // Uživatel potvrdil dialog, ale nevybral žádný předmět
        onImportFinish(true, 'Nebyly vybrány žádné předměty k importu.');
        return;
      }

      // 6. Import vybraných předmětů do databáze
      if (!context.mounted) return;

      final subjectProvider = Provider.of<SubjectProvider>(
        context,
        listen: false,
      );
      int importCount = 0;
      int errorCount = 0;
      List<String> errorSubjects = [];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Importuji ${selectedSubjects.length} vybraných předmětů...',
          ),
        ),
      );

      for (final subject in selectedSubjects) {
        // Ověření, zda má předmět potřebné údaje
        if (subject.zkratka != null && subject.nazev != null) {
          final companion = SubjectsCompanion.insert(
            name: subject.nazev!,
            code: subject.zkratka!,
          );
          try {
            //přidání předmětu do lokální databáze
            await subjectProvider.addSubject(companion);
            importCount++;
          } catch (e) {
            print("Chyba při importu předmětu ${subject.zkratka}: $e");
            errorCount++;
            errorSubjects.add(subject.zkratka!);
          }
        } else {
          // Předmět ze STAGu nemá zkratku nebo název
          print(
            "Předmět ze STAGu nemá zkratku nebo název: ${subject.nazev} / ${subject.zkratka}",
          );
          errorCount++;
          errorSubjects.add(subject.nazev ?? subject.zkratka ?? 'Neznámý');
        }
      }

      // 7. Sestavení a zobrazení výsledné zprávy
      String resultMessage =
          'Import dokončen. Bylo úspěšně importováno $importCount předmětů.';
      if (errorCount > 0) {
        resultMessage +=
            '\n$errorCount předmětů se nepodařilo importovat (např. již existují nebo chybí data): ${errorSubjects.join(', ')}.';
      }
      onImportFinish(true, resultMessage); // Import proběhl i přes chyby
    } catch (e) {
      // 8. Zpracování obecných chyb
      log("STAG Import Error: $e");
      if (context.mounted) {
        onImportFinish(false, 'Chyba během importu ze STAG: ${e.toString()}');
      }
    }
  }
}
