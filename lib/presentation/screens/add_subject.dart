import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolcalendar/data/db/database.dart';
import 'package:schoolcalendar/provider/subject_provider.dart';

class AddSubject extends StatelessWidget {
  const AddSubject({super.key});

  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> _formKey = GlobalKey();
    TextEditingController _codeController = TextEditingController();
    TextEditingController _nameController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text("Přidat nový předmět")),
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Kód nemůže být prázdný";
                      }
                    },
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: "Kód",
                      //helperText: "MAT1",
                      hintText: "MAT1",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Název nemůže být prázdný";
                      }
                    },
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Název předmětu",
                      //helperText: "MAT1",
                      hintText: "Matematika 1",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      SubjectsCompanion sc = SubjectsCompanion(
                        code: drift.Value(_codeController.text),
                        name: drift.Value(_nameController.text),
                      );
                      await subjectProvider.addSubject(sc);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Předmět úspěšně přidán")),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Přidat nový předmět"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
