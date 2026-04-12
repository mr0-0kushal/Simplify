import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/notification_sound_option.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../providers/notification_preferences_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import 'contact_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _setReminderSound(
    BuildContext context,
    NotificationPreferencesProvider preferencesProvider,
    TaskProvider taskProvider,
    NotificationSoundType type,
  ) async {
    final NotificationSoundOption? option = await _resolveSoundSelection(
      context: context,
      type: type,
      current: preferencesProvider.reminderSound,
      onPickCustom: preferencesProvider.pickCustomReminderSound,
    );
    if (option == null) {
      return;
    }

    await preferencesProvider.updateReminderSound(option);
    await taskProvider.rescheduleActiveNotifications();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Reminder tone set to ${option.labelFor(NotificationSoundRole.reminder)}.',
          ),
        ),
      );
  }

  Future<void> _setAlarmSound(
    BuildContext context,
    NotificationPreferencesProvider preferencesProvider,
    TaskProvider taskProvider,
    NotificationSoundType type,
  ) async {
    final NotificationSoundOption? option = await _resolveSoundSelection(
      context: context,
      type: type,
      current: preferencesProvider.alarmSound,
      onPickCustom: preferencesProvider.pickCustomAlarmSound,
    );
    if (option == null) {
      return;
    }

    await preferencesProvider.updateAlarmSound(option);
    await taskProvider.rescheduleActiveNotifications();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Alarm tone set to ${option.labelFor(NotificationSoundRole.alarm)}.',
          ),
        ),
      );
  }

  Future<NotificationSoundOption?> _resolveSoundSelection({
    required BuildContext context,
    required NotificationSoundType type,
    required NotificationSoundOption current,
    required Future<NotificationSoundOption?> Function() onPickCustom,
  }) async {
    switch (type) {
      case NotificationSoundType.appDefault:
        return const NotificationSoundOption.appDefault();
      case NotificationSoundType.optionalAlarm:
        return const NotificationSoundOption.optionalAlarm();
      case NotificationSoundType.deviceDefault:
        return const NotificationSoundOption.deviceDefault();
      case NotificationSoundType.custom:
        final NotificationSoundOption? customOption = await onPickCustom();
        if (customOption == null && context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'No ringtone selected. Keeping the current tone.',
                ),
              ),
            );
        }
        return customOption ?? current;
    }
  }

  Future<void> _openContact(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ContactScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      ThemeProvider,
      TaskProvider,
      NotificationPreferencesProvider
    >(
      builder: (context, themeProvider, taskProvider, notificationPreferences, _) {
        final ThemeData theme = Theme.of(context);
        final double horizontalPadding = Responsive.horizontalPadding(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.screenGradient(theme.brightness),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentWidth(context),
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      32,
                    ),
                    children: [
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme vibe',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Switch between the soft pastel daytime palette and the neon-accent night mode.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 22),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: themeProvider.isDarkMode,
                              title: const Text('Dark pulse mode'),
                              subtitle: Text(
                                themeProvider.isDarkMode
                                    ? 'Deep gray surfaces with neon highlights.'
                                    : 'Soft bright surfaces with warm pastel accents.',
                              ),
                              onChanged: (value) {
                                themeProvider.setThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringtone controls',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Only three choices are kept now: Simplify\'s own ringtone, your device default, or a custom audio file you pick.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SoundChooser(
                              title: 'Reminder tone',
                              subtitle:
                                  'This plays when the main reminder notification arrives.',
                              role: NotificationSoundRole.reminder,
                              selected: notificationPreferences.reminderSound,
                              onSelected: (type) {
                                _setReminderSound(
                                  context,
                                  notificationPreferences,
                                  taskProvider,
                                  type,
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            _SoundChooser(
                              title: 'Alarm tone',
                              subtitle:
                                  'This plays ${AppConstants.followUpAlarmDelayMinutes} minutes after the reminder if follow-up alarm is enabled on the task.',
                              role: NotificationSoundRole.alarm,
                              selected: notificationPreferences.alarmSound,
                              onSelected: (type) {
                                _setAlarmSound(
                                  context,
                                  notificationPreferences,
                                  taskProvider,
                                  type,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Custom tones use your selected local audio file. On Android, both reminders and follow-up alarms use it directly.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local-first setup',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 18),
                            const _InfoRow(
                              icon: Icons.offline_bolt_rounded,
                              title: 'Offline by design',
                              subtitle:
                                  'Tasks, Yudh plans, reminders, reports, and sound choices stay on-device.',
                            ),
                            const SizedBox(height: 14),
                            const _InfoRow(
                              icon: Icons.notifications_active_rounded,
                              title: 'Reminder engine',
                              subtitle:
                                  'Each task can send a reminder first and a follow-up alarm a few minutes later.',
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.storage_rounded,
                              title: 'Your current board',
                              subtitle:
                                  '${taskProvider.totalCount} tasks captured, ${taskProvider.yudhCount} in Yudh, ${taskProvider.completedCount} completed right now.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SettingsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Open the profile page for the student details you wanted included in the app.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.contact_page_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: const Text('Kushal Kant Sharma'),
                              subtitle: const Text(
                                'Class roll no. 32, Section A',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _openContact(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.softShadow(Theme.of(context).brightness),
      ),
      child: child,
    );
  }
}

class _SoundChooser extends StatelessWidget {
  const _SoundChooser({
    required this.title,
    required this.subtitle,
    required this.role,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final NotificationSoundRole role;
  final NotificationSoundOption selected;
  final ValueChanged<NotificationSoundType> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: NotificationSoundType.values
              .where((type) => type.supportsRole(role))
              .map((type) {
                final bool isSelected = type == selected.type;

                return ChoiceChip(
                  label: Text(type.optionLabelFor(role)),
                  selected: isSelected,
                  onSelected: (_) => onSelected(type),
                  avatar: Icon(
                    type == NotificationSoundType.custom
                        ? Icons.library_music_rounded
                        : Icons.music_note_rounded,
                    size: 18,
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Text(
          selected.descriptionFor(role),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
