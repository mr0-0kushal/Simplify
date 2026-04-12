import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/task_model.dart';
import '../providers/task_provider.dart';

class YudhReportScreen extends StatefulWidget {
  const YudhReportScreen({super.key});

  @override
  State<YudhReportScreen> createState() => _YudhReportScreenState();
}

class _YudhReportScreenState extends State<YudhReportScreen> {
  bool _isExporting = false;

  Future<void> _exportReport(
    BuildContext context,
    TaskProvider provider,
  ) async {
    setState(() => _isExporting = true);

    try {
      final DateTime now = DateTime.now();
      final Directory baseDirectory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final Directory targetDirectory = Directory(
        path.join(baseDirectory.path, AppConstants.exportedReportFolderName),
      );
      await targetDirectory.create(recursive: true);

      final String fileName =
          'yudh_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.html';
      final File reportFile = File(path.join(targetDirectory.path, fileName));
      await reportFile.writeAsString(_buildHtmlReport(provider, now));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Report saved to ${reportFile.path}')),
        );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Could not export the Yudh report.')),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildHtmlReport(TaskProvider provider, DateTime now) {
    final YudhReportSummary summary = provider.yudhReport;
    final String taskCards = provider.yudhTasks
        .map((task) {
          final TaskPerformanceStats stats = task.performanceStats();
          final TaskOccurrenceWindow? occurrence = task.currentYudhOccurrence(
            now,
          );
          final String nextSlot = occurrence == null
              ? 'No slot'
              : '${DateTimeFormatting.friendlyDate(occurrence.startAt)} - ${DateTimeFormatting.timeRange(occurrence.startAt, durationMinutes: task.schedule?.durationMinutes ?? 60)}';
          return '''
      <article class="task-card">
        <h3>${_escape(task.title)}</h3>
        <p>${_escape(task.description.isEmpty ? 'No extra context.' : task.description)}</p>
        <div class="meta">Next slot: ${_escape(nextSlot)}</div>
        <div class="meta">Completed: ${stats.completedCount} | Missed: ${stats.missedCount}</div>
        <div class="meta">Current streak: ${stats.currentStreak} | Best streak: ${stats.bestStreak}</div>
        <div class="meta">Score: ${stats.score}</div>
      </article>
      ''';
        })
        .join('\n');

    return '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Yudh Report</title>
    <style>
      body { font-family: Arial, sans-serif; background: #f7fafc; color: #152033; margin: 0; padding: 32px; }
      .hero { background: linear-gradient(135deg, #fff3ea, #eaf9f4); border-radius: 24px; padding: 24px; margin-bottom: 24px; }
      .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 20px 0; }
      .stat { background: white; border-radius: 18px; padding: 16px; box-shadow: 0 8px 22px rgba(18, 32, 51, 0.08); }
      .tasks { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; }
      .task-card { background: white; border-radius: 18px; padding: 18px; box-shadow: 0 8px 22px rgba(18, 32, 51, 0.08); }
      .meta { color: #526173; font-size: 14px; margin-top: 6px; }
    </style>
  </head>
  <body>
    <section class="hero">
      <h1>Yudh Report</h1>
      <p>Generated ${_escape(DateTimeFormatting.reportStamp(now))}</p>
      <div class="grid">
        <div class="stat"><strong>${summary.taskCount}</strong><br>Active Yudh blocks</div>
        <div class="stat"><strong>${summary.completedSessions}</strong><br>Completed sessions</div>
        <div class="stat"><strong>${summary.missedSessions}</strong><br>Missed sessions</div>
        <div class="stat"><strong>${summary.score}</strong><br>Total score</div>
        <div class="stat"><strong>${summary.currentStreak}</strong><br>Live streak</div>
        <div class="stat"><strong>${(summary.completionRate * 100).round()}%</strong><br>Completion rate</div>
      </div>
    </section>
    <section class="tasks">
      $taskCards
    </section>
  </body>
</html>
''';
  }

  String _escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final ThemeData theme = Theme.of(context);
        final YudhReportSummary summary = provider.yudhReport;
        final double horizontalPadding = Responsive.horizontalPadding(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Yudh report')),
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: theme.brightness == Brightness.dark
                                ? const <Color>[
                                    Color(0xFF172130),
                                    Color(0xFF0F1723),
                                  ]
                                : const <Color>[
                                    Color(0xFFFFF3EA),
                                    Color(0xFFEAF9F4),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: AppColors.softShadow(theme.brightness),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yudh performance',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A calmer summary of your daily and weekly consistency, built for progress rather than guilt.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _StatTile(
                                  label: 'Blocks',
                                  value: '${summary.taskCount}',
                                ),
                                _StatTile(
                                  label: 'Completed',
                                  value: '${summary.completedSessions}',
                                ),
                                _StatTile(
                                  label: 'Missed',
                                  value: '${summary.missedSessions}',
                                ),
                                _StatTile(
                                  label: 'Score',
                                  value: '${summary.score}',
                                ),
                                _StatTile(
                                  label: 'Live streak',
                                  value: '${summary.currentStreak}',
                                ),
                                _StatTile(
                                  label: 'Rate',
                                  value:
                                      '${(summary.completionRate * 100).round()}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportReport(context, provider),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download_rounded),
                              label: Text(
                                _isExporting ? 'Saving...' : 'Download report',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...provider.yudhTasks.map((task) {
                        final TaskPerformanceStats stats = task
                            .performanceStats();
                        final TaskOccurrenceWindow? occurrence = task
                            .currentYudhOccurrence(DateTime.now());
                        final String slotLabel = occurrence == null
                            ? 'No active slot'
                            : '${DateTimeFormatting.friendlyDate(occurrence.startAt)} | ${DateTimeFormatting.timeRange(occurrence.startAt, durationMinutes: task.schedule?.durationMinutes ?? 60)}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.9,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: AppColors.softShadow(theme.brightness),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  task.description.isEmpty
                                      ? 'No extra notes added for this Yudh block.'
                                      : task.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _ReportRow(
                                  label: 'Next slot',
                                  value: slotLabel,
                                ),
                                _ReportRow(
                                  label: 'Progress',
                                  value:
                                      '${stats.completedCount} completed, ${stats.missedCount} missed',
                                ),
                                _ReportRow(
                                  label: 'Streak',
                                  value:
                                      '${stats.currentStreak} live, ${stats.bestStreak} best',
                                ),
                                _ReportRow(
                                  label: 'Score',
                                  value: '${stats.score}',
                                ),
                                _ReportRow(
                                  label: 'Subtasks',
                                  value: task.subtasks.isEmpty
                                      ? 'No subtasks'
                                      : task.subtasks
                                            .map((item) => item.title)
                                            .join(', '),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.08 : 0.72,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
