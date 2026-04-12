import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/app_constants.dart';
import '../core/constants/notification_sound_option.dart';
import '../data/models/task_model.dart';

enum _ScheduledNotificationType { reminder, followUpAlarm }

class NotificationService {
  NotificationService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SharedPreferencesAsync _preferences;
  final MethodChannel _androidAlarmChannel = const MethodChannel(
    AppConstants.androidAlarmMethodChannel,
  );

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notificationsPlugin.initialize(settings: settings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    if (!canScheduleExact) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleTaskNotifications(TaskModel task) async {
    try {
      await _scheduleTaskNotificationsInternal(task);
    } catch (error, stackTrace) {
      debugPrint(
        'Notification scheduling failed for task ${task.id ?? 'unknown'}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _scheduleTaskNotificationsInternal(TaskModel task) async {
    await initialize();

    final int? taskId = task.id;
    final TaskSchedule? schedule = task.schedule;

    if (taskId == null) {
      return;
    }

    await cancelTaskNotifications(taskId);

    if (schedule == null || !schedule.reminderEnabled || task.isCompleted) {
      return;
    }

    final DateTime? reminderTrigger = _nextTrigger(task);
    if (reminderTrigger == null) {
      return;
    }

    final bool canScheduleExact = await _canScheduleExactNotifications();
    final NotificationSoundOption reminderSound = await _loadReminderSound();
    final NotificationSoundOption alarmSound = await _loadAlarmSound();

    await _ensureAndroidChannel(
      type: _ScheduledNotificationType.reminder,
      soundOption: reminderSound,
    );
    await _scheduleNotification(
      task: task,
      triggerAt: reminderTrigger,
      type: _ScheduledNotificationType.reminder,
      soundOption: reminderSound,
      canScheduleExact: canScheduleExact,
    );

    if (!schedule.followUpAlarmEnabled) {
      return;
    }

    final DateTime followUpTrigger = reminderTrigger.add(
      const Duration(minutes: AppConstants.followUpAlarmDelayMinutes),
    );

    if (_usesAndroidDeviceAlarm) {
      final bool scheduled = await _scheduleAndroidDeviceAlarm(
        task: task,
        triggerAt: followUpTrigger,
        soundOption: alarmSound,
      );

      if (scheduled) {
        return;
      }
    }

    await _ensureAndroidChannel(
      type: _ScheduledNotificationType.followUpAlarm,
      soundOption: alarmSound,
    );
    await _scheduleNotification(
      task: task,
      triggerAt: followUpTrigger,
      type: _ScheduledNotificationType.followUpAlarm,
      soundOption: alarmSound,
      canScheduleExact: canScheduleExact,
    );
  }

  Future<void> rescheduleActiveTaskNotifications(
    Iterable<TaskModel> tasks,
  ) async {
    for (final TaskModel task in tasks) {
      if (task.id == null) {
        continue;
      }

      if (task.isCompleted || task.schedule == null) {
        await cancelTaskNotifications(task.id!);
      } else {
        await scheduleTaskNotifications(task);
      }
    }
  }

  Future<void> cancelTaskNotifications(int taskId) async {
    try {
      await _notificationsPlugin.cancel(id: _reminderNotificationId(taskId));
      await _notificationsPlugin.cancel(
        id: _followUpAlarmNotificationId(taskId),
      );

      if (_usesAndroidDeviceAlarm) {
        try {
          await _androidAlarmChannel.invokeMethod<void>('cancelDeviceAlarm', {
            'taskId': taskId,
          });
        } catch (_) {
          // Ignore missing native alarm integrations and rely on local cancellation.
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Notification cancellation failed for task $taskId: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelTaskReminder(int taskId) =>
      cancelTaskNotifications(taskId);

  bool get _usesAndroidDeviceAlarm =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _scheduleNotification({
    required TaskModel task,
    required DateTime triggerAt,
    required _ScheduledNotificationType type,
    required NotificationSoundOption soundOption,
    required bool canScheduleExact,
  }) async {
    final TaskSchedule schedule = task.schedule!;
    final NotificationSoundRole soundRole = _soundRoleFor(type);
    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(type, soundOption),
        _channelName(type),
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        priority: type == _ScheduledNotificationType.followUpAlarm
            ? Priority.max
            : Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: soundOption.androidSoundFor(soundRole),
        playSound: true,
        audioAttributesUsage: type == _ScheduledNotificationType.followUpAlarm
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: soundOption.iosFileNameFor(soundRole),
      ),
    );

    await _notificationsPlugin.zonedSchedule(
      id: _notificationId(task.id!, type),
      title: _titleFor(task, type),
      body: _bodyFor(task, type),
      scheduledDate: tz.TZDateTime.from(triggerAt, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: _matchDateTimeComponents(schedule.repeat),
      payload: 'task:${task.id}:${type.name}',
    );
  }

  Future<bool> _scheduleAndroidDeviceAlarm({
    required TaskModel task,
    required DateTime triggerAt,
    required NotificationSoundOption soundOption,
  }) async {
    try {
      final bool? scheduled = await _androidAlarmChannel
          .invokeMethod<bool>('scheduleDeviceAlarm', {
            'taskId': task.id,
            'title': _titleFor(task, _ScheduledNotificationType.followUpAlarm),
            'description': _bodyFor(
              task,
              _ScheduledNotificationType.followUpAlarm,
            ),
            'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
            'repeat':
                task.schedule?.repeat.storageValue ??
                ReminderRepeat.none.storageValue,
            'sound': soundOption.androidSoundTokenFor(
              NotificationSoundRole.alarm,
            ),
          });
      return scheduled ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (error, stackTrace) {
      debugPrint('Android device alarm scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _ensureAndroidChannel({
    required _ScheduledNotificationType type,
    required NotificationSoundOption soundOption,
  }) async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId(type, soundOption),
        _channelName(type),
        description: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        sound: soundOption.androidSoundFor(_soundRoleFor(type)),
        audioAttributesUsage: type == _ScheduledNotificationType.followUpAlarm
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
      ),
    );
  }

  Future<bool> _canScheduleExactNotifications() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  Future<NotificationSoundOption> _loadReminderSound() async {
    final String? storedValue = await _preferences.getString(
      AppConstants.reminderSoundKey,
    );
    final String? customPath = await _preferences.getString(
      AppConstants.reminderCustomSoundPathKey,
    );
    final String? customLabel = await _preferences.getString(
      AppConstants.reminderCustomSoundLabelKey,
    );

    return NotificationSoundOption.fromStorage(
      rawValue: storedValue,
      customPath: customPath,
      customLabel: customLabel,
    ).ensureUsableFor(NotificationSoundRole.reminder);
  }

  Future<NotificationSoundOption> _loadAlarmSound() async {
    final String? storedValue = await _preferences.getString(
      AppConstants.alarmSoundKey,
    );
    final String? customPath = await _preferences.getString(
      AppConstants.alarmCustomSoundPathKey,
    );
    final String? customLabel = await _preferences.getString(
      AppConstants.alarmCustomSoundLabelKey,
    );

    return NotificationSoundOption.fromStorage(
      rawValue: storedValue,
      customPath: customPath,
      customLabel: customLabel,
    ).ensureUsableFor(NotificationSoundRole.alarm);
  }

  DateTime? _nextTrigger(TaskModel task) {
    final TaskSchedule? schedule = task.schedule;
    if (schedule == null) {
      return null;
    }

    final DateTime now = DateTime.now();
    if (!task.isYudh) {
      switch (schedule.repeat) {
        case ReminderRepeat.none:
          return schedule.scheduledAt.isAfter(now)
              ? schedule.scheduledAt
              : null;
        case ReminderRepeat.daily:
          DateTime candidate = DateTime(
            now.year,
            now.month,
            now.day,
            schedule.scheduledAt.hour,
            schedule.scheduledAt.minute,
          );
          if (!candidate.isAfter(now)) {
            candidate = candidate.add(const Duration(days: 1));
          }
          return candidate;
        case ReminderRepeat.weekly:
          DateTime candidate = schedule.scheduledAt;
          while (!candidate.isAfter(now)) {
            candidate = candidate.add(const Duration(days: 7));
          }
          return candidate;
      }
    }

    final TaskOccurrenceWindow? current = task.currentYudhOccurrence(now);
    if (current == null) {
      return null;
    }

    if (task.wasCompletedInCurrentPeriod(now) ||
        !current.startAt.isAfter(now)) {
      return task
          .nextYudhOccurrence(current.endAt.add(const Duration(seconds: 1)))
          ?.startAt;
    }

    return current.startAt;
  }

  DateTimeComponents? _matchDateTimeComponents(ReminderRepeat repeat) {
    switch (repeat) {
      case ReminderRepeat.none:
        return null;
      case ReminderRepeat.daily:
        return DateTimeComponents.time;
      case ReminderRepeat.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
    }
  }

  int _notificationId(int taskId, _ScheduledNotificationType type) {
    return switch (type) {
      _ScheduledNotificationType.reminder => _reminderNotificationId(taskId),
      _ScheduledNotificationType.followUpAlarm => _followUpAlarmNotificationId(
        taskId,
      ),
    };
  }

  int _reminderNotificationId(int taskId) {
    return (taskId * 10) + AppConstants.reminderNotificationOffset;
  }

  int _followUpAlarmNotificationId(int taskId) {
    return (taskId * 10) + AppConstants.followUpAlarmNotificationOffset;
  }

  String _channelId(
    _ScheduledNotificationType type,
    NotificationSoundOption soundOption,
  ) {
    return 'simplify_${type.name}_${soundOption.channelKey}';
  }

  String _channelName(_ScheduledNotificationType type) {
    return switch (type) {
      _ScheduledNotificationType.reminder => 'Simplify Reminder',
      _ScheduledNotificationType.followUpAlarm => 'Simplify Alarm',
    };
  }

  NotificationSoundRole _soundRoleFor(_ScheduledNotificationType type) {
    return switch (type) {
      _ScheduledNotificationType.reminder => NotificationSoundRole.reminder,
      _ScheduledNotificationType.followUpAlarm => NotificationSoundRole.alarm,
    };
  }

  String _titleFor(TaskModel task, _ScheduledNotificationType type) {
    return switch (type) {
      _ScheduledNotificationType.reminder => task.title,
      _ScheduledNotificationType.followUpAlarm => 'Alarm: ${task.title}',
    };
  }

  String _bodyFor(TaskModel task, _ScheduledNotificationType type) {
    return switch (type) {
      _ScheduledNotificationType.reminder =>
        task.description.isEmpty
            ? 'Reminder for ${task.title}'
            : task.description,
      _ScheduledNotificationType.followUpAlarm =>
        'Five minutes later and this still needs your attention.',
    };
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Keep the package default when timezone lookup is unavailable.
    }
  }
}
