import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/connection_status_chip.dart';
import '../widgets/dashboard_feature_card.dart';
import '../providers/network_health_provider.dart';
import '../services/network_diagnostics_service.dart';
import 'activities/multi_screen_navigation_screen.dart';
import 'activities/network_monitor_screen.dart';
import 'activities/network_diagnostics_dashboard_screen.dart';
import 'mesh_chat_screen.dart';
import 'activities/local_spots_screen.dart';

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
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = isDark
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
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
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: _currentIndex == 0,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Activities',
                    isSelected: _currentIndex == 1,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    isSelected: _currentIndex == 2,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
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
            textAlign: TextAlign.center,
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
// Global network health chip (broadcast app-wide)
// ─────────────────────────────────────────────
class _NetworkHealthChip extends StatelessWidget {
  final NetworkHealthTier tier;
  final VoidCallback onTap;

  const _NetworkHealthChip({required this.tier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = NetworkHealthTier.fromValue(tier.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, color: color, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                tier.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 13,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ],
        ),
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
    // App-wide network health broadcast from NetworkHealthProvider.
    final health = context.watch<NetworkHealthProvider>();

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hello, ${appProvider.userName} ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const ConnectionStatusChip(),
                      // Global network health indicator
                      _NetworkHealthChip(
                        tier: health.tier,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const NetworkDiagnosticsDashboardScreen(),
                            ),
                          );
                        },
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          appProvider.userName.isNotEmpty
                              ? appProvider.userName[0].toUpperCase()
                              : 'J',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Color.lerp(
                        Theme.of(context).colorScheme.primary,
                        Colors.white,
                        0.2,
                      )!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
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
                              '5',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (constraints.maxWidth >= 220)
                        Icon(
                          Icons.science_rounded,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 56,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Features section ───────────────────────────────────────
              Text(
                'Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              const ActivityOneFeatureCard(),
              const SizedBox(height: 12),
              const ActivityTwoFeatureCard(),
              const SizedBox(height: 12),
              const _CompiledActivityCards(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVITIES TAB
// ─────────────────────────────────────────────
class _CompiledActivityCards extends StatelessWidget {
  const _CompiledActivityCards();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      DashboardFeatureCard(
        icon: Icons.speed_rounded,
        title: 'Network Diagnostics',
        subtitle: 'Activity 3',
        description:
            'Run real-time network tests and monitor your connection quality live.',
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NetworkDiagnosticsDashboardScreen(),
          ),
        ),
      ),
      const SizedBox(height: 12),
      DashboardFeatureCard(
        icon: Icons.hub_rounded,
        title: 'Local Mesh Chat',
        subtitle: 'Activity 4',
        description:
            'Send messages between nearby devices using Bluetooth & Wi-Fi Direct.',
        gradientColors: const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeshChatScreen()),
        ),
      ),
      const SizedBox(height: 12),
      DashboardFeatureCard(
        icon: Icons.map_outlined,
        title: 'Bayugan Local Spots',
        subtitle: 'Activity 5',
        description:
            'Explore verified neighborhood spots and record entry and exit events.',
        gradientColors: const [Color(0xFF2E8B57), Color(0xFF217565)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LocalSpotsScreen()),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Activities')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ActivityOneFeatureCard(),
          SizedBox(height: 12),
          ActivityTwoFeatureCard(),
          SizedBox(height: 12),
          _CompiledActivityCards(),
        ],
      ),
    ),
  );
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
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
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      appProvider.userName.isNotEmpty
                          ? appProvider.userName[0].toUpperCase()
                          : 'J',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
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
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
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
                      horizontal: 18,
                      vertical: 6,
                    ),
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
                      horizontal: 18,
                      vertical: 14,
                    ),
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
                          activeThumbColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          onChanged: (val) => appProvider.toggleTheme(val),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme color',
                          style: TextStyle(color: textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppAccentColor.values.map((accent) {
                            return ChoiceChip(
                              label: Text(accent.label),
                              avatar: CircleAvatar(
                                radius: 8,
                                backgroundColor: accent.primary,
                              ),
                              selected: appProvider.accentColor == accent,
                              onSelected: (_) =>
                                  appProvider.setAccentColor(accent),
                            );
                          }).toList(),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 0, color: dividerColor),
      ],
    );
  }
}
