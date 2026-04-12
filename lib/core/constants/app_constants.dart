abstract final class AppConstants {
  static const String appName = 'Simplify';
  static const String databaseName = 'simplify_tasks.db';
  static const String taskTableName = 'tasks';
  static const String themeModeKey = 'theme_mode';
  static const String reminderSoundKey = 'reminder_sound';
  static const String alarmSoundKey = 'alarm_sound';
  static const String reminderCustomSoundPathKey = 'reminder_custom_sound_path';
  static const String reminderCustomSoundLabelKey =
      'reminder_custom_sound_label';
  static const String alarmCustomSoundPathKey = 'alarm_custom_sound_path';
  static const String alarmCustomSoundLabelKey = 'alarm_custom_sound_label';
  static const String customSoundFolderName = 'notification_sounds';
  static const String exportedReportFolderName = 'yudh_reports';
  static const String lightLogoAsset =
      'lib/assets/images/Simplify_light_theme_app_logo.png';
  static const String darkLogoAsset =
      'lib/assets/images/Simplify_dark_theme_app_logo.png';
  static const String lightAppIconAsset =
      'lib/assets/images/Simplify_light_theme_app_icon.png';
  static const String darkAppIconAsset =
      'lib/assets/images/Simplify_dark_theme_app_icon.png';

  static const String notificationChannelName = 'Task Reminders';
  static const String notificationChannelDescription =
      'Offline reminders that help you stay on top of your plans.';
  static const String androidAlarmMethodChannel = 'simplify/device_alarm';
  static const int reminderNotificationOffset = 1;
  static const int followUpAlarmNotificationOffset = 2;
  static const int followUpAlarmDelayMinutes = 5;
  static const int defaultYudhDurationMinutes = 120;

  static const int splashDurationMs = 1800;
  static const Duration animationDuration = Duration(milliseconds: 260);
}
