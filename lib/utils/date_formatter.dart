import 'package:intl/intl.dart';

class DateFormatter {
  static String formatCzechDate(DateTime date) {
    // Předpokládá, že initializeDateFormatting('cs_CZ', null) bylo zavoláno v main.dart
    final formatter = DateFormat('EEEE, d. MMMM yyyy', 'cs_CZ');
    return formatter.format(date);
  }

  static String formatCzechDateTime(DateTime date) {
    final formatter = DateFormat('d.M.yyyy HH:mm', 'cs_CZ');
    return formatter.format(date);
  }
}
