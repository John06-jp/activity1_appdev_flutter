import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HeaderBanner extends StatelessWidget {
  const HeaderBanner({super.key});

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 18) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appProvider = context.watch<AppProvider>();
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            secondaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background decorative circle pattern
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 550;

                final avatarWidget = Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    child: Icon(
                      appProvider.currentAvatarIcon,
                      size: 38,
                    ),
                  ),
                );

                final infoWidget = Column(
                  crossAxisAlignment: isWide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 14,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FLUTTER PORTFOLIO COMPILATION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_getTimeBasedGreeting()}, ${appProvider.userName}!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: isWide ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${appProvider.userRole} • Student ID: ${appProvider.studentId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: isWide ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Metrics pill tags
                    Wrap(
                      alignment: isWide
                          ? WrapAlignment.start
                          : WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _HeaderStatBadge(
                          icon: appProvider.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          label: appProvider.isDarkMode
                              ? 'Dark Mode'
                              : 'Light Mode',
                        ),
                        _HeaderStatBadge(
                          icon: Icons.palette_rounded,
                          label: appProvider.accentColor.label,
                        ),
                      ],
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      avatarWidget,
                      const SizedBox(width: 24),
                      Expanded(child: infoWidget),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white),
                        label: const Text('State Settings',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    avatarWidget,
                    const SizedBox(height: 16),
                    infoWidget,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderStatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
