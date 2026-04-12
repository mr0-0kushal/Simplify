import 'package:flutter_test/flutter_test.dart';
import 'package:simplify/core/constants/notification_sound_option.dart';

void main() {
  test('alarm app default uses the new Uth Jaa preset on Android', () {
    const NotificationSoundOption option = NotificationSoundOption.appDefault();

    expect(
      option.androidSoundTokenFor(NotificationSoundRole.alarm),
      'app_default_alarm_uth_jaa',
    );
  });

  test('optional alarm tone falls back to app default for reminder role', () {
    const NotificationSoundOption option =
        NotificationSoundOption.optionalAlarm();

    expect(
      option.ensureUsableFor(NotificationSoundRole.reminder),
      const NotificationSoundOption.appDefault(),
    );
  });
}
