import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/tasks/providers/task_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await context.read<TaskProvider>().initializeNotifications();
    await Future<void>.delayed(
      const Duration(milliseconds: AppConstants.splashDurationMs),
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Animation<Offset> offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String logoAsset = theme.brightness == Brightness.dark
        ? AppConstants.darkLogoAsset
        : AppConstants.lightLogoAsset;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(theme.brightness),
        ),
        child: Stack(
          children: [
            const _SplashOrb(top: -50, left: -20, size: 180),
            const _SplashOrb(bottom: -60, right: -10, size: 220),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.88, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.76,
                            ),
                            borderRadius: BorderRadius.circular(38),
                            boxShadow: AppColors.softShadow(theme.brightness),
                          ),
                          child: Image.asset(logoAsset, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 28),
                        Text('Simplify', style: theme.textTheme.displaySmall),
                        const SizedBox(height: 10),
                        Text(
                          'Offline planning that feels calm, quick, and premium.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 180,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
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
  }
}

class _SplashOrb extends StatelessWidget {
  const _SplashOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? AppColors.neonSky : AppColors.coral).withValues(
              alpha: 0.14,
            ),
          ),
        ),
      ),
    );
  }
}
