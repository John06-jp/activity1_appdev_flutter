import 'package:flutter/material.dart';
import '../../widgets/dashboard_feature_card.dart';

/// A reusable, static entry point shared by Home and the Activities tab.
class ActivityOneFeatureCard extends StatelessWidget {
  const ActivityOneFeatureCard({super.key});

  @override
  Widget build(BuildContext context) => DashboardFeatureCard(
    subtitle: 'Activity 1',
    title: 'Multi-Screen Navigation',
    description:
        'Open your activity dashboard and explore two interactive screens.',
    icon: Icons.dashboard_customize_rounded,
    gradientColors: const [Color(0xFF52639A), Color(0xFF52639A)],
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/activity-1'),
        builder: (_) => const MultiScreenNavigationScreen(),
      ),
    ),
  );
}

/// Static composition; interaction state belongs to each destination screen.
class MultiScreenNavigationScreen extends StatelessWidget {
  const MultiScreenNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Activity 1',
    children: [
      Text(
        'Your activity dashboard',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Choose an activity to get started. Each screen has its own interactive workspace.',
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _MenuCard(
              label: 'Activity screen 1',
              title: 'Tap Counter',
              description: 'Practice local state with a simple counter.',
              icon: Icons.touch_app_rounded,
              color: const Color(0xFF0B9D78),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/activity-1/counter'),
                  builder: (_) => const TapCounterScreen(),
                ),
              ),
            ),
            _MenuCard(
              label: 'Activity screen 2',
              title: 'Study Checklist',
              description: 'Track your progress through a study session.',
              icon: Icons.checklist_rounded,
              color: const Color(0xFF8754D8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/activity-1/checklist'),
                  builder: (_) => const StudyChecklistScreen(),
                ),
              ),
            ),
          ];
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          if (constraints.maxWidth < 640 || scale > 1.3) {
            return Column(
              children: [cards[0], const SizedBox(height: 16), cards[1]],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        },
      ),
    ],
  );
}

class TapCounterScreen extends StatefulWidget {
  const TapCounterScreen({super.key});

  @override
  State<TapCounterScreen> createState() => _TapCounterScreenState();
}

class _TapCounterScreenState extends State<TapCounterScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Tap Counter',
    children: [
      const Text('Activity screen 1'),
      const SizedBox(height: 12),
      Text(
        'Make every tap count',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text('Tap the button to update the counter on this screen.'),
      const SizedBox(height: 32),
      Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            '$_count taps',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => setState(() => _count++),
        icon: const Icon(Icons.add),
        label: const Text('Add a tap'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _count == 0 ? null : () => setState(() => _count = 0),
        child: const Text('Reset counter'),
      ),
    ],
  );
}

class StudyChecklistScreen extends StatefulWidget {
  const StudyChecklistScreen({super.key});

  @override
  State<StudyChecklistScreen> createState() => _StudyChecklistScreenState();
}

class _StudyChecklistScreenState extends State<StudyChecklistScreen> {
  static const _tasks = [
    'Review the lesson',
    'Practice building a widget',
    'Test on a different screen size',
  ];
  final Set<int> _completed = {};

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Study Checklist',
    children: [
      const Text('Activity screen 2'),
      const SizedBox(height: 12),
      Text(
        'One step at a time',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text('${_completed.length} of ${_tasks.length} completed'),
      const SizedBox(height: 16),
      LinearProgressIndicator(
        value: _completed.length / _tasks.length,
        semanticsLabel: 'Study progress',
      ),
      const SizedBox(height: 20),
      for (var i = 0; i < _tasks.length; i++)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(_tasks[i]),
          value: _completed.contains(i),
          onChanged: (checked) => setState(() {
            if (checked == true) {
              _completed.add(i);
            } else {
              _completed.remove(i);
            }
          }),
        ),
    ],
  );
}

/// Shared native layout: scroll on compact displays, constrain on desktops.
class _ActivityPage extends StatelessWidget {
  const _ActivityPage({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1A1F2E)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 14),
                Icon(Icons.arrow_forward_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
