import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/utils/date_time_extensions.dart';

DateTime? _parseDate(String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  return DateTime.tryParse(rawValue);
}

int _parseInt(dynamic rawValue, {required int fallback}) {
  if (rawValue is int) {
    return rawValue;
  }

  if (rawValue is num) {
    return rawValue.toInt();
  }

  if (rawValue is String) {
    return int.tryParse(rawValue) ?? fallback;
  }

  return fallback;
}

String _cycleDateKey(DateTime date) {
  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _startOfWeek(DateTime date) =>
    date.startOfDay.subtract(Duration(days: date.weekday - 1));

bool _isSameWeek(DateTime left, DateTime right) {
  return _startOfWeek(left).isSameDate(_startOfWeek(right));
}

enum ReminderRepeat { none, daily, weekly }

extension ReminderRepeatX on ReminderRepeat {
  String get label {
    switch (this) {
      case ReminderRepeat.none:
        return 'One-time';
      case ReminderRepeat.daily:
        return 'Daily';
      case ReminderRepeat.weekly:
        return 'Weekly';
    }
  }

  String get storageValue {
    switch (this) {
      case ReminderRepeat.none:
        return 'none';
      case ReminderRepeat.daily:
        return 'daily';
      case ReminderRepeat.weekly:
        return 'weekly';
    }
  }

  static ReminderRepeat fromStorage(String? rawValue) {
    switch (rawValue) {
      case 'daily':
        return ReminderRepeat.daily;
      case 'weekly':
        return ReminderRepeat.weekly;
      default:
        return ReminderRepeat.none;
    }
  }
}

enum TaskKind { oneTime, yudh }

extension TaskKindX on TaskKind {
  String get label {
    switch (this) {
      case TaskKind.oneTime:
        return 'One-time';
      case TaskKind.yudh:
        return 'Yudh';
    }
  }

  String get storageValue {
    switch (this) {
      case TaskKind.oneTime:
        return 'one_time';
      case TaskKind.yudh:
        return 'yudh';
    }
  }

  static TaskKind fromStorage(String? rawValue) {
    switch (rawValue) {
      case 'yudh':
        return TaskKind.yudh;
      default:
        return TaskKind.oneTime;
    }
  }
}

enum TaskProgressStatus { completed, missed }

extension TaskProgressStatusX on TaskProgressStatus {
  String get label {
    switch (this) {
      case TaskProgressStatus.completed:
        return 'Completed';
      case TaskProgressStatus.missed:
        return 'Missed';
    }
  }

  String get storageValue {
    switch (this) {
      case TaskProgressStatus.completed:
        return 'completed';
      case TaskProgressStatus.missed:
        return 'missed';
    }
  }

  static TaskProgressStatus fromStorage(String? rawValue) {
    switch (rawValue) {
      case 'missed':
        return TaskProgressStatus.missed;
      default:
        return TaskProgressStatus.completed;
    }
  }
}

@immutable
class TaskSchedule {
  const TaskSchedule({
    required this.scheduledAt,
    this.repeat = ReminderRepeat.none,
    this.reminderEnabled = true,
    this.followUpAlarmEnabled = false,
    this.durationMinutes = 60,
  });

  final DateTime scheduledAt;
  final ReminderRepeat repeat;
  final bool reminderEnabled;
  final bool followUpAlarmEnabled;
  final int durationMinutes;

  Duration get duration => Duration(minutes: durationMinutes);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scheduledAt': scheduledAt.toIso8601String(),
      'repeat': repeat.storageValue,
      'reminderEnabled': reminderEnabled,
      'followUpAlarmEnabled': followUpAlarmEnabled,
      'durationMinutes': durationMinutes,
    };
  }

  String toStorage() => jsonEncode(toJson());

  factory TaskSchedule.fromStorage(String rawValue) {
    try {
      final dynamic decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return TaskSchedule.fromJson(decoded);
      }

      if (decoded is Map) {
        return TaskSchedule.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Legacy reminder payloads may only contain a raw ISO timestamp.
    }

    return TaskSchedule(scheduledAt: DateTime.parse(rawValue));
  }

  factory TaskSchedule.fromJson(Map<String, dynamic> json) {
    return TaskSchedule(
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      repeat: ReminderRepeatX.fromStorage(json['repeat'] as String?),
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      followUpAlarmEnabled: json['followUpAlarmEnabled'] as bool? ?? false,
      durationMinutes: _parseInt(
        json['durationMinutes'],
        fallback: (json['repeat'] as String?) == 'none' ? 60 : 120,
      ),
    );
  }

  TaskSchedule copyWith({
    DateTime? scheduledAt,
    ReminderRepeat? repeat,
    bool? reminderEnabled,
    bool? followUpAlarmEnabled,
    int? durationMinutes,
  }) {
    return TaskSchedule(
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeat: repeat ?? this.repeat,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      followUpAlarmEnabled: followUpAlarmEnabled ?? this.followUpAlarmEnabled,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

@immutable
class TaskChecklistItem {
  const TaskChecklistItem({required this.title, this.isCompleted = false});

  final String title;
  final bool isCompleted;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'isCompleted': isCompleted};
  }

  factory TaskChecklistItem.fromJson(Map<String, dynamic> json) {
    return TaskChecklistItem(
      title: (json['title'] as String? ?? '').trim(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  TaskChecklistItem copyWith({String? title, bool? isCompleted}) {
    return TaskChecklistItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@immutable
class TaskProgressLog {
  const TaskProgressLog({
    required this.cycleKey,
    required this.startAt,
    required this.endAt,
    required this.occurredAt,
    required this.status,
  });

  final String cycleKey;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime occurredAt;
  final TaskProgressStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cycleKey': cycleKey,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'occurredAt': occurredAt.toIso8601String(),
      'status': status.storageValue,
    };
  }

  factory TaskProgressLog.fromJson(Map<String, dynamic> json) {
    return TaskProgressLog(
      cycleKey: json['cycleKey'] as String? ?? '',
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      status: TaskProgressStatusX.fromStorage(json['status'] as String?),
    );
  }

  TaskProgressLog copyWith({
    String? cycleKey,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? occurredAt,
    TaskProgressStatus? status,
  }) {
    return TaskProgressLog(
      cycleKey: cycleKey ?? this.cycleKey,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      occurredAt: occurredAt ?? this.occurredAt,
      status: status ?? this.status,
    );
  }
}

@immutable
class TaskOccurrenceWindow {
  const TaskOccurrenceWindow({
    required this.cycleKey,
    required this.startAt,
    required this.endAt,
  });

  final String cycleKey;
  final DateTime startAt;
  final DateTime endAt;

  bool isSameDayAs(DateTime date) => startAt.isSameDate(date);
}

@immutable
class TaskPerformanceStats {
  const TaskPerformanceStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.completedCount,
    required this.missedCount,
    required this.score,
    required this.completionRate,
  });

  final int currentStreak;
  final int bestStreak;
  final int completedCount;
  final int missedCount;
  final int score;
  final double completionRate;
}

List<TaskChecklistItem> _decodeChecklist(String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return const <TaskChecklistItem>[];
  }

  try {
    final dynamic decoded = jsonDecode(rawValue);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                TaskChecklistItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.title.isNotEmpty)
          .toList(growable: false);
    }
  } catch (_) {
    // Ignore malformed legacy checklist payloads.
  }

  return const <TaskChecklistItem>[];
}

