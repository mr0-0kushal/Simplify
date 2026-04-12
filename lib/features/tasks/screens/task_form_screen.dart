import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/task_model.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskModel? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final List<TextEditingController> _subtaskControllers;

  late TaskKind _taskKind;
  DateTime? _dueDate;
  bool _hasReminder = false;
  DateTime? _scheduleAt;
  ReminderRepeat _repeat = ReminderRepeat.none;
  bool _hasFollowUpAlarm = false;
  int _durationMinutes = AppConstants.defaultYudhDurationMinutes;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;
  bool get _isYudh => _taskKind == TaskKind.yudh;

  @override
  void initState() {
    super.initState();

    final TaskSchedule? schedule = widget.task?.schedule;

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _subtaskControllers = (widget.task?.subtasks ?? const <TaskChecklistItem>[])
        .map((item) => TextEditingController(text: item.title))
        .toList(growable: true);
    _taskKind = widget.task?.kind ?? TaskKind.oneTime;
    _dueDate = widget.task?.dueDate;
    _hasReminder = schedule?.reminderEnabled ?? false;
    _scheduleAt = schedule?.scheduledAt;
    _repeat = _taskKind == TaskKind.yudh
        ? (schedule?.repeat == ReminderRepeat.none
              ? ReminderRepeat.daily
              : schedule?.repeat ?? ReminderRepeat.daily)
        : ReminderRepeat.none;
    _hasFollowUpAlarm = schedule?.followUpAlarmEnabled ?? false;
    _durationMinutes =
        schedule?.durationMinutes ?? AppConstants.defaultYudhDurationMinutes;

    if (_isYudh && _scheduleAt == null) {
      _scheduleAt = _defaultYudhStart();
      _hasReminder = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final TextEditingController controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime _defaultYudhStart() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 8);
  }

  Future<void> _pickDueDate() async {
    final DateTime initialDate = _dueDate ?? DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        23,
        59,
      );
    });
  }

  Future<void> _pickScheduleDateTime() async {
    final DateTime seed =
        _scheduleAt ??
        (_isYudh
            ? _defaultYudhStart()
            : DateTime.now().add(const Duration(hours: 1)));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _scheduleAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _hasReminder = true;
    });
  }

  void _setTaskKind(TaskKind kind) {
    if (_taskKind == kind) {
      return;
    }

    setState(() {
      _taskKind = kind;
      if (_taskKind == TaskKind.yudh) {
        _repeat = _repeat == ReminderRepeat.weekly
            ? ReminderRepeat.weekly
            : ReminderRepeat.daily;
        _scheduleAt ??= _defaultYudhStart();
        _hasReminder = true;
        _dueDate = null;
      } else {
        _repeat = ReminderRepeat.none;
        _durationMinutes = AppConstants.defaultYudhDurationMinutes;
        for (final TextEditingController controller in _subtaskControllers) {
          controller.dispose();
        }
        _subtaskControllers.clear();
      }
    });
  }

  void _toggleReminder(bool value) {
    setState(() {
      _hasReminder = value;
      if (value) {
        _scheduleAt ??= _isYudh
            ? _defaultYudhStart()
            : DateTime.now().add(const Duration(hours: 1));
      } else {
        _hasFollowUpAlarm = false;
        if (!_isYudh) {
          _scheduleAt = null;
        }
      }
    });
  }

  void _addSubtaskField() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtaskField(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_hasReminder && _scheduleAt == null) {
      _showMessage(
        _isYudh
            ? 'Pick the Yudh study slot first.'
            : 'Pick the reminder time first.',
      );
      return;
    }

    if (!_isYudh &&
        _hasReminder &&
        _scheduleAt != null &&
        !_scheduleAt!.isAfter(DateTime.now())) {
      _showMessage('One-time reminders need a future date and time.');
      return;
    }

    if (_isYudh && _scheduleAt == null) {
      _showMessage('Yudh needs a start time to build the timetable.');
      return;
    }

    setState(() => _isSaving = true);

    final List<TaskChecklistItem> subtasks = _subtaskControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false)
        .asMap()
        .entries
        .map((entry) {
          final int index = entry.key;
          final String title = entry.value;
          final bool preserveCompletion =
              index < (widget.task?.subtasks.length ?? 0) &&
              widget.task!.subtasks[index].title == title;
          return TaskChecklistItem(
            title: title,
            isCompleted: preserveCompletion
                ? widget.task!.subtasks[index].isCompleted
                : false,
          );
        })
        .toList(growable: false);

    final TaskSchedule? schedule = _hasReminder && _scheduleAt != null
        ? TaskSchedule(
            scheduledAt: _scheduleAt!,
            repeat: _isYudh ? _repeat : ReminderRepeat.none,
            reminderEnabled: _hasReminder,
            followUpAlarmEnabled: _hasReminder && _hasFollowUpAlarm,
            durationMinutes: _isYudh ? _durationMinutes : 60,
          )
        : _isYudh && _scheduleAt != null
        ? TaskSchedule(
            scheduledAt: _scheduleAt!,
            repeat: _repeat,
            reminderEnabled: false,
            followUpAlarmEnabled: false,
            durationMinutes: _durationMinutes,
          )
        : null;

    final bool preserveProgressLogs =
        widget.task?.isYudh == true &&
        _taskKind == TaskKind.yudh &&
        widget.task?.schedule?.repeat == schedule?.repeat &&
        widget.task?.schedule?.durationMinutes == schedule?.durationMinutes &&
        widget.task?.schedule?.scheduledAt.hour == schedule?.scheduledAt.hour &&
        widget.task?.schedule?.scheduledAt.minute ==
            schedule?.scheduledAt.minute &&
        widget.task?.schedule?.scheduledAt.weekday ==
            schedule?.scheduledAt.weekday;

    final TaskModel task = TaskModel(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      isCompleted: _taskKind == TaskKind.oneTime
          ? widget.task?.isCompleted ?? false
          : false,
      dueDate: _taskKind == TaskKind.oneTime ? _dueDate : null,
      schedule: schedule,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      kind: _taskKind,
      subtasks: _taskKind == TaskKind.yudh
          ? subtasks
          : const <TaskChecklistItem>[],
      progressLogs: preserveProgressLogs
          ? widget.task?.progressLogs ?? const <TaskProgressLog>[]
          : const <TaskProgressLog>[],
    );

    try {
      await context.read<TaskProvider>().upsertTask(task);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _showMessage('Something went wrong while saving the task.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveTask,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
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
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: AppColors.softShadow(theme.brightness),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Refine the plan and keep the momentum steady.'
                                  : 'Choose a one-time task or build a Yudh timetable block.',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'One-time tasks handle normal to-dos. Yudh is for recurring daily or weekly focus blocks with streaks, score, and report tracking.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FormCard(
                        title: 'Task type',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<TaskKind>(
                                showSelectedIcon: false,
                                segments: const <ButtonSegment<TaskKind>>[
                                  ButtonSegment<TaskKind>(
                                    value: TaskKind.oneTime,
                                    label: Text('One-time'),
                                    icon: Icon(Icons.task_alt_rounded),
                                  ),
                                  ButtonSegment<TaskKind>(
                                    value: TaskKind.yudh,
                                    label: Text('Yudh'),
                                    icon: Icon(Icons.bolt_rounded),
                                  ),
                                ],
                                selected: <TaskKind>{_taskKind},
                                onSelectionChanged: (selection) {
                                  _setTaskKind(selection.first);
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _isYudh
                                  ? 'Yudh creates a repeatable day-to-day or weekly slot with score, streak, and report tracking.'
                                  : 'One-time keeps normal tasks simple: due date optional, reminder optional, done means done.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FormCard(
                        title: _isYudh ? 'Mission details' : 'Task details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: _isYudh
                                    ? 'Focus block title'
                                    : 'Title',
                                hintText: _isYudh
                                    ? 'Maths sprint'
                                    : 'Finish the poster draft',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'A clear title helps you spot it fast.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 4,
                              maxLines: 6,
                              decoration: InputDecoration(
                                labelText: _isYudh
                                    ? 'Goal or context'
                                    : 'Description',
                                hintText: _isYudh
                                    ? 'Exam prep, chapter target, or what success looks like for this block.'
                                    : 'Add context, checklist notes, or anything future-you should remember.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FormCard(
                        title: _isYudh ? 'Schedule' : 'Timing',
                        child: Column(
                          children: [
                            if (!_isYudh) ...[
                              _ActionTile(
                                icon: Icons.event_rounded,
                                title: 'Due date',
                                value: _dueDate == null
                                    ? 'No deadline yet'
                                    : DateTimeFormatting.friendlyDate(
                                        _dueDate!,
                                      ),
                                onTap: _pickDueDate,
                                trailing: _dueDate == null
                                    ? null
                                    : TextButton(
                                        onPressed: () {
                                          setState(() => _dueDate = null);
                                        },
                                        child: const Text('Clear'),
                                      ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_isYudh) ...[
                              _ActionTile(
                                icon: Icons.schedule_rounded,
                                title: 'Study slot',
                                value: _scheduleAt == null
                                    ? 'Pick the day and start time'
                                    : '${DateTimeFormatting.friendlyDate(_scheduleAt!)} | ${DateTimeFormatting.timeRange(_scheduleAt!, durationMinutes: _durationMinutes)}',
                                onTap: _pickScheduleDateTime,
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Repeat',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SegmentedButton<ReminderRepeat>(
                                  showSelectedIcon: false,
                                  segments:
                                      const <ButtonSegment<ReminderRepeat>>[
                                        ButtonSegment<ReminderRepeat>(
                                          value: ReminderRepeat.daily,
                                          label: Text('Daily'),
                                          icon: Icon(Icons.today_rounded),
                                        ),
                                        ButtonSegment<ReminderRepeat>(
                                          value: ReminderRepeat.weekly,
                                          label: Text('Weekly'),
                                          icon: Icon(Icons.view_week_rounded),
                                        ),
                                      ],
                                  selected: <ReminderRepeat>{_repeat},
                                  onSelectionChanged: (selection) {
                                    setState(() => _repeat = selection.first);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Session duration',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: const <int>[30, 60, 90, 120, 180]
                                    .map((minutes) {
                                      final bool isSelected =
                                          minutes == _durationMinutes;
                                      return ChoiceChip(
                                        label: Text('$minutes min'),
                                        selected: isSelected,
                                        onSelected: (_) {
                                          setState(() {
                                            _durationMinutes = minutes;
                                          });
                                        },
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (!_isYudh) ...[
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Reminder'),
                                subtitle: Text(
                                  _hasReminder
                                      ? 'Local notification scheduled on-device.'
                                      : 'Turn this on if you want a nudge before you forget.',
                                ),
                                value: _hasReminder,
                                onChanged: _toggleReminder,
                              ),
                            ] else ...[
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Reminder at start time'),
                                subtitle: Text(
                                  _hasReminder
                                      ? 'The Yudh reminder fires when the block starts.'
                                      : 'Keep the timetable visible without sending a reminder.',
                                ),
                                value: _hasReminder,
                                onChanged: _toggleReminder,
                              ),
                            ],
                            if (_hasReminder) ...[
                              const SizedBox(height: 10),
                              _ActionTile(
                                icon: Icons.alarm_rounded,
                                title: _isYudh
                                    ? 'Reminder slot'
                                    : 'Reminder time',
                                value: _scheduleAt == null
                                    ? 'Choose a date and time'
                                    : DateTimeFormatting.friendlyDate(
                                        _scheduleAt!,
                                        includeTime: true,
                                      ),
                                onTap: _pickScheduleDateTime,
                                trailing: _scheduleAt == null || _isYudh
                                    ? null
                                    : TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _scheduleAt = null;
                                            _hasFollowUpAlarm = false;
                                          });
                                        },
                                        child: const Text('Clear'),
                                      ),
                              ),
                              const SizedBox(height: 10),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _hasFollowUpAlarm,
                                title: const Text('Follow-up alarm'),
                                subtitle: Text(
                                  'Automatically fires ${AppConstants.followUpAlarmDelayMinutes} minutes after the reminder.',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _hasFollowUpAlarm = value;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_isYudh) ...[
                        const SizedBox(height: 18),
                        _FormCard(
                          title: 'Subtasks',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add topics, chapters, mocks, or any smaller targets inside this Yudh block.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_subtaskControllers.isEmpty)
                                Text(
                                  'No subtasks yet. Add one to turn this into a proper timetable block.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              else
                                Column(
                                  children: List<Widget>.generate(
                                    _subtaskControllers.length,
                                    (index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              index ==
                                                  _subtaskControllers.length - 1
                                              ? 0
                                              : 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _subtaskControllers[index],
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Subtask ${index + 1}',
                                                  hintText:
                                                      'Chapter 4 revision',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton.filledTonal(
                                              onPressed: () =>
                                                  _removeSubtaskField(index),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _addSubtaskField,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add subtask'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_isEditing) ...[
                        const SizedBox(height: 18),
                        _FormCard(
                          title: 'Meta',
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Created ${DateTimeFormatting.createdAtLabel(widget.task!.createdAt)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveTask,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            _isEditing
                                ? (_isYudh
                                      ? 'Update Yudh block'
                                      : 'Update task')
                                : (_isYudh
                                      ? 'Create Yudh block'
                                      : 'Create task'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.softShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
