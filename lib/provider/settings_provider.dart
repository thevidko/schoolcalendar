import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Klíče pro uložení nastavení notifikací
const String _notifyHourKey = 'notify_hour_before';
const String _notifyDayKey = 'notify_day_before';
const String _notifyWeekKey = 'notify_week_before';

class SettingsProvider extends ChangeNotifier {
  bool _notifyOneHourBefore = true; // Výchozí hodnoty
  bool _notifyOneDayBefore = true;
  bool _notifyOneWeekBefore = false;

  bool get notifyOneHourBefore => _notifyOneHourBefore;
  bool get notifyOneDayBefore => _notifyOneDayBefore;
  bool get notifyOneWeekBefore => _notifyOneWeekBefore;

  SettingsProvider() {
    _loadNotificationPreferences(); // Načteme při startu
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notifyOneHourBefore =
          prefs.getBool(_notifyHourKey) ??
          _notifyOneHourBefore; // Použijeme ?? pro default
      _notifyOneDayBefore = prefs.getBool(_notifyDayKey) ?? _notifyOneDayBefore;
      _notifyOneWeekBefore =
          prefs.getBool(_notifyWeekKey) ?? _notifyOneWeekBefore;
    } catch (e) {
      print("Error loading notification preferences: $e");
    }
    notifyListeners(); // Notifikujeme po načtení
  }

  Future<void> _saveBoolPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print("Error saving preference $key: $e");
    }
  }

  // Metody pro aktualizaci jednotlivých nastavení
  Future<void> setNotifyOneHour(bool value) async {
    if (_notifyOneHourBefore == value) return;
    _notifyOneHourBefore = value;
    notifyListeners();
    await _saveBoolPreference(_notifyHourKey, value);
    // Zde by bylo ideální přeplánovat VŠECHNY existující notifikace
    // podle nového nastavení - to je ale složitější.
    // Pro jednoduchost teď jen uložíme preferenci pro BUDOUCÍ úkoly.
  }

  Future<void> setNotifyOneDay(bool value) async {
    if (_notifyOneDayBefore == value) return;
    _notifyOneDayBefore = value;
    notifyListeners();
    await _saveBoolPreference(_notifyDayKey, value);
    // TODO: Reschedule existing notifications?
  }

  Future<void> setNotifyOneWeek(bool value) async {
    if (_notifyOneWeekBefore == value) return;
    _notifyOneWeekBefore = value;
    notifyListeners();
    await _saveBoolPreference(_notifyWeekKey, value);
    // TODO: Reschedule existing notifications?
  }
}
