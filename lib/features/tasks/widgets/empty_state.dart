import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: brightness == Brightness.dark
                        ? <Color>[AppColors.neonMint, AppColors.neonSky]
                        : <Color>[AppColors.coral, AppColors.mint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: AppColors.softShadow(brightness),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: brightness == Brightness.dark
                      ? AppColors.midnight
                      : Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
