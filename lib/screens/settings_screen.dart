import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    final appProvider = context.read<AppProvider>();
    _nameController = TextEditingController(text: appProvider.userName);
    _roleController = TextEditingController(text: appProvider.userRole);
    _idController = TextEditingController(text: appProvider.studentId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    context.read<AppProvider>().updateProfile(
          name: _nameController.text,
          role: _roleController.text,
          studentId: _idController.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Global User Profile updated & synced!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global State Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global App State Controls',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modify global state variables managed by Provider. Updates reflect instantly across all screens.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Card 1: Theme Mode Switcher
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                appProvider.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Theme Appearance Mode',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _ThemeChoiceCard(
                                title: 'Light',
                                icon: Icons.light_mode_rounded,
                                isSelected:
                                    appProvider.themeMode == ThemeMode.light,
                                onTap: () =>
                                    appProvider.setThemeMode(ThemeMode.light),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ThemeChoiceCard(
                                title: 'Dark',
                                icon: Icons.dark_mode_rounded,
                                isSelected:
                                    appProvider.themeMode == ThemeMode.dark,
                                onTap: () =>
                                    appProvider.setThemeMode(ThemeMode.dark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ThemeChoiceCard(
                                title: 'System',
                                icon: Icons.brightness_auto_rounded,
                                isSelected:
                                    appProvider.themeMode == ThemeMode.system,
                                onTap: () =>
                                    appProvider.setThemeMode(ThemeMode.system),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card 2: Accent Color Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.palette_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Accent Color Scheme',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: AppAccentColor.values.map((colorItem) {
                            final isSelected =
                                appProvider.accentColor == colorItem;
                            return InkWell(
                              onTap: () =>
                                  appProvider.setAccentColor(colorItem),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorItem.primary.withValues(alpha: 0.15)
                                      : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorItem.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: colorItem.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      colorItem.label,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card 3: Profile State Editor & Avatar Picker
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.badge_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Global User Profile State',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Avatar Picker Row
                        Text(
                          'Select Profile Avatar Icon:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(
                            AppProvider.avatarIcons.length,
                            (index) {
                              final iconData = AppProvider.avatarIcons[index];
                              final isSelected =
                                  appProvider.avatarIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: InkWell(
                                  onTap: () =>
                                      appProvider.setAvatarIndex(index),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.surfaceContainerHighest,
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Developer Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _roleController,
                          decoration: const InputDecoration(
                            labelText: 'Designation / Role',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: 'Student / Lab ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save Profile State'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChoiceCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
