import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/overview_panel.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_chip.dart';
import 'settings_screen.dart';
import 'task_form_screen.dart';
import 'yudh_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openTaskForm(BuildContext context, [TaskModel? task]) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)));
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openYudhReport(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const YudhReportScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, ThemeProvider>(
      builder: (context, taskProvider, themeProvider, _) {
        final ThemeData theme = Theme.of(context);
        final double horizontalPadding = Responsive.horizontalPadding(context);
        final List<TaskModel> oneTimeTasks = taskProvider.visibleOneTimeTasks;
        final List<TaskModel> yudhTasks = taskProvider.visibleYudhTasks;
        final TaskModel? nextTask = taskProvider.nextTask;
        final DateTime? nextTaskTime = nextTask == null
            ? null
            : taskProvider.nextFocusTimeFor(nextTask);
        final YudhReportSummary yudhReport = taskProvider.yudhReport;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openTaskForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New task'),
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.screenGradient(theme.brightness),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -30,
                  child: _GlowOrb(color: theme.colorScheme.primary),
                ),
                Positioned(
                  bottom: 160,
                  left: -40,
                  child: _GlowOrb(color: theme.colorScheme.tertiary),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentWidth(context),
                      ),
                      child: RefreshIndicator(
                        onRefresh: taskProvider.loadTasks,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                12,
                                horizontalPadding,
                                0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: OverviewPanel(
                                  todayCount: taskProvider.todayCount,
                                  upcomingCount: taskProvider.upcomingCount,
                                  completedCount: taskProvider.completedCount,
                                  progress: taskProvider.completionProgress,
                                  nextTask: nextTask,
                                  nextTaskTime: nextTaskTime,
                                  isDarkMode: themeProvider.isDarkMode,
                                  onToggleTheme: themeProvider.toggleTheme,
                                  onOpenSettings: () => _openSettings(context),
                                  yudhCount: taskProvider.yudhCount,
                                  yudhScore: yudhReport.score,
                                  yudhCurrentStreak: yudhReport.currentStreak,
                                  onOpenReport: taskProvider.yudhCount == 0
                                      ? null
                                      : () => _openYudhReport(context),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                20,
                                horizontalPadding,
                                0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: TaskFilter.values
                                      .map((filter) {
                                        final int count;
                                        switch (filter) {
                                          case TaskFilter.today:
                                            count = taskProvider.todayCount;
                                          case TaskFilter.upcoming:
                                            count = taskProvider.upcomingCount;
                                          case TaskFilter.completed:
                                            count = taskProvider.completedCount;
                                        }

                                        return TaskFilterChip(
                                          label: filter.label,
                                          count: count,
                                          isSelected:
                                              taskProvider.selectedFilter ==
                                              filter,
                                          onTap: () =>
                                              taskProvider.updateFilter(filter),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                              ),
                            ),
                            if (taskProvider.isLoading &&
                                !taskProvider.hasTasks)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (oneTimeTasks.isEmpty && yudhTasks.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: EmptyState(
                                  title: taskProvider.selectedFilter.emptyTitle,
                                  subtitle:
                                      taskProvider.selectedFilter.emptySubtitle,
                                  onAction: () => _openTaskForm(context),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  18,
                                  horizontalPadding,
                                  120,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      if (yudhTasks.isNotEmpty) ...[
                                        _SectionHeader(
                                          title: 'Yudh',
                                          subtitle:
                                              taskProvider.selectedFilter ==
                                                  TaskFilter.completed
                                              ? 'Your recurring wins for the current period.'
                                              : 'Day-to-day and weekly rhythm blocks.',
                                          actionLabel: 'Report',
                                          onAction: () =>
                                              _openYudhReport(context),
                                        ),
                                        const SizedBox(height: 12),
                                        ...yudhTasks.map((task) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 14,
                                            ),
                                            child: TaskCard(
                                              task: task,
                                              onToggleComplete: () {
                                                taskProvider
                                                    .toggleTaskCompletion(task);
                                              },
                                              onEdit: () =>
                                                  _openTaskForm(context, task),
                                              onDelete: () async {
                                                await taskProvider.deleteTask(
                                                  task,
                                                );
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(context)
                                                  ..hideCurrentSnackBar()
                                                  ..showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Deleted "${task.title}"',
                                                      ),
                                                    ),
                                                  );
                                              },
                                            ),
                                          );
                                        }),
                                      ],
                                      if (oneTimeTasks.isNotEmpty) ...[
                                        _SectionHeader(
                                          title: 'One-time tasks',
                                          subtitle:
                                              taskProvider.selectedFilter ==
                                                  TaskFilter.completed
                                              ? 'Finished tasks that stay done.'
                                              : 'Standard tasks with optional due dates and reminders.',
                                        ),
                                        const SizedBox(height: 12),
                                        ...oneTimeTasks.map((task) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 14,
                                            ),
                                            child: TaskCard(
                                              task: task,
                                              onToggleComplete: () {
                                                taskProvider
                                                    .toggleTaskCompletion(task);
                                              },
                                              onEdit: () =>
                                                  _openTaskForm(context, task),
                                              onDelete: () async {
                                                await taskProvider.deleteTask(
                                                  task,
                                                );
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(context)
                                                  ..hideCurrentSnackBar()
                                                  ..showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Deleted "${task.title}"',
                                                      ),
                                                    ),
                                                  );
                                              },
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
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
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.insights_rounded),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
