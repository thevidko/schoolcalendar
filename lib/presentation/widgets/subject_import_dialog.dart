import 'package:flutter/material.dart';
import 'package:schoolcalendar/data/models/stag_subject_model.dart';

// Funkce pro zobrazení dialogu
Future<List<StagSubject>?> showSubjectImportDialog(
  BuildContext context,
  List<StagSubject> subjects,
) {
  // Mapa pro uchování stavu zaškrtnutí pro každý předmět
  final Map<int, bool> selectedStates = {
    for (var i = 0; i < subjects.length; i++)
      i: false, // Defaultně nic není vybráno
  };

  return showDialog<List<StagSubject>>(
    context: context,
    barrierDismissible: false, // Uživatel musí vybrat akci
    builder: (BuildContext dialogContext) {
      //StatefulBuilder pro správu stavu checkboxů uvnitř dialogu
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Vyberte předměty pro import'),
            content: SizedBox(
              // Omezení velikosti dialogu
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.5,
              child:
                  subjects.isEmpty
                      ? const Center(
                        child: Text(
                          'Nebyly nalezeny žádné předměty ke stažení.',
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return CheckboxListTile(
                            title: Text(subject.nazev ?? 'Bez názvu'),
                            subtitle: Text(subject.zkratka ?? 'Bez kódu'),
                            value: selectedStates[index],
                            onChanged: (bool? value) {
                              // Aktualizace stavu checkboxu uvnitř StatefulBuilderu
                              setState(() {
                                selectedStates[index] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Zrušit'),
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(null); // Zavřít a vrátit null (žádný výběr)
                },
              ),
              TextButton(
                child: const Text('Importovat vybrané'),
                onPressed: () {
                  // vybrané předměty
                  final List<StagSubject> selectedSubjects = [];
                  selectedStates.forEach((index, isSelected) {
                    if (isSelected) {
                      selectedSubjects.add(subjects[index]);
                    }
                  });
                  // Zavření dialogu a vrácení seznamu vybraných předmětů
                  Navigator.of(dialogContext).pop(selectedSubjects);
                },
              ),
            ],
          );
        },
      );
    },
  );
}
