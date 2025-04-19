// lib/services/awesome_notification_service.dart (příklad)
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // Potřeba pro Color

// Unikátní klíč pro notifikační kanál
const String channelKeyReminders = 'school_calendar_reminders_channel';

class AwesomeNotificationService {
  ///  Inicializace Awesome Notifications
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, //např. res_app_icon.png
      [
        // Seznam kanálů k vytvoření
        NotificationChannel(
          channelKey: channelKeyReminders,
          channelName: 'Připomenutí termínů',
          channelDescription: 'Notifikace pro blížící se termíny',
          defaultColor: Colors.blue.shade800, // Barva ikony/akcentu
          ledColor: Colors.white,
          importance: NotificationImportance.Max, // Nejvyšší důležitost
          channelShowBadge: true, // Zobrazit odznak na ikoně aplikace
          playSound: true,
          enableVibration: true,
          // locked: true,
        ),
      ],
      // Nastavení pro debugování
      debug: true,
    );

    // Nastavení listenerů pro akce
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
    log("Awesome notifications initialized");
  }

  /// Žádost o oprávnění
  static Future<bool> requestPermissions() async {
    // Zjistí, zda jsou notifikace obecně povoleny
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      // Požádá o základní oprávnění (POST_NOTIFICATIONS na A13+)
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Volitelně  preciseAlarm: true
    /*
    bool hasPrecise = await AwesomeNotifications().checkPermissionList(
        permissions: [NotificationPermission.PreciseAlarms]);
    print("Precise Alarm permission: $hasPrecise");
    if (!hasPrecise) {
        print("Requesting Precise Alarm permission...");
        // Toto může uživatele poslat do nastavení systému
        await AwesomeNotifications().requestPermissionToSendNotifications(
            permissions: [NotificationPermission.PreciseAlarms]);
        // Znovu zkontrolovat po žádosti (uživatel mohl odmítnout)
        hasPrecise = await AwesomeNotifications().checkPermissionList(
             permissions: [NotificationPermission.PreciseAlarms]);
        print("Precise Alarm permission after request: $hasPrecise");
    }
    */

    return isAllowed;
  }

  // Plánování notifikace
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    Map<String, String>? payload,
    bool usePreciseAlarm = false, // PARAMETR: přesný alarm?
  }) async {
    // Čas musí být v budoucnosti
    if (scheduledDateTime.isBefore(DateTime.now())) {
      log(
        "AwesomeNotify Service: Skipping scheduling ID $id: Scheduled time is in the past.",
      );
      return;
    }

    log(
      "AwesomeNotify Service: Scheduling ID=$id for $scheduledDateTime [Precise: $usePreciseAlarm]",
    );

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKeyReminders,
          title: title,
          body: body,
          payload: payload,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDateTime,
          preciseAlarm: usePreciseAlarm,
          allowWhileIdle: true, // Povolit i v idle režimu
          repeats: false, // Jednorázová notifikace
        ),
      );
      log(
        "AwesomeNotify Service: Notification ID $id scheduled successfully for $scheduledDateTime [Precise: $usePreciseAlarm]",
      );
    } catch (e) {
      log("Error scheduling awesome notification ID $id: $e");
    }
  }

  /// Testovací notifikace
  static Future<void> showTestNotification() async {
    print("Showing awesome test notification...");
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 0, // Pevné ID pro test
          channelKey: channelKeyReminders,
          title: 'Testovací Notifikace (Awesome) 🚀',
          body: 'Pokud vidíš tuto zprávu, awesome notifikace fungují!',
          payload: {'test': 'awesome_payload'},
          category: NotificationCategory.Status,
        ),
        // Bez parametru 'schedule' se zobrazí ihned
      );
    } catch (e) {
      log("Error showing awesome test notification: $e");
    }
  }

  // Zrušení notifikací
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    print("Cancelled awesome notification with ID: $id");
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print("Cancelled all awesome notifications.");
  }

  static Future<void> cancelTaskNotifications(int taskId) async {
    await cancelNotification(generateNotificationId(taskId, 1));
    await cancelNotification(generateNotificationId(taskId, 2));
    await cancelNotification(generateNotificationId(taskId, 3));
    log("Cancelled potential awesome notifications for Task ID: $taskId");
  }

  // Generátor ID
  static int generateNotificationId(int taskId, int intervalCode) {
    const int hourOffset = 100000;
    const int dayOffset = 200000;
    const int weekOffset = 300000;
    if (taskId <= 0 || intervalCode < 1 || intervalCode > 3) {
      log(
        "WARN: Invalid taskId or intervalCode for notification ID generation.",
      );
      return -(taskId.abs() + intervalCode * 10);
    }
    int id;
    switch (intervalCode) {
      case 1:
        id = taskId + hourOffset;
        break;
      case 2:
        id = taskId + dayOffset;
        break;
      case 3:
        id = taskId + weekOffset;
        break;
      default:
        id = -1;
    }
    // Omezení na 32-bit signed integer
    const int maxInt32 = 2147483647;
    if (id > maxInt32) {
      log(
        "WARN: Generated notification ID exceeds 32-bit limit, potentially wrapping around.",
      );
      // Může způsobit kolize, zvážit jiný systém ID
      id = id % maxInt32;
    }
    return id;
  }
}

//Controller pro zpracování akcí notifikací
// Ideálně by měl být v samostatném souboru
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    log('onNotificationCreatedMethod: ${receivedNotification.id}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    log('onNotificationDisplayedMethod: ${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    log('onDismissActionReceivedMethod: ${receivedAction.id}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    log('onActionReceivedMethod: ${receivedAction.id}');
    log('Payload: ${receivedAction.payload}');
  }
}
