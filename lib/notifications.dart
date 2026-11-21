import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'data.dart';

/// Schedules the daily 7 PM reminder / roast notifications on Android and iOS.
///
/// Notifications are pre-computed for the next 14 days from the current data
/// and recomputed when the data changes or the app opens — so if you train
/// legs today, tomorrow's leg roast is cancelled.
///
/// Efficiency: changes are batched (1 s), runs never overlap, and if the
/// computed schedule is identical to what's already scheduled, nothing is
/// sent to Android at all.
class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const reminderHour = 19;
  static const daysAhead = 14;

  static Timer? _debounce;
  static Future<void> _chain = Future.value();
  static String? _lastSignature;

  static bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  static NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          'gymbroo_reminders',
          'Workout reminders',
          channelDescription: 'Daily nudges about incomplete muscles and roasts for skipped ones',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFDC2F2F),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
      );

  static Future<void> init() async {
    if (!supported) return;
    try {
      // Only absolute UTC instants are scheduled, so the (large) time-zone
      // database is never loaded — faster start-up and a smaller app.
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is requested later, from the in-app toggle — not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  /// Asks for the notification permission (Android 13+ / iOS). Returns true if granted.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _ios?.requestPermissions(alert: true, badge: false, sound: true) ?? false;
    }
    return await _android?.requestNotificationsPermission() ?? false;
  }

  /// Batched reschedule — call freely after every data change.
  static void requestReschedule(AppState s) {
    if (!_ready) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () => reschedule(s));
  }

  /// Reschedules now. Calls are serialized so two runs never interleave.
  static Future<void> reschedule(AppState s) {
    if (!_ready) return _chain;
    _debounce?.cancel();
    return _chain = _chain.then((_) => _doReschedule(s));
  }

  static Future<void> _doReschedule(AppState s) async {
    try {
      final now = DateTime.now();
      final plan = <(DateTime, String, String)>[];
      if (s.notify) {
        for (var i = 0; i < daysAhead; i++) {
          final when = DateTime(now.year, now.month, now.day + i, reminderHour);
          if (!when.isAfter(now)) continue;
          final body = s.reminderFor(ymd(when));
          if (body != null) plan.add((when, s.roastLevel.notificationTitle, body));
        }
      }
      final signature = plan.map((p) => '${p.$1.toIso8601String()}|${p.$2}|${p.$3}').join('\n');
      if (signature == _lastSignature) return; // nothing changed → no platform calls

      // Only pending (future) ones — a reminder already in the shade stays put.
      await _plugin.cancelAllPendingNotifications();
      for (var i = 0; i < plan.length; i++) {
        final (at, title, body) = plan[i];
        await _plugin.zonedSchedule(
          id: 100 + i,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(at, tz.UTC), // absolute instant
          notificationDetails: _details(body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      _lastSignature = signature;
    } catch (e) {
      _lastSignature = null; // force a full retry next time
      debugPrint('Notification scheduling failed: $e');
    }
  }

  static Future<void> showNow(AppState s) async {
    if (!_ready) return;
    final body = s.reminderFor(todayStr()) ?? 'All weekly goals done. Absolute unit. 🦍';
    await _plugin.show(id: 1, title: s.roastLevel.notificationTitle, body: body, notificationDetails: _details(body));
  }
}
