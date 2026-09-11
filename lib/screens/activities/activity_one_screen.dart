import 'package:flutter/material.dart';

class ActivityOneScreen extends StatefulWidget {
  const ActivityOneScreen({super.key});

  @override
  State<ActivityOneScreen> createState() => _ActivityOneScreenState();
}

class TaskItem {
  final String id;
  final String title;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class _ActivityOneScreenState extends State<ActivityOneScreen> {
  int _counter = 0;
  final TextEditingController _taskController = TextEditingController();
  final List<TaskItem> _tasks = [
    TaskItem(id: '1', title: 'Setup Flutter Project & Provider', isCompleted: true),
    TaskItem(id: '2', title: 'Implement Responsive Navigation Routes', isCompleted: true),
    TaskItem(id: '3', title: 'Test Dark/Light Theme Switching', isCompleted: false),
  ];
  String _filter = 'All';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_counter > 0) _counter--;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks.add(
        TaskItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
        ),
      );
      _taskController.clear();
    });
  }

  void _toggleTask(String id) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == id);
      task.isCompleted = !task.isCompleted;
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
  }

  List<TaskItem> get _filteredTasks {
    if (_filter == 'Active') {
      return _tasks.where((t) => !t.isCompleted).toList();
    } else if (_filter == 'Completed') {
      return _tasks.where((t) => t.isCompleted).toList();
    }
    return _tasks;
  }

  double get _completionRatio {
    if (_tasks.isEmpty) return 0.0;
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    return completedCount / _tasks.length;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completedCount = _tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 1: Task & Counter Tracker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'LOCAL STATE MANAGEMENT (StatefulWidget)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 1: Counter Component
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interactive Counter Widget',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.primaryContainer
                                    .withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stateful Counter',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Text(
                                    'Local setState()',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$_counter',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _decrementCounter,
                                icon: const Icon(Icons.remove_rounded),
                                label: const Text('Decrement'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _resetCounter,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _incrementCounter,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Increment'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card 2: Dynamic Task Manager with Progress Indicator
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dynamic Task Manager',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$completedCount / ${_tasks.length} Done',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _completionRatio,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Input field row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _taskController,
                                decoration: InputDecoration(
                                  hintText: 'Enter new activity task...',
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: (_) => _addTask(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _addTask,
                              icon: const Icon(Icons.add_task_rounded),
                              label: const Text('Add Task'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Filter choices
                        Row(
                          children: ['All', 'Active', 'Completed'].map((filter) {
                            final isSelected = _filter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _filter = filter;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 28),

                        // Task items list
                        _filteredTasks.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.checklist_rounded,
                                          size: 40,
                                          color: colorScheme.outline),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No tasks found in "$_filter"',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = _filteredTasks[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        key: ValueKey(task.id),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        title: Text(
                                          task.title,
                                          style: TextStyle(
                                            decoration: task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: task.isCompleted
                                                ? colorScheme.outline
                                                : colorScheme.onSurface,
                                            fontWeight: task.isCompleted
                                                ? FontWeight.normal
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        value: task.isCompleted,
                                        onChanged: (_) => _toggleTask(task.id),
                                        secondary: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              _deleteTask(task.id),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
