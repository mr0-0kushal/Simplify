import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/database/db_helper.dart';
import 'data/repositories/task_repository.dart';
import 'features/tasks/providers/notification_preferences_provider.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/tasks/providers/theme_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  final notificationPreferencesProvider = NotificationPreferencesProvider();
  await notificationPreferencesProvider.load();

  final taskProvider = TaskProvider(
    repository: TaskRepository(dbHelper: DbHelper.instance),
    notificationService: notificationService,
  );
  await taskProvider.loadTasks();

  runApp(
    SimplifyApp(
      appName: AppConstants.appName,
      taskProvider: taskProvider,
      themeProvider: themeProvider,
      notificationPreferencesProvider: notificationPreferencesProvider,
    ),
  );
}
