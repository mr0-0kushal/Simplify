import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:simplify/data/database/db_helper.dart';
import 'package:simplify/data/models/task_model.dart';
import 'package:simplify/data/repositories/task_repository.dart';
import 'package:simplify/features/tasks/providers/task_provider.dart';
import 'package:simplify/services/notification_service.dart';

final class _InMemorySharedPreferencesAsyncPlatform
    extends SharedPreferencesAsyncPlatform {
  final Map<String, Object> _store = <String, Object>{};

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final Set<String>? allowList = parameters.filter.allowList;
    if (allowList == null) {
      _store.clear();
      return;
    }

    _store.removeWhere((key, _) => allowList.contains(key));
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async =>
      _store[key] as bool?;

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesOptions options,
  ) async => _store[key] as double?;

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async =>
      _store[key] as int?;

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final Set<String>? allowList = parameters.filter.allowList;
    if (allowList == null) {
      return Map<String, Object>.from(_store);
    }

    return Map<String, Object>.fromEntries(
      _store.entries.where((entry) => allowList.contains(entry.key)),
    );
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final Set<String>? allowList = parameters.filter.allowList;
    if (allowList == null) {
      return _store.keys.toSet();
    }

    return _store.keys.where(allowList.contains).toSet();
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async => _store[key] as String?;

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async => (_store[key] as List<Object?>?)?.cast<String>().toList();

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setInt(
    String key,
    int value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = List<String>.from(value);
  }
}

class _FakeTaskRepository extends TaskRepository {
  _FakeTaskRepository(List<TaskModel> seedTasks)
    : _tasks = List<TaskModel>.from(seedTasks),
      super(dbHelper: DbHelper.instance);

  final List<TaskModel> _tasks;

  @override
  Future<List<TaskModel>> fetchTasks() async =>
      List<TaskModel>.from(_tasks, growable: false);

  @override
  Future<TaskModel> insertTask(TaskModel task) async {
    final TaskModel savedTask = task.copyWith(id: _tasks.length + 1);
    _tasks.add(savedTask);
    return savedTask;
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final int index = _tasks.indexWhere((item) => item.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id);
  }
}

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> scheduleTaskNotifications(TaskModel task) async {}

  @override
  Future<void> cancelTaskNotifications(int taskId) async {}

  @override
  Future<void> rescheduleActiveTaskNotifications(
    Iterable<TaskModel> tasks,
  ) async {}
}

TaskModel _task({
  required int id,
  required String title,
  DateTime? dueDate,
  TaskSchedule? schedule,
  TaskKind kind = TaskKind.oneTime,
  List<TaskProgressLog> progressLogs = const <TaskProgressLog>[],
}) {
  return TaskModel(
    id: id,
    title: title,
    description: '',
    isCompleted: false,
    dueDate: dueDate,
    schedule: schedule,
    createdAt: DateTime(2026, 1, 1, 9),
    kind: kind,
    progressLogs: progressLogs,
  );
}

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('TaskProvider filters', () {
    test('day-to-day tasks stay visible in Today', () async {
      final provider = TaskProvider(
        repository: _FakeTaskRepository([_task(id: 1, title: 'Flexible task')]),
        notificationService: _FakeNotificationService(),
      );

      await provider.loadTasks();

      expect(provider.todayCount, 1);
      expect(provider.upcomingCount, 0);
    });

    test('tasks later today stay in Today and not Upcoming', () async {
      final DateTime now = DateTime.now();
      final DateTime endOfToday = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      );

      final provider = TaskProvider(
        repository: _FakeTaskRepository([
          _task(id: 2, title: 'Tonight task', dueDate: endOfToday),
        ]),
        notificationService: _FakeNotificationService(),
      );

      await provider.loadTasks();

      expect(provider.todayCount, 1);
      expect(provider.upcomingCount, 0);
    });

    test('overdue tasks remain visible in Today', () async {
      final DateTime now = DateTime.now();
      final DateTime yesterday = now.subtract(const Duration(days: 1));

      final provider = TaskProvider(
        repository: _FakeTaskRepository([
          _task(id: 3, title: 'Missed task', dueDate: yesterday),
        ]),
        notificationService: _FakeNotificationService(),
      );

      await provider.loadTasks();

      expect(provider.todayCount, 1);
      expect(provider.upcomingCount, 0);
    });

    test('weekly Yudh blocks stay active across weekly boundaries', () async {
      final DateTime now = DateTime.now();
      final int targetWeekday = (now.weekday % DateTime.daysPerWeek) + 1;
      final int daysUntilNextWeekday =
          (targetWeekday - now.weekday + DateTime.daysPerWeek) %
          DateTime.daysPerWeek;
      final bool wrapsToNextCycle = targetWeekday <= now.weekday;
      final DateTime nextSlot = DateTime(now.year, now.month, now.day, 8).add(
        Duration(days: daysUntilNextWeekday == 0 ? 7 : daysUntilNextWeekday),
      );

      final provider = TaskProvider(
        repository: _FakeTaskRepository([
          _task(
            id: 4,
            title: 'Biology block',
            kind: TaskKind.yudh,
            schedule: TaskSchedule(
              scheduledAt: nextSlot,
              repeat: ReminderRepeat.weekly,
              durationMinutes: 120,
            ),
          ),
        ]),
        notificationService: _FakeNotificationService(),
      );

      await provider.loadTasks();

      expect(provider.todayCount, wrapsToNextCycle ? 1 : 0);
      expect(provider.upcomingCount, wrapsToNextCycle ? 0 : 1);
    });

    test('completed daily Yudh blocks move to Completed', () async {
      final DateTime now = DateTime.now();
      final DateTime slotStart = DateTime(now.year, now.month, now.day, 8);

      final provider = TaskProvider(
        repository: _FakeTaskRepository([
          _task(
            id: 5,
            title: 'Maths revision',
            kind: TaskKind.yudh,
            schedule: TaskSchedule(
              scheduledAt: slotStart,
              repeat: ReminderRepeat.daily,
              durationMinutes: 120,
            ),
            progressLogs: [
              TaskProgressLog(
                cycleKey:
                    'daily:${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                startAt: slotStart,
                endAt: slotStart.add(const Duration(minutes: 120)),
                occurredAt: slotStart.add(const Duration(minutes: 30)),
                status: TaskProgressStatus.completed,
              ),
            ],
          ),
        ]),
        notificationService: _FakeNotificationService(),
      );

      await provider.loadTasks();

      expect(provider.todayCount, 0);
      expect(provider.completedCount, 1);
    });
  });
}
