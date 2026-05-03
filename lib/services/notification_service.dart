import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefEnabledKey = 'notifications_enabled';

  // ✅ separate toggle for scan reminders (optional)
  static const String _prefScanRemindersKey = 'scan_reminders_enabled';

  // ✅ stable IDs for scheduled reminders (avoid collisions)
  static const int _idBreakfast = 1001;
  static const int _idLunch = 1002;
  static const int _idDinner = 1003;

  // ✅ quick nudge notification ID
  static const int _idScanNudge = 1099;

  // ✅ one-time confirmation notification ID
  static const int _idEnabledConfirmation = 2001;

  // ✅ channel for confirmation
  static const String _channelEnabledConfirmation = 'notif_status';

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  void _log(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  /// Initialize notification service (loads saved preference and syncs with permissions)
  Future<void> initialize() async {
    if (_isInitialized) {
      _log('✅ NotificationService already initialized');
      return;
    }

    try {
      _log('🔔 Initializing NotificationService...');

      // Load saved preference first
      await _loadEnabledPreference();

      // Initialize timezones
      tz_data.initializeTimeZones();

      // Android settings
      const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;

      // If user previously enabled notifications, re-check permissions now
      if (_isEnabled) {
        await _requestPermissions();

        // If permission is denied, reflect that and persist OFF
        if (!_isEnabled) {
          await _saveEnabledPreference(false);
        } else {
          // ✅ Optional: re-schedule defaults on relaunch (only if scan reminders enabled)
          final scanOn = await getScanRemindersEnabled();
          if (scanOn) {
            await scheduleDefaultScanReminders();
          }
        }
      }

      _log('✅ NotificationService initialized successfully');
    } catch (e) {
      _log('❌ NotificationService initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Load user preference from local storage
  Future<void> _loadEnabledPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefEnabledKey) ?? false;
  }

  /// Save user preference to local storage
  Future<void> _saveEnabledPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, value);
    _isEnabled = value;
  }

  // scan reminders preference (optional)
  Future<bool> getScanRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefScanRemindersKey) ?? true;
  }

  Future<void> setScanRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefScanRemindersKey, value);
  }

  /// Request notification permissions
  /// Sets _isEnabled based on OS permission result.
  Future<void> _requestPermissions() async {
    try {
      bool grantedAny = false;
      bool checkedSomething = false;

      // Android 13+ permission request
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        checkedSomething = true;
        final granted =
        await androidImplementation.requestNotificationsPermission();
        grantedAny = granted == true;
        _log(
            '🔔 Android notification permission: ${grantedAny ? "Granted" : "Denied"}');
      }

      // iOS permission request
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        checkedSomething = true;
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        grantedAny = granted == true;
        _log(
            '🔔 iOS notification permission: ${grantedAny ? "Granted" : "Denied"}');
      }

      if (!checkedSomething) {
        _log('⚠️ No platform notification implementation found');
        return;
      }

      _isEnabled = grantedAny;
    } catch (e) {
      _log('❌ Error requesting permissions: $e');
      _isEnabled = false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _log('🔔 Notification tapped: ${response.payload}');
  }

  // ---------------------------------------------------------------------------
  // ✅ Production-safe: ONE-TIME “Notifications enabled” confirmation (not ongoing)
  // ---------------------------------------------------------------------------

  Future<void> showNotificationsEnabledConfirmation() async {
    if (!_isEnabled || !_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelEnabledConfirmation,
      'Notification Status',
      channelDescription: 'Confirmation when notifications are enabled',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: false,
      autoCancel: true,
      onlyAlertOnce: true,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      _idEnabledConfirmation,
      'Notifications enabled',
      'You can manage reminders anytime in Settings.',
      details,
      payload: 'notif_status',
    );
  }

  /// Kept for compatibility with your existing calls (now shows one-time confirmation)
  Future<void> showNotificationsEnabledIndicator() async {
    await showNotificationsEnabledConfirmation();
  }

  /// Kept for compatibility (no-op now; optional cancel of confirmation)
  Future<void> hideNotificationsEnabledIndicator() async {
    await cancel(_idEnabledConfirmation);
  }

  /// Enable notifications (persist ON + request permissions)
  Future<void> enableNotifications() async {
    // User explicitly toggled ON
    await _saveEnabledPreference(true);

    if (!_isInitialized) {
      await initialize();
    }

    await _requestPermissions();

    // If permission denied, persist OFF so switch stays correct
    if (!_isEnabled) {
      await _saveEnabledPreference(false);
      _log('🔕 Notifications permission denied (saved OFF)');
      return;
    }

    _log('🔔 Notifications enabled (saved ON)');

    // ✅ ONE-TIME confirmation (not ongoing)
    await showNotificationsEnabledConfirmation();

    // schedule defaults if scan reminders preference is on
    final scanOn = await getScanRemindersEnabled();
    if (scanOn) {
      await scheduleDefaultScanReminders();
    }
  }

  /// Disable notifications (persist OFF + cancel scheduled/active)
  Future<void> disableNotifications() async {
    await _saveEnabledPreference(false);

    await cancelAll();
    _log('🔕 Notifications disabled (saved OFF)');
  }

  /// Show daily health tip notification
  Future<void> showDailyTipNotification(String tip) async {
    if (!_isEnabled || !_isInitialized) {
      _log('⚠️ Notifications not enabled/initialized');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_tips',
        'Daily Health Tips',
        channelDescription: 'Daily personalized health tips',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0,
        '💡 Daily Health Tip',
        tip,
        details,
        payload: 'daily_tip',
      );

      _log('✅ Daily tip notification shown');
    } catch (e) {
      _log('❌ Error showing notification: $e');
    }
  }

  /// Schedule meal reminder (recurring daily at hour) - kept for compatibility
  Future<void> scheduleMealReminder(int hour, String mealType) async {
    if (!_isEnabled || !_isInitialized) {
      _log('⚠️ Notifications not enabled/initialized');
      return;
    }

    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'meal_reminders',
        'Meal Reminders',
        channelDescription: 'Reminders for meal times',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = hour; // old behavior

      await _notifications.zonedSchedule(
        id,
        '🍽️ $mealType Time!',
        'Time for your $mealType. Don\'t forget to scan and track!',
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'meal_reminder_$mealType',
      );

      _log('✅ Meal reminder scheduled for $mealType at $hour:00');
    } catch (e) {
      _log('❌ Error scheduling meal reminder: $e');
    }
  }

  /// schedule the default “Scan your food” reminders (3x daily)
  Future<void> scheduleDefaultScanReminders() async {
    if (!_isEnabled || !_isInitialized) {
      _log('⚠️ Notifications not enabled/initialized');
      return;
    }

    await setScanRemindersEnabled(true);

    try {
      await _scheduleDailyAt(
        id: _idBreakfast,
        hour: 8,
        minute: 0,
        title: '🍳 About to eat?',
        body: 'Scan your breakfast first — know what you’re eating.',
        payload: 'scan_reminder_breakfast',
      );

      await _scheduleDailyAt(
        id: _idLunch,
        hour: 12,
        minute: 30,
        title: '🥗 Lunchtime!',
        body: 'Before you bite — scan your food with ScanBite.',
        payload: 'scan_reminder_lunch',
      );

      await _scheduleDailyAt(
        id: _idDinner,
        hour: 18,
        minute: 30,
        title: '🌙 Dinner time?',
        body: 'Quick scan reminder — know what you’re eating.',
        payload: 'scan_reminder_dinner',
      );

      _log('✅ Default scan reminders scheduled (8:00, 12:30, 18:30)');
    } catch (e) {
      _log('❌ Error scheduling default scan reminders: $e');
    }
  }

  /// disable ONLY the scan reminders (keeps other notifications)
  Future<void> cancelDefaultScanReminders() async {
    await setScanRemindersEnabled(false);
    await cancel(_idBreakfast);
    await cancel(_idLunch);
    await cancel(_idDinner);
    _log('✅ Default scan reminders cancelled');
  }

  /// instant pop-up “nudge” you can trigger when user opens the app
  Future<void> showScanNudge({String? message}) async {
    if (!_isEnabled || !_isInitialized) return;

    final body = (message?.trim().isNotEmpty == true)
        ? message!.trim()
        : 'Scan your food first — know what you’re eating.';

    try {
      const androidDetails = AndroidNotificationDetails(
        'scan_nudges',
        'Scan Nudges',
        channelDescription: 'Quick reminders to scan your meals',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _idScanNudge,
        '📸 Quick reminder',
        body,
        details,
        payload: 'scan_nudge',
      );

      _log('✅ Scan nudge shown');
    } catch (e) {
      _log('❌ Error showing scan nudge: $e');
    }
  }

  Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'scan_reminders',
      'Scan Reminders',
      channelDescription: 'Reminders to scan meals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Show scan reminder notification (immediate)
  Future<void> showScanReminder(String message) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'scan_reminders',
        'Scan Reminders',
        channelDescription: 'Reminders to scan meals',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1,
        '📸 Scan Your Meal',
        message,
        details,
        payload: 'scan_reminder',
      );

      _log('✅ Scan reminder shown');
    } catch (e) {
      _log('❌ Error showing scan reminder: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      _log('✅ All notifications cancelled');
    } catch (e) {
      _log('❌ Error cancelling notifications: $e');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
      _log('✅ Notification $id cancelled');
    } catch (e) {
      _log('❌ Error cancelling notification: $e');
    }
  }

  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      _log('❌ Error getting pending notifications: $e');
      return 0;
    }
  }
}