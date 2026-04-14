import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static final Uri _policyUri = Uri.parse(AppConstants.privacyPolicyUrl);

  static const List<_PolicySectionData> _sections = <_PolicySectionData>[
    _PolicySectionData(
      title: '1. Information We Collect',
      body: 'Simplify is a completely offline application.',
      bullets: <String>[
        'We do not collect, store, or share any personal data on external servers.',
        'All data you create, such as tasks, reminders, and preferences, is stored locally on your device using SQLite.',
      ],
    ),
    _PolicySectionData(
      title: '2. How Your Information Is Used',
      body: 'Your data is used only within the app to provide core features.',
      bullets: <String>[
        'Managing tasks.',
        'Setting reminders.',
        'Saving preferences like theme settings.',
        'We do not access or transmit your data outside your device.',
      ],
    ),
    _PolicySectionData(
      title: '3. Notifications',
      body: 'Simplify uses local notifications to remind you about tasks.',
      bullets: <String>[
        'Notifications are generated only on your device.',
        'No data is sent to external servers or third parties.',
      ],
    ),
    _PolicySectionData(
      title: '4. Data Sharing',
      body:
          'We do not share, sell, or transfer your data to any third parties.',
    ),
    _PolicySectionData(
      title: '5. Data Security',
      bullets: <String>[
        'All data is stored securely on your device.',
        'We do not store data on cloud servers.',
        'You have full control over your data.',
      ],
    ),
    _PolicySectionData(
      title: '6. Data Deletion',
      body: 'You can delete your data at any time.',
      bullets: <String>[
        'Remove tasks in the app.',
        'Uninstall the application to permanently remove all stored data.',
      ],
    ),
    _PolicySectionData(
      title: '7. Third-Party Services',
      body:
          'Simplify does not use third-party services that collect user data.',
    ),
    _PolicySectionData(
      title: '8. Children\'s Privacy',
      body:
          'Simplify does not knowingly collect any personal information from children under the age of 13.',
    ),
    _PolicySectionData(
      title: '9. Changes to This Privacy Policy',
      body: 'We may update this Privacy Policy in the future.',
      bullets: <String>[
        'Any changes will be reflected on this page with an updated effective date.',
      ],
    ),
    _PolicySectionData(
      title: '10. Contact Us',
      body:
          'If you have any questions or concerns about this Privacy Policy, you can contact us at:',
      bullets: <String>['Email: ${AppConstants.privacyPolicyEmail}'],
    ),
  ];

  Future<void> _openHostedPolicy(BuildContext context) async {
    final bool launched = await launchUrl(_policyUri);
    if (launched || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Unable to open the hosted privacy policy link.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
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
              child: SelectionArea(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    _HeroCard(
                      onOpenHostedPolicy: () => _openHostedPolicy(context),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Summary', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            'Simplify stays local-first, offline, and under your control.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _SummaryPill(label: 'No data collection'),
                              _SummaryPill(label: 'No internet usage'),
                              _SummaryPill(label: 'Fully offline'),
                              _SummaryPill(label: 'On-device storage'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._sections.map((section) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SectionCard(
                          child: _PolicySection(section: section),
                        ),
                      );
                    }),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agreement',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By using Simplify, you agree to this Privacy Policy.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                            ),
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
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onOpenHostedPolicy});

  final VoidCallback onOpenHostedPolicy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? const <Color>[Color(0xFF132032), Color(0xFF0E1726)]
              : const <Color>[Color(0xFFFFF1E5), Color(0xFFE8FBF5)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.softShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.72,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Privacy Policy for Simplify',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Effective date: ${AppConstants.privacyPolicyEffectiveDate}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This page mirrors the current Simplify privacy policy and keeps the hosted copy one tap away.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onOpenHostedPolicy,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open hosted policy'),
          ),
          const SizedBox(height: 14),
          Text(
            AppConstants.privacyPolicyUrl,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.softShadow(Theme.of(context).brightness),
      ),
      child: child,
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.section});

  final _PolicySectionData section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: theme.textTheme.headlineSmall),
        if (section.body != null) ...[
          const SizedBox(height: 10),
          Text(
            section.body!,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
        if (section.bullets.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...section.bullets.map((bullet) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PolicyBullet(text: bullet),
            );
          }),
        ],
      ],
    );
  }
}

class _PolicyBullet extends StatelessWidget {
  const _PolicyBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.2 : 0.11,
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

class _PolicySectionData {
  const _PolicySectionData({
    required this.title,
    this.body,
    this.bullets = const <String>[],
  });

  final String title;
  final String? body;
  final List<String> bullets;
}
