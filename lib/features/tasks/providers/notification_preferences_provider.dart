import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/notification_sound_option.dart';

class NotificationPreferencesProvider extends ChangeNotifier {
  NotificationPreferencesProvider({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  NotificationSoundOption _reminderSound =
      const NotificationSoundOption.appDefault();
  NotificationSoundOption _alarmSound =
      const NotificationSoundOption.appDefault();

  NotificationSoundOption get reminderSound => _reminderSound;
  NotificationSoundOption get alarmSound => _alarmSound;

  Future<void> load() async {
    _reminderSound = await _loadSound(
      soundKey: AppConstants.reminderSoundKey,
      pathKey: AppConstants.reminderCustomSoundPathKey,
      labelKey: AppConstants.reminderCustomSoundLabelKey,
    );
    _alarmSound = await _loadSound(
      soundKey: AppConstants.alarmSoundKey,
      pathKey: AppConstants.alarmCustomSoundPathKey,
      labelKey: AppConstants.alarmCustomSoundLabelKey,
    );

    notifyListeners();
  }

  Future<void> updateReminderSound(NotificationSoundOption option) async {
    _reminderSound = option.ensureUsableFor(NotificationSoundRole.reminder);
    await _preferences.setString(
      AppConstants.reminderSoundKey,
      _reminderSound.storageValue,
    );
    notifyListeners();
  }

  Future<void> updateAlarmSound(NotificationSoundOption option) async {
    _alarmSound = option.ensureUsableFor(NotificationSoundRole.alarm);
    await _preferences.setString(
      AppConstants.alarmSoundKey,
      _alarmSound.storageValue,
    );
    notifyListeners();
  }

  Future<NotificationSoundOption?> pickCustomReminderSound() async {
    final NotificationSoundOption? sound = await _pickCustomSound(
      role: 'reminder',
      soundKey: AppConstants.reminderSoundKey,
      pathKey: AppConstants.reminderCustomSoundPathKey,
      labelKey: AppConstants.reminderCustomSoundLabelKey,
    );

    if (sound != null) {
      _reminderSound = sound;
      notifyListeners();
    }

    return sound;
  }

  Future<NotificationSoundOption?> pickCustomAlarmSound() async {
    final NotificationSoundOption? sound = await _pickCustomSound(
      role: 'alarm',
      soundKey: AppConstants.alarmSoundKey,
      pathKey: AppConstants.alarmCustomSoundPathKey,
      labelKey: AppConstants.alarmCustomSoundLabelKey,
    );

    if (sound != null) {
      _alarmSound = sound;
      notifyListeners();
    }

    return sound;
  }

  Future<NotificationSoundOption> _loadSound({
    required String soundKey,
    required String pathKey,
    required String labelKey,
  }) async {
    final String? storedSound = await _preferences.getString(soundKey);
    final String? customPath = await _preferences.getString(pathKey);
    final String? customLabel = await _preferences.getString(labelKey);

    if (customPath != null && customPath.isNotEmpty) {
      final bool exists = await File(customPath).exists();
      if (!exists) {
        await _preferences.remove(pathKey);
        await _preferences.remove(labelKey);
      }
    }

    return NotificationSoundOption.fromStorage(
      rawValue: storedSound,
      customPath: customPath,
      customLabel: customLabel,
    ).ensureUsableFor(
      soundKey == AppConstants.alarmSoundKey
          ? NotificationSoundRole.alarm
          : NotificationSoundRole.reminder,
    );
  }

  Future<NotificationSoundOption?> _pickCustomSound({
    required String role,
    required String soundKey,
    required String pathKey,
    required String labelKey,
  }) async {
    final NotificationSoundRole soundRole = role == 'alarm'
        ? NotificationSoundRole.alarm
        : NotificationSoundRole.reminder;
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const <String>[
        'mp3',
        'wav',
        'm4a',
        'aac',
        'ogg',
        'mpeg',
      ],
      dialogTitle: 'Select a ringtone for $role alerts',
    );

    final PlatformFile? file = result == null || result.files.isEmpty
        ? null
        : result.files.first;
    final String? selectedPath = file?.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return null;
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory targetDirectory = Directory(
      path.join(appDirectory.path, AppConstants.customSoundFolderName),
    );
    await targetDirectory.create(recursive: true);

    final String extension = path.extension(selectedPath);
    final String targetPath = path.join(
      targetDirectory.path,
      '${role}_custom${extension.isEmpty ? '.mp3' : extension}',
    );

    final File copiedFile = await File(selectedPath).copy(targetPath);
    final NotificationSoundOption option = NotificationSoundOption.custom(
      customPath: copiedFile.path,
      customLabel: file?.name ?? '$role ringtone',
    );

    await _preferences.setString(soundKey, option.storageValue);
    await _preferences.setString(pathKey, copiedFile.path);
    await _preferences.setString(labelKey, option.labelFor(soundRole));

    return option;
  }
}
