import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleAction(response);
}

class NotificationService {
  static String? pendingOpenNoteId;
  static void Function(String noteId)? onOpenNoteRequest;

  static final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static String? consumePendingOpenNoteId() {
    final id = pendingOpenNoteId;
    pendingOpenNoteId = null;
    return id;
  }

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> handleAction(NotificationResponse response) async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    final payload = response.payload ?? "";
    final parts = payload.split("|||");

    if (parts.length < 4) return;

    final id = int.tryParse(parts[0]);
    final title = parts[1];
    final body = parts[2];
    final noteId = parts[3];

    if (id == null) return;

    final actionId = response.actionId ?? "";

    if (actionId == "done_action") {
      await cancelNotification(id);
      return;
    }

    if (actionId == "snooze_action") {
      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: DateTime.now().add(const Duration(minutes: 10)),
        noteId: noteId,
      );
      return;
    }

    if (actionId == "open_action" || actionId.isEmpty) {
      pendingOpenNoteId = noteId;
      onOpenNoteRequest?.call(noteId);
      return;
    }
  }

  static Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id: id);
  }

  static Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  static Future<void> scheduleNotification({
    String? noteId,
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await cancelNotification(id);

    final cleanBody = body.trim().isEmpty
        ? "Open VibeNote to view this note."
        : body.trim();

    final payload = "$id|||$title|||$cleanBody|||${noteId ?? ""}";

    final androidDetails = AndroidNotificationDetails(
      'vibenote_channel',
      'VibeNote Reminders',
      channelDescription: 'Smart reminder notifications for your notes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'VibeNote Reminder',
      styleInformation: BigTextStyleInformation(
        cleanBody,
        contentTitle: title,
        summaryText: 'VibeNote',
      ),
      actions: const [
        AndroidNotificationAction(
          'done_action',
          'Done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'snooze_action',
          'Snooze 10m',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'open_action',
          'Open',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: cleanBody,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      await notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: cleanBody,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }
}