import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_extensions.dart';
import '../../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;
    final DateTime now = DateTime.now();
    final bool isCompleted = task.isCompletedFor(now);
    final bool isMissed = task.isMissedFor(now);
    final bool isOverdue = task.isOverdue;
    final TaskOccurrenceWindow? occurrence = task.currentYudhOccurrence(now);
    final TaskPerformanceStats? stats = task.isYudh
        ? task.performanceStats()
        : null;
    final List<Widget> pills = <Widget>[];

    if (task.isYudh) {
      if (occurrence != null) {
        pills.add(
          _MetaPill(
            icon: Icons.schedule_rounded,
            label: DateTimeFormatting.timeRange(
              occurrence.startAt,
              durationMinutes: task.schedule?.durationMinutes ?? 60,
            ),
            tint: theme.colorScheme.primary,
          ),
        );
        pills.add(
          _MetaPill(
            icon: Icons.repeat_rounded,
            label: task.schedule?.repeat.label ?? 'Yudh',
            tint: theme.colorScheme.secondary,
          ),
        );
      }

      if ((task.subtasks).isNotEmpty) {
        pills.add(
          _MetaPill(
            icon: Icons.checklist_rounded,
            label: '${task.subtasks.length} subtasks',
            tint: theme.colorScheme.tertiary,
          ),
        );
      }

      if (stats != null) {
        pills.add(
          _MetaPill(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak ${stats.currentStreak}',
            tint: theme.colorScheme.secondary,
          ),
        );
        pills.add(
          _MetaPill(
            icon: Icons.stars_rounded,
            label: 'Score ${stats.score}',
            tint: theme.colorScheme.primary,
          ),
        );
      }

      if (task.schedule?.followUpAlarmEnabled == true) {
        pills.add(
          _MetaPill(
            icon: Icons.notifications_active_rounded,
            label: 'Alarm +${AppConstants.followUpAlarmDelayMinutes} min',
            tint: AppColors.softRed,
          ),
        );
      }
    } else {
      if (task.dueDate != null) {
        pills.add(
          _MetaPill(
            icon: Icons.event_rounded,
            label: DateTimeFormatting.friendlyDate(task.dueDate!),
            tint: isOverdue ? AppColors.softRed : theme.colorScheme.primary,
          ),
        );
      } else {
        pills.add(
          _MetaPill(
            icon: Icons.all_inclusive_rounded,
            label: 'No due date',
            tint: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }

      if (task.schedule != null) {
        pills.add(
          _MetaPill(
            icon: Icons.alarm_rounded,
            label: DateTimeFormatting.friendlyDate(
              task.schedule!.scheduledAt,
              includeTime: true,
            ),
            tint: theme.colorScheme.secondary,
          ),
        );

        if (task.schedule!.followUpAlarmEnabled) {
          pills.add(
            _MetaPill(
              icon: Icons.notifications_active_rounded,
              label: 'Alarm +${AppConstants.followUpAlarmDelayMinutes} min',
              tint: AppColors.softRed,
            ),
          );
        }
      }
    }

    final Color accent = task.isYudh
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    final String footerLabel = task.isYudh
        ? isCompleted
              ? 'Won this ${task.schedule?.repeat == ReminderRepeat.weekly ? 'week' : 'slot'}'
              : isMissed
              ? 'Missed window'
              : 'Yudh active'
        : isCompleted
        ? 'Wrapped up'
        : 'Long press to edit';

    return Dismissible(
      key: ValueKey('task-${task.id ?? task.createdAt.microsecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: AppColors.softRed,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        return true;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppColors.softShadow(brightness),
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onLongPress: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isMissed ? null : onToggleComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? accent
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCompleted
                              ? accent
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : isMissed
                            ? Icons.close_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isCompleted
                            ? (brightness == Brightness.dark
                                  ? AppColors.midnight
                                  : Colors.white)
                            : isMissed
                            ? AppColors.softRed
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: isCompleted
                                              ? theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                              : theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.kind.label,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: accent),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: onEdit,
                              splashRadius: 20,
                              icon: const Icon(Icons.edit_rounded),
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isOverdue)
                              const _MetaPill(
                                icon: Icons.priority_high_rounded,
                                label: 'Overdue',
                                tint: AppColors.softRed,
                              ),
                            if (isMissed)
                              const _MetaPill(
                                icon: Icons.timer_off_rounded,
                                label: 'Missed',
                                tint: AppColors.softRed,
                              ),
                            ...pills,
                            _MetaPill(
                              icon: task.isYudh
                                  ? Icons.auto_graph_rounded
                                  : Icons.auto_awesome_rounded,
                              label: footerLabel,
                              tint: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
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
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: tint),
          ),
        ],
      ),
    );
  }
}
