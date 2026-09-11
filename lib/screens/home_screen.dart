import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_model.dart';
import '../providers/app_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/header_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Laboratory Portfolio'),
        actions: [
          IconButton(
            icon: Icon(
              appProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
            tooltip: 'Toggle Theme State',
            onPressed: () {
              appProvider.toggleTheme(!appProvider.isDarkMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'App State Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section displaying reactive User Profile state
                  const HeaderBanner(),
                  const SizedBox(height: 28),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laboratory Activities Compilation',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select an activity below to launch its interactive demo.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        avatar: Icon(Icons.check_circle,
                            size: 16, color: colorScheme.primary),
                        label: Text(
                          '${ActivityData.activities.length} Labs Available',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Responsive Layout: Grid for Wide screens, Column for Mobile
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;

                      if (isWide) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: ActivityData.activities.length,
                          itemBuilder: (context, index) {
                            final activity = ActivityData.activities[index];
                            return ActivityCard(
                              activity: activity,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, activity.routeName);
                              },
                            );
                          },
                        );
                      }

                      // Mobile Column layout
                      return Column(
                        children: ActivityData.activities.map((activity) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ActivityCard(
                              activity: activity,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, activity.routeName);
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Architecture Specs Summary Box
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.architecture_rounded,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Architecture & State Features',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FeatureBadge(
                                  label: 'Global State: Provider',
                                  icon: Icons.sync),
                              _FeatureBadge(
                                  label: 'Declarative Widgets',
                                  icon: Icons.layers),
                              _FeatureBadge(
                                  label: 'Responsive Layouts',
                                  icon: Icons.devices),
                              _FeatureBadge(
                                  label: 'Material 3 Themes',
                                  icon: Icons.palette),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/settings');
        },
        icon: const Icon(Icons.tune_rounded),
        label: const Text('State Settings'),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FeatureBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
    );
  }
}
