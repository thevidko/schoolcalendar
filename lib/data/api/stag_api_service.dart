import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:schoolcalendar/data/models/stag_subject_model.dart';

class StagApiService {
  final String _baseUrl = "stagws.uhk.cz"; //UNIVERZITA HRADEC KRÁLOVÉ
  final String _basePath = "/ws/services/rest2";

  // Metoda pro získání předmětů studenta
  Future<List<StagSubject>> fetchStudentSubjects(
    String ticket,
    String studentIdentifier,
  ) async {
    final path = '$_basePath/predmety/getPredmetyByStudent';
    final queryParameters = {
      'osCislo': studentIdentifier,
      'outputFormat': 'json',
      'semestr': '%', // Všechny semestry
      'rok': '%', // Všechny roky
      // 'nevracetUznane': 'TRUE',  // Volitelně pro ignorování uznaných
    };

    // Sestavení URL
    final uri = Uri.https(_baseUrl, path, queryParameters);
    print("Fetching STAG Subjects from: $uri"); // Debug print

    // Vytvoření Basic Auth hlavičky
    final String credentials = '$ticket:';
    final String encodedCredentials = base64Url.encode(
      utf8.encode(credentials),
    );
    final Map<String, String> headers = {
      'Authorization': 'Basic $encodedCredentials',
    };

    try {
      final response = await http.get(uri, headers: headers);

      print("STAG API Response Status: ${response.statusCode}"); // Debug print

      if (response.statusCode == 200) {
        // Úspěch, parse JSON
        final decodedBody = utf8.decode(
          response.bodyBytes,
        ); // Správné dekódování UTF-8
        final Map<String, dynamic> data = jsonDecode(decodedBody);

        //  Kontrola dat zda obsahují klíč 'predmetStudenta' a zda je to list
        if (data.containsKey('predmetStudenta') &&
            data['predmetStudenta'] is List) {
          final List<dynamic> subjectsJson = data['predmetStudenta'];
          // Převedení JSON na StagSubject modely
          final List<StagSubject> subjects =
              subjectsJson
                  .map((json) => StagSubject.fromJson(json))
                  .where(
                    (subject) =>
                        subject.zkratka != null && subject.nazev != null,
                  ) // Filtrujeme neplatné
                  .toList();
          return subjects;
        } else {
          // Očekávaná struktura JSONu nebyla nalezena
          print(
            "STAG API Response missing 'predmetStudenta' list or has wrong format.",
          );
          return [];
        }
      } else {
        // Chyba API
        print(
          "STAG API Error: ${response.statusCode} - ${response.reasonPhrase}",
        );
        throw Exception(
          'Nepodařilo se načíst předměty ze STAGu (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      // Síťová chyba nebo chyba při parsování
      print("Error fetching STAG subjects: $e");
      throw Exception('Chyba připojení nebo zpracování odpovědi ze STAGu: $e');
    }
  }
}
