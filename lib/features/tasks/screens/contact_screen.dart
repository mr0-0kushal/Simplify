import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String _githubProjectUrl =
      'https://github.com/mr0-0kushal/Simplify';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
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
                    padding: const EdgeInsets.all(28),
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
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.1
                                  : 0.7,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 34,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kushal Kant Sharma',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Student contact profile',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _ProfileTag(label: 'BCA - 3rd Year'),
                            _ProfileTag(label: 'Section A'),
                            _ProfileTag(label: 'GLA University'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ContactInfoCard(
                    title: 'Name',
                    value: 'Kushal Kant Sharma',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ContactInfoCard(
                    title: 'University Roll Number',
                    value: '2342010346',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  _ContactInfoCard(
                    title: 'Class Roll Number',
                    value: '32',
                    icon: Icons.numbers_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ContactInfoCard(
                    title: 'Section',
                    value: 'A',
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ContactInfoCard(
                    title: 'Department / Year',
                    value: 'BCA - 3rd Year',
                    icon: Icons.school_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ContactInfoCard(
                    title: 'University Name',
                    value: 'GLA University',
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ContactInfoCard(
                    title: 'GitHub Project Link',
                    value: _githubProjectUrl,
                    icon: Icons.link_rounded,
                    isAccent: true,
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

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isAccent = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color cardColor = isAccent
        ? theme.colorScheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
          )
        : theme.colorScheme.surface.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow(theme.brightness),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
