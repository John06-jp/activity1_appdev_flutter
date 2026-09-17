import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/activity_model.dart';
import 'activities/labtrack_activity_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;

    final screens = [
      const HomeTab(),
      const ActivitiesTab(),
      const SettingsTab(),
    ];

    final navBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final selectedColor = const Color(0xFF3B6FE8);
    final unselectedColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Activities',
                  isSelected: _currentIndex == 1,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: _currentIndex == 2,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? selectedColor : unselectedColor,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? selectedColor : unselectedColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;
    final activities = ActivityData.activities;

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hello, ${appProvider.userName} ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome back to your lab activities!',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.settings_outlined,
                            color: textSecondary, size: 22),
                        onPressed: () {},
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF3B6FE8),
                        child: Text(
                          appProvider.userName.isNotEmpty
                              ? appProvider.userName[0].toUpperCase()
                              : 'J',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Activities Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B6FE8), Color(0xFF6B8FF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Activities',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${activities.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.science_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 56,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Activities label
              Text(
                'Activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 2x2 grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
                children: activities.map((activity) {
                  return _ActivityGridCard(
                    activity: activity,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LabTrackActivityScreen(
                            activity: activity,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityGridCard extends StatelessWidget {
  final ActivityItem activity;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ActivityGridCard({
    required this.activity,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activity.themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(activity.icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(
              activity.title,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              activity.subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVITIES TAB
// ─────────────────────────────────────────────
class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;
    final activities = ActivityData.activities;

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Activities',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final activity = activities[index];
          final completedCount =
              activity.tasks.where((t) => t.isCompleted).length;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabTrackActivityScreen(activity: activity),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activity.themeColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(activity.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        Text(
                          activity.subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount/${activity.tasks.length} tasks done',
                          style: TextStyle(
                            fontSize: 12,
                            color: activity.themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: textSecondary, size: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SETTINGS TAB
// ─────────────────────────────────────────────
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF3B6FE8),
                    child: Text(
                      appProvider.userName.isNotEmpty
                          ? appProvider.userName[0].toUpperCase()
                          : 'J',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appProvider.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        appProvider.userRole,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Theme card
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Switch(
                          value: isDark,
                          activeColor: const Color(0xFF3B6FE8),
                          onChanged: (val) => appProvider.toggleTheme(val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu items
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SettingsMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () {
                      _showEditProfileDialog(context, appProvider);
                    },
                  ),
                  _SettingsMenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About App',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'LabTrack',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2024 LabTrack',
                      );
                    },
                  ),
                  _SettingsMenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    iconColor: Colors.redAccent,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    showDivider: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppProvider appProvider) {
    final nameCtrl = TextEditingController(text: appProvider.userName);
    final roleCtrl = TextEditingController(text: appProvider.userRole);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appProvider.updateProfile(
                name: nameCtrl.text,
                role: roleCtrl.text,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final bool showDivider;
  final VoidCallback onTap;

  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.showDivider,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? textSecondary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: iconColor ?? textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: textSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 0, color: dividerColor),
      ],
    );
  }
}