List<TaskProgressLog> _decodeProgressLogs(String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return const <TaskProgressLog>[];
  }

  try {
    final dynamic decoded = jsonDecode(rawValue);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => TaskProgressLog.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false)
        ..sort((left, right) => left.startAt.compareTo(right.startAt));
    }
  } catch (_) {
    // Ignore malformed legacy progress payloads.
  }

  return const <TaskProgressLog>[];
}

@immutable
class TaskModel {
  const TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.dueDate,
    required this.schedule,
    required this.createdAt,
    this.kind = TaskKind.oneTime,
    this.subtasks = const <TaskChecklistItem>[],
    this.progressLogs = const <TaskProgressLog>[],
  });

  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TaskSchedule? schedule;
  final DateTime createdAt;
  final TaskKind kind;
  final List<TaskChecklistItem> subtasks;
  final List<TaskProgressLog> progressLogs;

  bool get isYudh => kind == TaskKind.yudh;

  bool get isAnytimeTask => !isYudh && dueDate == null && schedule == null;

  DateTime? get timelineDate {
    if (isYudh) {
      return nextYudhOccurrence()?.startAt;
    }

    final DateTime? scheduleAt = nextReminderOccurrence;

    if (dueDate == null) {
      return scheduleAt;
    }

    if (scheduleAt == null) {
      return dueDate;
    }

    return scheduleAt.isBefore(dueDate!) ? scheduleAt : dueDate;
  }

  DateTime? get nextReminderOccurrence {
    final TaskSchedule? currentSchedule = schedule;
    if (currentSchedule == null) {
      return null;
    }

    final DateTime now = DateTime.now();

    switch (currentSchedule.repeat) {
      case ReminderRepeat.none:
        return currentSchedule.scheduledAt;
      case ReminderRepeat.daily:
        DateTime candidate = DateTime(
          now.year,
          now.month,
          now.day,
          currentSchedule.scheduledAt.hour,
          currentSchedule.scheduledAt.minute,
        );
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case ReminderRepeat.weekly:
        DateTime candidate = currentSchedule.scheduledAt;
        while (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
    }
  }

  bool isCompletedFor(DateTime now) {
    if (!isYudh) {
      return isCompleted;
    }

    final TaskOccurrenceWindow? current = currentYudhOccurrence(now);
    if (current == null) {
      return false;
    }

    return progressForCycle(current.cycleKey)?.status ==
        TaskProgressStatus.completed;
  }

  bool isMissedFor(DateTime now) {
    if (!isYudh) {
      return false;
    }

    final TaskOccurrenceWindow? current = currentYudhOccurrence(now);
    if (current == null) {
      return false;
    }

    final TaskProgressLog? log = progressForCycle(current.cycleKey);
    if (log != null) {
      return log.status == TaskProgressStatus.missed;
    }

    return current.endAt.isBefore(now);
  }

  bool get isOverdue {
    if (isYudh || isCompleted) {
      return false;
    }

    final DateTime now = DateTime.now();
    if (dueDate != null) {
      return dueDate!.isBefore(now);
    }

    if (schedule == null) {
      return false;
    }

    return schedule!.repeat == ReminderRepeat.none &&
        schedule!.scheduledAt.isBefore(now);
  }

  TaskProgressLog? progressForCycle(String cycleKey) {
    for (final TaskProgressLog log in progressLogs) {
      if (log.cycleKey == cycleKey) {
        return log;
      }
    }

    return null;
  }

  TaskOccurrenceWindow? currentYudhOccurrence([DateTime? reference]) {
    if (!isYudh || schedule == null) {
      return null;
    }

    final DateTime now = reference ?? DateTime.now();
    return switch (schedule!.repeat) {
      ReminderRepeat.daily => _dailyOccurrenceFor(now),
      ReminderRepeat.weekly => _weeklyOccurrenceFor(now),
      ReminderRepeat.none => TaskOccurrenceWindow(
        cycleKey: 'once:${_cycleDateKey(schedule!.scheduledAt)}',
        startAt: schedule!.scheduledAt,
        endAt: schedule!.scheduledAt.add(schedule!.duration),
      ),
    };
  }

  TaskOccurrenceWindow? nextYudhOccurrence([DateTime? reference]) {
    if (!isYudh || schedule == null) {
      return null;
    }

    final DateTime now = reference ?? DateTime.now();
    final TaskOccurrenceWindow? current = currentYudhOccurrence(now);
    if (current == null) {
      return null;
    }

    if (!current.endAt.isBefore(now)) {
      return current;
    }

    return switch (schedule!.repeat) {
      ReminderRepeat.daily => _occurrenceWindowFor(
        current.startAt.add(const Duration(days: 1)),
      ),
      ReminderRepeat.weekly => _occurrenceWindowFor(
        current.startAt.add(const Duration(days: 7)),
      ),
      ReminderRepeat.none => null,
    };
  }

  bool shouldAppearInYudhToday(DateTime now) {
    if (!isYudh || schedule == null) {
      return false;
    }

    final TaskOccurrenceWindow? current = currentYudhOccurrence(now);
    if (current == null) {
      return false;
    }

    switch (schedule!.repeat) {
      case ReminderRepeat.daily:
        return true;
      case ReminderRepeat.weekly:
        return current.startAt.isSameDate(now) || current.startAt.isBefore(now);
      case ReminderRepeat.none:
        return current.startAt.isSameDate(now);
    }
  }

  bool shouldAppearInYudhUpcoming(DateTime now) {
    if (!isYudh || schedule == null) {
      return false;
    }

    final TaskOccurrenceWindow? current = currentYudhOccurrence(now);
    if (current == null) {
      return false;
    }

    switch (schedule!.repeat) {
      case ReminderRepeat.daily:
        return false;
      case ReminderRepeat.weekly:
        return current.startAt.isAfter(now) && !current.startAt.isSameDate(now);
      case ReminderRepeat.none:
        return current.startAt.isAfter(now) && !current.startAt.isSameDate(now);
    }
  }

  bool wasCompletedInCurrentPeriod(DateTime now) {
    if (!isYudh) {
      return isCompleted;
    }

    if (schedule == null) {
      return false;
    }

    return progressLogs.any((log) {
      if (log.status != TaskProgressStatus.completed) {
        return false;
      }

      return switch (schedule!.repeat) {
        ReminderRepeat.daily => log.startAt.isSameDate(now),
        ReminderRepeat.weekly => _isSameWeek(log.startAt, now),
        ReminderRepeat.none => log.startAt.isSameDate(now),
      };
    });
  }

  TaskPerformanceStats performanceStats() {
    if (!isYudh) {
      return const TaskPerformanceStats(
        currentStreak: 0,
        bestStreak: 0,
        completedCount: 0,
        missedCount: 0,
        score: 0,
        completionRate: 0,
      );
    }

    final List<TaskProgressLog> sortedLogs = List<TaskProgressLog>.from(
      progressLogs,
    )..sort((left, right) => left.startAt.compareTo(right.startAt));

    int currentStreak = 0;
    int bestStreak = 0;
    int runningStreak = 0;
    int completedCount = 0;
    int missedCount = 0;

    for (final TaskProgressLog log in sortedLogs) {
      if (log.status == TaskProgressStatus.completed) {
        completedCount += 1;
        runningStreak += 1;
        if (runningStreak > bestStreak) {
          bestStreak = runningStreak;
        }
      } else {
        missedCount += 1;
        runningStreak = 0;
      }
    }

    for (final TaskProgressLog log in sortedLogs.reversed) {
      if (log.status == TaskProgressStatus.completed) {
        currentStreak += 1;
      } else {
        break;
      }
    }

    final int totalSessions = completedCount + missedCount;
    final double completionRate = totalSessions == 0
        ? 0
        : completedCount / totalSessions;
    final int score = (completedCount * 10) - (missedCount * 4);

    return TaskPerformanceStats(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completedCount: completedCount,
      missedCount: missedCount,
      score: score,
      completionRate: completionRate,
    );
  }

  TaskModel normalizedForNow([DateTime? reference]) {
    if (!isYudh || schedule == null) {
      return this;
    }

    final DateTime now = reference ?? DateTime.now();
    final Map<String, TaskProgressLog> logsByKey = <String, TaskProgressLog>{
      for (final TaskProgressLog log in progressLogs) log.cycleKey: log,
    };

    for (final TaskOccurrenceWindow occurrence in expectedYudhOccurrencesUntil(
      now,
    )) {
      if (occurrence.endAt.isAfter(now)) {
        continue;
      }

      logsByKey.putIfAbsent(
        occurrence.cycleKey,
        () => TaskProgressLog(
          cycleKey: occurrence.cycleKey,
          startAt: occurrence.startAt,
          endAt: occurrence.endAt,
          occurredAt: occurrence.endAt,
          status: TaskProgressStatus.missed,
        ),
      );
    }

    final List<TaskProgressLog> normalizedLogs = logsByKey.values.toList(
      growable: false,
    )..sort((left, right) => left.startAt.compareTo(right.startAt));

    if (listEquals(normalizedLogs, progressLogs)) {
      return this;
    }

    return copyWith(progressLogs: normalizedLogs);
  }

  List<TaskOccurrenceWindow> expectedYudhOccurrencesUntil(DateTime now) {
    if (!isYudh || schedule == null) {
      return const <TaskOccurrenceWindow>[];
    }

    final List<TaskOccurrenceWindow> occurrences = <TaskOccurrenceWindow>[];
    DateTime cursor = schedule!.scheduledAt;
    final Duration? step = switch (schedule!.repeat) {
      ReminderRepeat.daily => const Duration(days: 1),
      ReminderRepeat.weekly => const Duration(days: 7),
      ReminderRepeat.none => null,
    };

    while (!cursor.isAfter(now)) {
      occurrences.add(_occurrenceWindowFor(cursor));
      if (step == null) {
        break;
      }
      cursor = cursor.add(step);
    }

    return occurrences;
  }

  TaskModel toggleForNow([DateTime? reference]) {
    final DateTime now = reference ?? DateTime.now();

    if (!isYudh) {
      return copyWith(isCompleted: !isCompleted);
    }

    final TaskOccurrenceWindow? current = currentYudhOccurrence(now);
    if (current == null) {
      return this;
    }

    final TaskProgressLog? existing = progressForCycle(current.cycleKey);
    if (existing?.status == TaskProgressStatus.missed &&
        current.endAt.isBefore(now)) {
      return this;
    }

    final List<TaskProgressLog> updatedLogs = List<TaskProgressLog>.from(
      progressLogs,
    )..removeWhere((log) => log.cycleKey == current.cycleKey);

    if (existing?.status != TaskProgressStatus.completed) {
      updatedLogs.add(
        TaskProgressLog(
          cycleKey: current.cycleKey,
          startAt: current.startAt,
          endAt: current.endAt,
          occurredAt: now,
          status: TaskProgressStatus.completed,
        ),
      );
      updatedLogs.sort((left, right) => left.startAt.compareTo(right.startAt));
    }

    return copyWith(progressLogs: updatedLogs);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title.trim(),
      'description': description.trim(),
      'isCompleted': isCompleted ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': schedule?.toStorage(),
      'createdAt': createdAt.toIso8601String(),
      'taskKind': kind.storageValue,
      'subtasksData': jsonEncode(
        subtasks.map((item) => item.toJson()).toList(growable: false),
      ),
      'progressLogData': jsonEncode(
        progressLogs.map((log) => log.toJson()).toList(growable: false),
      ),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final String? scheduleValue = map['reminderTime'] as String?;
    final TaskSchedule? schedule =
        scheduleValue == null || scheduleValue.isEmpty
        ? null
        : TaskSchedule.fromStorage(scheduleValue);

    final TaskKind inferredKind;
    final String? rawKind = map['taskKind'] as String?;
    if (rawKind == null || rawKind.isEmpty) {
      inferredKind = schedule != null && schedule.repeat != ReminderRepeat.none
          ? TaskKind.yudh
          : TaskKind.oneTime;
    } else {
      inferredKind = TaskKindX.fromStorage(rawKind);
    }

    return TaskModel(
      id: map['id'] as int?,
      title: (map['title'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      dueDate: _parseDate(map['dueDate'] as String?),
      schedule: schedule,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      kind: inferredKind,
      subtasks: _decodeChecklist(map['subtasksData'] as String?),
      progressLogs: _decodeProgressLogs(map['progressLogData'] as String?),
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskSchedule? schedule,
    bool clearSchedule = false,
    DateTime? createdAt,
    TaskKind? kind,
    List<TaskChecklistItem>? subtasks,
    List<TaskProgressLog>? progressLogs,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      schedule: clearSchedule ? null : schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      subtasks: subtasks ?? this.subtasks,
      progressLogs: progressLogs ?? this.progressLogs,
    );
  }

  TaskOccurrenceWindow _dailyOccurrenceFor(DateTime reference) {
    final DateTime startAt = DateTime(
      reference.year,
      reference.month,
      reference.day,
      schedule!.scheduledAt.hour,
      schedule!.scheduledAt.minute,
    );

    return _occurrenceWindowFor(startAt);
  }

  TaskOccurrenceWindow _weeklyOccurrenceFor(DateTime reference) {
    final int weekdayDelta = schedule!.scheduledAt.weekday - reference.weekday;
    final DateTime startAt = DateTime(
      reference.year,
      reference.month,
      reference.day,
      schedule!.scheduledAt.hour,
      schedule!.scheduledAt.minute,
    ).add(Duration(days: weekdayDelta));

    return _occurrenceWindowFor(startAt);
  }

  TaskOccurrenceWindow _occurrenceWindowFor(DateTime startAt) {
    final String prefix = switch (schedule!.repeat) {
      ReminderRepeat.daily => 'daily',
      ReminderRepeat.weekly => 'weekly',
      ReminderRepeat.none => 'once',
    };

    return TaskOccurrenceWindow(
      cycleKey: '$prefix:${_cycleDateKey(startAt)}',
      startAt: startAt,
      endAt: startAt.add(schedule!.duration),
    );
  }
}
