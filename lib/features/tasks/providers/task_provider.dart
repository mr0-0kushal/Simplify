import 'package:flutter/foundation.dart';

import '../../../core/utils/date_time_extensions.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/notification_service.dart';

enum TaskFilter { today, upcoming, completed }

extension TaskFilterX on TaskFilter {
  String get label {
    switch (this) {
      case TaskFilter.today:
        return 'Today';
      case TaskFilter.upcoming:
        return 'Upcoming';
      case TaskFilter.completed:
        return 'Completed';
    }
  }

  String get emptyTitle {
    switch (this) {
      case TaskFilter.today:
        return 'Your board is calm';
      case TaskFilter.upcoming:
        return 'Nothing queued next';
      case TaskFilter.completed:
        return 'No wins logged yet';
    }
  }

  String get emptySubtitle {
    switch (this) {
      case TaskFilter.today:
        return 'One-time tasks and today\'s Yudh blocks will appear here.';
      case TaskFilter.upcoming:
        return 'Future one-time plans and later Yudh sessions land here.';
      case TaskFilter.completed:
        return 'Finished one-time tasks and this period\'s Yudh wins show up here.';
    }
  }
}

@immutable
class YudhReportSummary {
  const YudhReportSummary({
    required this.taskCount,
    required this.completedSessions,
    required this.missedSessions,
    required this.score,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
  });

