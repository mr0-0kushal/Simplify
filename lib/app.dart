import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/tasks/providers/notification_preferences_provider.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/tasks/providers/theme_provider.dart';
import 'features/tasks/screens/splash_screen.dart';

class SimplifyApp extends StatelessWidget {
  const SimplifyApp({
    super.key,
    required this.appName,
    required this.taskProvider,
    required this.themeProvider,
    required this.notificationPreferencesProvider,
  });

  final String appName;
  final TaskProvider taskProvider;
  final ThemeProvider themeProvider;
  final NotificationPreferencesProvider notificationPreferencesProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<NotificationPreferencesProvider>.value(
          value: notificationPreferencesProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
