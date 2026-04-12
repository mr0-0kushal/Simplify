import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_extensions.dart';
import '../../../data/models/task_model.dart';

class OverviewPanel extends StatelessWidget {
  const OverviewPanel({
    super.key,
    required this.todayCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.progress,
    required this.nextTask,
    required this.nextTaskTime,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenSettings,
    required this.yudhCount,
    required this.yudhScore,
    required this.yudhCurrentStreak,
    required this.onOpenReport,
  });

  final int todayCount;
  final int upcomingCount;
  final int completedCount;
  final double progress;
  final TaskModel? nextTask;
  final DateTime? nextTaskTime;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenSettings;
  final int yudhCount;
  final int yudhScore;
  final int yudhCurrentStreak;
  final VoidCallback? onOpenReport;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;
    final String logoAsset = brightness == Brightness.dark
        ? AppConstants.darkLogoAsset
        : AppConstants.lightLogoAsset;
    final String nextTaskLabel = nextTask == null
        ? 'Clear head. Capture only what matters.'
        : 'Next focus: ${nextTask!.title}';
    final String nextTaskMeta = nextTaskTime == null
        ? 'You are officially caught up.'
        : DateTimeFormatting.friendlyDate(nextTaskTime!, includeTime: true);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brightness == Brightness.dark
              ? <Color>[const Color(0xFF172130), const Color(0xFF0F1723)]
              : <Color>[const Color(0xFFFFF3EA), const Color(0xFFEAF9F4)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppColors.softShadow(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: brightness == Brightness.dark ? 0.09 : 0.7,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(logoAsset),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simplify', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'One-time clarity with a Yudh rhythm.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onToggleTheme,
                icon: Icon(
                  isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Make today feel lighter',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(nextTaskLabel, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            nextTaskMeta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(
                alpha: brightness == Brightness.dark ? 0.08 : 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).round()}% of visible work is completed',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatPill(label: 'Today', value: '$todayCount'),
              _StatPill(label: 'Upcoming', value: '$upcomingCount'),
              _StatPill(label: 'Completed', value: '$completedCount'),
              _StatPill(label: 'Yudh blocks', value: '$yudhCount'),
              _StatPill(label: 'Yudh score', value: '$yudhScore'),
              _StatPill(label: 'Live streak', value: '$yudhCurrentStreak'),
            ],
          ),
          if (onOpenReport != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onOpenReport,
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Open Yudh report'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.08 : 0.65,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
