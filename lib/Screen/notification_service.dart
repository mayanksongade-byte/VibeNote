import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleAction(response);
}

class NotificationService {
  NotificationService._();

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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImplementation = notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    _initialized = true;

    final launchDetails =
    await notificationsPlugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload ?? "";
      final parts = payload.split("|||");
      if (parts.length >= 4) {
        pendingOpenNoteId = parts[3];
      }
    }

    final androidPlugin = notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'vibenote_default_channel',
          'VibeNote Reminders',
          description: 'Default reminder notifications',
          importance: Importance.max,
        ),
      );

      const sounds = [
        'faaa',
        'hindi_meme',
        'jethalal_meme',
        'nahi_meme',
        'depression_meme',
        'choti_bachi_ho_kya',
        'danish_bhai',
        'omae_wa_mu_shindeu',
        'omfo_song_jay_toffek',
      ];

      final prefs = await SharedPreferences.getInstance();
      const channelsFixedKey = 'vibenote_sound_channels_fixed_v1';
      final alreadyFixed = prefs.getBool(channelsFixedKey) ?? false;

      if (!alreadyFixed) {
        // Android notification channels are permanent once created — if these
        // were created earlier without a valid raw sound resource, recreating
        // them with the same id silently does nothing. Delete them once so
        // they get recreated below with the correct sound.
        for (final sound in sounds) {
          try {
            await androidPlugin.deleteNotificationChannel(
              channelId: 'vibenote_${sound}_channel',
            );
          } catch (_) {}
        }
        await prefs.setBool(channelsFixedKey, true);
      }

      for (final sound in sounds) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'vibenote_${sound}_channel',
            'VibeNote $sound',
            description: 'Reminder notifications',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(sound),
          ),
        );
      }
    }
  }

  static Future<void> handleAction(NotificationResponse response) async {
    final payload = response.payload ?? "";
    final parts = payload.split("|||");

    if (parts.length < 4) return;

    final id = int.tryParse(parts[0]);
    final noteId = parts[3];

    if (id == null) return;

    final actionId = response.actionId ?? "";

    if (actionId == "done_action") {
      await notificationsPlugin.cancel(id: id);
      pendingOpenNoteId = null;
      return;
    }

    if (actionId == "open_action" || actionId.isEmpty) {
      pendingOpenNoteId = noteId;

      if (onOpenNoteRequest != null) {
        onOpenNoteRequest!(noteId);
        pendingOpenNoteId = null;
      }

      return;
    }
  }

  static Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id: id);
  }

  static Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  static String _channelIdForSound(String selectedSound) {
    return selectedSound == "default"
        ? "vibenote_default_channel"
        : "vibenote_${selectedSound}_channel";
  }

  static String _channelNameForSound(String selectedSound) {
    return selectedSound == "default"
        ? "VibeNote Reminders"
        : "VibeNote ${selectedSound.replaceAll('_', ' ')}";
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

    final prefs = await SharedPreferences.getInstance();

    final notificationsEnabled = prefs.getBool("notificationsOn") ?? true;
    if (!notificationsEnabled) return;

    final selectedSound = prefs.getString("notification_sound") ?? "default";

    final cleanBody = body.trim().isEmpty
        ? "Open VibeNote to view this note."
        : body.trim();

    final payload = "$id|||$title|||$cleanBody|||${noteId ?? ""}";

    final androidDetails = AndroidNotificationDetails(
      _channelIdForSound(selectedSound),
      _channelNameForSound(selectedSound),
      channelDescription: 'Smart reminder notifications for your notes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: selectedSound == "default"
          ? null
          : RawResourceAndroidNotificationSound(selectedSound),
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
    } catch (e) {
      debugPrint("Notification exact schedule error: $e");

      try {
        await notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: cleanBody,
          scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (e) {
        debugPrint("Notification inexact schedule error: $e");
        rethrow;
      }
    }
  }
}