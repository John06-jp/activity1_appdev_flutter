import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HeaderBanner extends StatelessWidget {
  const HeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appProvider = context.watch<AppProvider>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            final avatarWidget = CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.primary,
              child: Text(
                appProvider.userName.isNotEmpty
                    ? appProvider.userName[0].toUpperCase()
                    : 'S',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
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
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Master Compilation App',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      appProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, ${appProvider.userName}!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  textAlign: isWide ? TextAlign.left : TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${appProvider.userRole} • ID: ${appProvider.studentId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                  textAlign: isWide ? TextAlign.left : TextAlign.center,
                ),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  avatarWidget,
                  const SizedBox(width: 20),
                  Expanded(child: infoWidget),
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'State Settings',
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
    );
  }
}
