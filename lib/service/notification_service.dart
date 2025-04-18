// lib/services/awesome_notification_service.dart (příklad)
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // Potřeba pro Color

// Unikátní klíč pro notifikační kanál
const String channelKeyReminders = 'school_calendar_reminders_channel';

class AwesomeNotificationService {
  static Future<void> initialize() async {
    // --- Inicializace Awesome Notifications ---
    await AwesomeNotifications().initialize(
      // Použijte cestu k ikoně v android/app/src/main/res/drawable
      // Název ikony BEZ přípony. Musí existovat!
      null, // Vytvořte ikonu např. res_app_icon.png
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
          // locked: true, // Pokud chcete, aby uživatel nemohl kanál snadno vypnout
        ),
      ],
      // Volitelně: Nastavení pro debugování
      debug: true, // Vypíše více logů z pluginu
    );

    // Nastavení listenerů pro akce (kliknutí na notifikaci atd.)
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );

    print("AwesomeNotificationService Initialized.");
  }

  // --- Žádost o oprávnění ---
  static Future<bool> requestPermissions() async {
    // Zjistí, zda jsou notifikace obecně povoleny
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    print("Notifications allowed initially: $isAllowed");

    if (!isAllowed) {
      // Požádá o základní oprávnění (POST_NOTIFICATIONS na A13+)
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      print("Permission request result: $isAllowed");
    }

    // Volitelně: Zkontrolovat/požádat o oprávnění pro PŘESNÉ alarmy
    // Pokud plánujete používat preciseAlarm: true
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

  // --- Plánování notifikace ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    Map<String, String>? payload, // Payload je Map<String, String>?
    bool usePreciseAlarm = false, // PARAMETR: Chceme přesný alarm? Defaultně NE
  }) async {
    // Čas musí být v budoucnosti
    if (scheduledDateTime.isBefore(DateTime.now())) {
      print(
        "AwesomeNotify Service: Skipping scheduling ID $id: Scheduled time is in the past.",
      );
      return;
    }

    print(
      "AwesomeNotify Service: Scheduling ID=$id for $scheduledDateTime [Precise: $usePreciseAlarm]",
    );

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id, // Unikátní ID (int)
          channelKey: channelKeyReminders, // Klíč kanálu
          title: title,
          body: body,
          payload: payload, // Vlastní data
          notificationLayout: NotificationLayout.Default, // Běžné rozložení
          // Můžete přidat další (largeIcon, bigPicture, ...)
          // locked: true, // Notifikace zůstane, dokud ji uživatel neodstraní
          wakeUpScreen: true, // Pokusí se probudit obrazovku
          category: NotificationCategory.Reminder, // Kategorie
        ),
        schedule: NotificationCalendar.fromDate(
          date:
              scheduledDateTime, // DateTime objekt (použije lokální čas zařízení)
          preciseAlarm:
              usePreciseAlarm, // Použít přesný alarm? VYŽADUJE OPRÁVNĚNÍ!
          allowWhileIdle: true, // Povolit i v idle režimu (důležité!)
          repeats: false, // Jednorázová notifikace
        ),
        // Můžete přidat i tlačítka akcí
        // actionButtons: [ NotificationActionButton(...) ]
      );
      print(
        "AwesomeNotify Service: Notification ID $id scheduled successfully for $scheduledDateTime [Precise: $usePreciseAlarm]",
      );
    } catch (e) {
      print("Error scheduling awesome notification ID $id: $e");
    }
  }

  // --- Testovací notifikace ---
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
      print("Awesome test notification created.");
    } catch (e) {
      print("Error showing awesome test notification: $e");
    }
  }

  // --- Zrušení notifikací ---
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    print("Cancelled awesome notification with ID: $id");
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print("Cancelled all awesome notifications.");
  }

  static Future<void> cancelTaskNotifications(int taskId) async {
    // Potřebujeme znát, jaká ID byla pro úkol použita
    // Pokud používáme stejný generátor ID jako předtím:
    await cancelNotification(generateNotificationId(taskId, 1));
    await cancelNotification(generateNotificationId(taskId, 2));
    await cancelNotification(generateNotificationId(taskId, 3));
    // Nebo pokud awesome_notifications má lepší způsob, jak rušit podle payloadu/tagu?
    // Prozkoumat API pro metody jako cancelNotificationsByTag apod.
    // Pro jednoduchost zatím použijeme starý způsob rušení podle ID.
    print("Cancelled potential awesome notifications for Task ID: $taskId");
  }

  // Generátor ID (může zůstat stejný, pokud jsou ID v rozsahu 32-bit int)
  static int generateNotificationId(int taskId, int intervalCode) {
    const int hourOffset = 100000;
    const int dayOffset = 200000;
    const int weekOffset = 300000;
    if (taskId <= 0 || intervalCode < 1 || intervalCode > 3) {
      print(
        "WARN: Invalid taskId or intervalCode for notification ID generation.",
      );
      // Vrátíme nějaké nekonfliktní ID, např. negativní variantu,
      // kterou pak awesome_notifications může ignorovat, pokud neumí záporná ID
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
      print(
        "WARN: Generated notification ID exceeds 32-bit limit, potentially wrapping around.",
      );
      // Může způsobit kolize, zvážit jiný systém ID
      id = id % maxInt32;
    }
    return id;
  }
}

// --- Controller pro zpracování akcí notifikací (minimální verze) ---
// Toto je potřeba pro setListeners, i když to třeba hned nevyužiješ
// Ideálně by měl být v samostatném souboru
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('onNotificationCreatedMethod: ${receivedNotification.id}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('onNotificationDisplayedMethod: ${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print('onDismissActionReceivedMethod: ${receivedAction.id}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print('onActionReceivedMethod: ${receivedAction.id}');
    print('Payload: ${receivedAction.payload}'); // Vypíše payload
    // Zde můžeš přidat logiku pro navigaci na základě payloadu
    // Např. rozparsovat payload['taskId'] a navigovat na detail úkolu
  }
}
