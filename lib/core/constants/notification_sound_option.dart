import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationSoundRole { reminder, alarm }

enum NotificationSoundType { appDefault, optionalAlarm, deviceDefault, custom }

extension NotificationSoundTypeX on NotificationSoundType {
  String get storageValue {
    switch (this) {
      case NotificationSoundType.appDefault:
        return 'app_default';
      case NotificationSoundType.optionalAlarm:
        return 'optional_alarm';
      case NotificationSoundType.deviceDefault:
        return 'device_default';
      case NotificationSoundType.custom:
        return 'custom';
    }
  }

  String optionLabelFor(NotificationSoundRole role) {
    switch (this) {
      case NotificationSoundType.appDefault:
        return role == NotificationSoundRole.alarm ? 'Uth Jaa' : 'App default';
      case NotificationSoundType.optionalAlarm:
        return 'Dum Dum';
      case NotificationSoundType.deviceDefault:
        return 'Device default';
      case NotificationSoundType.custom:
        return 'Custom ringtone';
    }
  }

  bool supportsRole(NotificationSoundRole role) {
    return role == NotificationSoundRole.alarm ||
        this != NotificationSoundType.optionalAlarm;
  }

  static NotificationSoundType fromStorage(String? rawValue) {
    switch (rawValue) {
      case 'optional_alarm':
        return NotificationSoundType.optionalAlarm;
      case 'device_default':
        return NotificationSoundType.deviceDefault;
      case 'custom':
        return NotificationSoundType.custom;
      default:
        return NotificationSoundType.appDefault;
    }
  }
}

@immutable
class NotificationSoundOption {
  const NotificationSoundOption._({
    required this.type,
    this.customPath,
    this.customLabel,
  });

  const NotificationSoundOption.appDefault()
    : this._(type: NotificationSoundType.appDefault);

  const NotificationSoundOption.optionalAlarm()
    : this._(type: NotificationSoundType.optionalAlarm);

  const NotificationSoundOption.deviceDefault()
    : this._(type: NotificationSoundType.deviceDefault);

  const NotificationSoundOption.custom({
    required String customPath,
    required String customLabel,
  }) : this._(
         type: NotificationSoundType.custom,
         customPath: customPath,
         customLabel: customLabel,
       );

  final NotificationSoundType type;
  final String? customPath;
  final String? customLabel;

  bool get isCustom => type == NotificationSoundType.custom;

  String get storageValue => type.storageValue;

  String labelFor(NotificationSoundRole role) {
    switch (type) {
      case NotificationSoundType.appDefault:
        return role == NotificationSoundRole.alarm
            ? 'Uth Jaa'
            : 'Simplify ringtone';
      case NotificationSoundType.optionalAlarm:
        return 'Dum Dum';
      case NotificationSoundType.deviceDefault:
        return 'Device default';
      case NotificationSoundType.custom:
        return customLabel?.trim().isNotEmpty == true
            ? customLabel!.trim()
            : 'Custom ringtone';
    }
  }

  String descriptionFor(NotificationSoundRole role) {
    switch (type) {
      case NotificationSoundType.appDefault:
        return role == NotificationSoundRole.alarm
            ? 'Uses the built-in Uth Jaa alarm tone.'
            : 'Uses the app ringtone that ships with Simplify.';
      case NotificationSoundType.optionalAlarm:
        return 'Uses the optional built-in Dum Dum alarm tone.';
      case NotificationSoundType.deviceDefault:
        return 'Uses the phone\'s default notification or alarm sound.';
      case NotificationSoundType.custom:
        return customLabel?.trim().isNotEmpty == true
            ? 'Uses your selected audio file: ${customLabel!.trim()}.'
            : 'Uses your selected custom audio file.';
    }
  }

  String get channelKey {
    switch (type) {
      case NotificationSoundType.appDefault:
        return 'app_default';
      case NotificationSoundType.optionalAlarm:
        return 'optional_alarm';
      case NotificationSoundType.deviceDefault:
        return 'device_default';
      case NotificationSoundType.custom:
        return 'custom_${(customPath ?? '').hashCode.abs()}';
    }
  }

  String androidSoundTokenFor(NotificationSoundRole role) {
    switch (type) {
      case NotificationSoundType.appDefault:
        return role == NotificationSoundRole.alarm
            ? 'app_default_alarm_uth_jaa'
            : 'reminder_fahhh';
      case NotificationSoundType.optionalAlarm:
        return 'app_alarm_dum_dum_optional';
      case NotificationSoundType.deviceDefault:
        return 'device_default';
      case NotificationSoundType.custom:
        return customPath ?? 'device_default';
    }
  }

  AndroidNotificationSound? androidSoundFor(NotificationSoundRole role) {
    switch (type) {
      case NotificationSoundType.appDefault:
        return RawResourceAndroidNotificationSound(androidSoundTokenFor(role));
      case NotificationSoundType.optionalAlarm:
        return const RawResourceAndroidNotificationSound(
          'app_alarm_dum_dum_optional',
        );
      case NotificationSoundType.deviceDefault:
        return null;
      case NotificationSoundType.custom:
        final String? path = customPath;
        if (path == null || path.isEmpty) {
          return null;
        }

        final String soundUri =
            path.startsWith('content://') || path.startsWith('file://')
            ? path
            : Uri.file(path).toString();
        return UriAndroidNotificationSound(soundUri);
    }
  }

  String? iosFileNameFor(NotificationSoundRole role) {
    switch (type) {
      case NotificationSoundType.appDefault:
        return role == NotificationSoundRole.alarm
            ? 'simplify_focus_alarm.wav'
            : 'simplify_soft_bloom.wav';
      case NotificationSoundType.optionalAlarm:
        // iOS local notifications require bundled AIFF/WAV/CAF files.
        return 'simplify_spark_pulse.wav';
      case NotificationSoundType.deviceDefault:
      case NotificationSoundType.custom:
        return null;
    }
  }

  NotificationSoundOption ensureUsableFor(NotificationSoundRole role) {
    if (!type.supportsRole(role)) {
      return const NotificationSoundOption.appDefault();
    }

    if (type != NotificationSoundType.custom) {
      return this;
    }

    if (customPath == null || customPath!.trim().isEmpty) {
      return const NotificationSoundOption.appDefault();
    }

    return this;
  }

  static NotificationSoundOption fromStorage({
    required String? rawValue,
    String? customPath,
    String? customLabel,
  }) {
    return switch (NotificationSoundTypeX.fromStorage(rawValue)) {
      NotificationSoundType.optionalAlarm =>
        const NotificationSoundOption.optionalAlarm(),
      NotificationSoundType.deviceDefault =>
        const NotificationSoundOption.deviceDefault(),
      NotificationSoundType.custom =>
        customPath == null || customPath.trim().isEmpty
            ? const NotificationSoundOption.appDefault()
            : NotificationSoundOption.custom(
                customPath: customPath,
                customLabel: customLabel?.trim().isNotEmpty == true
                    ? customLabel!.trim()
                    : 'Custom ringtone',
              ),
      NotificationSoundType.appDefault =>
        const NotificationSoundOption.appDefault(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NotificationSoundOption &&
        other.type == type &&
        other.customPath == customPath &&
        other.customLabel == customLabel;
  }

  @override
  int get hashCode => Object.hash(type, customPath, customLabel);
}