  final int taskCount;
  final int completedSessions;
  final int missedSessions;
  final int score;
  final int currentStreak;
  final int bestStreak;
  final double completionRate;
}

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required TaskRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService;

  final TaskRepository _repository;
  final NotificationService _notificationService;

  List<TaskModel> _tasks = <TaskModel>[];
  TaskFilter _selectedFilter = TaskFilter.today;
  bool _isLoading = false;
  bool _notificationsReady = false;

  List<TaskModel> get tasks => List<TaskModel>.unmodifiable(_tasks);
  TaskFilter get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  bool get hasTasks => _tasks.isNotEmpty;

  int get totalCount => _tasks.length;
  int get completedCount => _filteredTasks(TaskFilter.completed).length;
  int get activeCount => _tasks.where((task) => !_isTaskCompleted(task)).length;

  int get todayCount => _filteredTasks(TaskFilter.today).length;
  int get upcomingCount => _filteredTasks(TaskFilter.upcoming).length;
  int get yudhCount => _tasks.where((task) => task.isYudh).length;

  List<TaskModel> get visibleTasks => _filteredTasks(_selectedFilter);

  List<TaskModel> get visibleOneTimeTasks =>
      visibleTasks.where((task) => !task.isYudh).toList(growable: false);

  List<TaskModel> get visibleYudhTasks =>
      visibleTasks.where((task) => task.isYudh).toList(growable: false);

  List<TaskModel> get yudhTasks =>
      _tasks.where((task) => task.isYudh).toList(growable: false)
        ..sort((left, right) => _sortTasks(left, right));

  double get completionProgress {
    if (_tasks.isEmpty) {
      return 0;
    }

    return completedCount / _tasks.length;
  }

  TaskModel? get nextTask {
    final DateTime now = DateTime.now();
    final List<TaskModel> candidates =
        _tasks
            .where((task) => !_isTaskCompleted(task, reference: now))
            .toList(growable: false)
          ..sort(_sortTasks);

    return candidates.isEmpty ? null : candidates.first;
  }

  YudhReportSummary get yudhReport {
    int completedSessions = 0;
    int missedSessions = 0;
    int score = 0;
    int currentStreak = 0;
    int bestStreak = 0;

    for (final TaskModel task in yudhTasks) {
      final TaskPerformanceStats stats = task.performanceStats();
      completedSessions += stats.completedCount;
      missedSessions += stats.missedCount;
      score += stats.score;
      currentStreak += stats.currentStreak;
      if (stats.bestStreak > bestStreak) {
        bestStreak = stats.bestStreak;
      }
    }

    final int totalSessions = completedSessions + missedSessions;
    final double completionRate = totalSessions == 0
        ? 0
        : completedSessions / totalSessions;

    return YudhReportSummary(
      taskCount: yudhCount,
      completedSessions: completedSessions,
      missedSessions: missedSessions,
      score: score,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completionRate: completionRate,
    );
  }

  Future<void> initializeNotifications() async {
    if (_notificationsReady) {
      return;
    }

    try {
      await _notificationService.requestPermissions();
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    _notificationsReady = true;
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<TaskModel> storedTasks = await _repository.fetchTasks();
      final List<TaskModel> normalizedTasks = await _normalizeTasks(
        storedTasks,
      );
      normalizedTasks.sort(_sortTasks);
      _tasks = normalizedTasks;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upsertTask(TaskModel task) async {
    final TaskModel normalizedTask = task.normalizedForNow();
    final TaskModel savedTask;

    if (normalizedTask.id == null) {
      savedTask = await _repository.insertTask(normalizedTask);
    } else {
      await _repository.updateTask(normalizedTask);
      savedTask = normalizedTask;
    }

    if (savedTask.id != null) {
      await _syncTaskNotifications(savedTask);
    }

    await loadTasks();
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    final TaskModel updatedTask = task.toggleForNow().normalizedForNow();

    if (updatedTask.id == null) {
      return;
    }

    await _repository.updateTask(updatedTask);

    if (updatedTask.isYudh) {
      await _syncTaskNotifications(updatedTask);
    } else if (updatedTask.isCompleted) {
      await _safeCancelNotifications(updatedTask.id!);
    } else {
      await _syncTaskNotifications(updatedTask);
    }

    await loadTasks();
  }

  Future<void> deleteTask(TaskModel task) async {
    if (task.id == null) {
      return;
    }

    await _safeCancelNotifications(task.id!);
    await _repository.deleteTask(task.id!);
    await loadTasks();
  }

  Future<void> rescheduleActiveNotifications() async {
    try {
      await _notificationService.rescheduleActiveTaskNotifications(_tasks);
    } catch (error, stackTrace) {
      debugPrint('Failed to reschedule active notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void updateFilter(TaskFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    _selectedFilter = filter;
    notifyListeners();
  }

  TaskOccurrenceWindow? currentOccurrenceFor(TaskModel task) {
    return task.currentYudhOccurrence(DateTime.now());
  }

  DateTime? nextFocusTimeFor(TaskModel task) {
    final DateTime now = DateTime.now();

    if (!task.isYudh) {
      return task.timelineDate;
    }

    final TaskOccurrenceWindow? current = task.currentYudhOccurrence(now);
    if (current == null) {
      return null;
    }

    if (task.wasCompletedInCurrentPeriod(now)) {
      return task
          .nextYudhOccurrence(current.endAt.add(const Duration(seconds: 1)))
          ?.startAt;
    }

    return current.startAt;
  }

  List<TaskModel> _filteredTasks(TaskFilter filter) {
    final DateTime now = DateTime.now();

    switch (filter) {
      case TaskFilter.today:
        return _tasks
            .where((task) => _belongsToToday(task, now))
            .toList(growable: false)
          ..sort(_sortTasks);
      case TaskFilter.upcoming:
        return _tasks
            .where((task) => _belongsToUpcoming(task, now))
            .toList(growable: false)
          ..sort(_sortTasks);
      case TaskFilter.completed:
        return _tasks
            .where((task) => _belongsToCompleted(task, now))
            .toList(growable: false)
          ..sort(_sortTasks);
    }
  }

  bool _belongsToToday(TaskModel task, DateTime now) {
    if (task.isYudh) {
      return !_belongsToCompleted(task, now) &&
          task.shouldAppearInYudhToday(now);
    }

    if (task.isCompleted) {
      return false;
    }

    final List<DateTime> references = _timelineReferences(task);
    if (references.isEmpty) {
      return true;
    }

    return references.any((reference) => !reference.isAfter(now.endOfDay));
  }

  bool _belongsToUpcoming(TaskModel task, DateTime now) {
    if (task.isYudh) {
      return !_belongsToCompleted(task, now) &&
          task.shouldAppearInYudhUpcoming(now);
    }

    if (task.isCompleted) {
      return false;
    }

    return _timelineReferences(
      task,
    ).any((reference) => reference.isAfter(now.endOfDay));
  }

  bool _belongsToCompleted(TaskModel task, DateTime now) {
    if (task.isYudh) {
      return task.wasCompletedInCurrentPeriod(now);
    }

    return task.isCompleted;
  }

  int _sortTasks(TaskModel left, TaskModel right) {
    final DateTime now = DateTime.now();
    final bool leftCompleted = _isTaskCompleted(left, reference: now);
    final bool rightCompleted = _isTaskCompleted(right, reference: now);

    if (leftCompleted != rightCompleted) {
      return leftCompleted ? 1 : -1;
    }

    final DateTime? leftDate = nextFocusTimeFor(left);
    final DateTime? rightDate = nextFocusTimeFor(right);

    if (leftDate == null && rightDate != null) {
      return 1;
    }

    if (leftDate != null && rightDate == null) {
      return -1;
    }

    if (leftDate != null && rightDate != null) {
      final int comparison = leftDate.compareTo(rightDate);
      if (comparison != 0) {
        return comparison;
      }
    }

    return right.createdAt.compareTo(left.createdAt);
  }

  bool _isTaskCompleted(TaskModel task, {DateTime? reference}) {
    return task.isCompletedFor(reference ?? DateTime.now());
  }

  Future<List<TaskModel>> _normalizeTasks(List<TaskModel> tasks) async {
    final DateTime now = DateTime.now();
    final List<TaskModel> normalized = <TaskModel>[];

    for (final TaskModel task in tasks) {
      final TaskModel updatedTask = task.normalizedForNow(now);
      if (_needsPersistence(task, updatedTask) && updatedTask.id != null) {
        await _repository.updateTask(updatedTask);
      }
      normalized.add(updatedTask);
    }

    return normalized;
  }

  bool _needsPersistence(TaskModel original, TaskModel updated) {
    if (!identical(original, updated) &&
        original.progressLogs.length != updated.progressLogs.length) {
      return true;
    }

    if (original.progressLogs.length != updated.progressLogs.length) {
      return true;
    }

    for (int index = 0; index < original.progressLogs.length; index += 1) {
      if (original.progressLogs[index].cycleKey !=
              updated.progressLogs[index].cycleKey ||
          original.progressLogs[index].status !=
              updated.progressLogs[index].status) {
        return true;
      }
    }

    return false;
  }

  Future<void> _syncTaskNotifications(TaskModel task) async {
    try {
      await _notificationService.scheduleTaskNotifications(task);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to schedule notifications for task ${task.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _safeCancelNotifications(int taskId) async {
    try {
      await _notificationService.cancelTaskNotifications(taskId);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel notifications for task $taskId: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<DateTime> _timelineReferences(TaskModel task) {
    return <DateTime?>[
      task.dueDate,
      task.nextReminderOccurrence,
    ].whereType<DateTime>().toList(growable: false);
  }
}
