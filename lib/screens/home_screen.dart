import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_model.dart';
import '../providers/app_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/header_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<ActivityItem> get _filteredActivities {
    return ActivityData.activities.where((activity) {
      final matchesQuery = activity.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          activity.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          activity.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.apps_rounded,
                  color: colorScheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Portfolio Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              appProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
            tooltip: appProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
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
                  // Hero Header Banner
                  const HeaderBanner(),
                  const SizedBox(height: 28),

                  // Search and Filters Section
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search laboratory activities...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                'All',
                                'Local State & UI',
                                'Forms & Logic'
                              ].map((category) {
                                final isSelected =
                                    _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                    selectedColor: colorScheme.primaryContainer,
                                    checkmarkColor:
                                        colorScheme.onPrimaryContainer,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laboratory Compilation',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap any card to launch its interactive Flutter screen.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_filteredActivities.length} Loaded',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Responsive Activities View
                  _filteredActivities.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 48, color: colorScheme.outline),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No activities found matching "$_searchQuery"',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try searching with a different term or clear filters.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : LayoutBuilder(
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
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: _filteredActivities.length,
                                itemBuilder: (context, index) {
                                  final activity = _filteredActivities[index];
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

                            return Column(
                              children: _filteredActivities.map((activity) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: SizedBox(
                                    height: 250,
                                    child: ActivityCard(
                                      activity: activity,
                                      onTap: () {
                                        Navigator.pushNamed(
                                            context, activity.routeName);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                  const SizedBox(height: 28),

                  // System Specs Box
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded,
                              color: colorScheme.primary, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Global App State Active',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'State updates via Provider stream instantly across all routes in real-time.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
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
        elevation: 4,
      ),
    );
  }
}
