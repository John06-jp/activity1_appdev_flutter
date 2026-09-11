import 'package:flutter/material.dart';

class ActivityTwoScreen extends StatefulWidget {
  const ActivityTwoScreen({super.key});

  @override
  State<ActivityTwoScreen> createState() => _ActivityTwoScreenState();
}

class _ActivityTwoScreenState extends State<ActivityTwoScreen> {
  final _quizController = TextEditingController(text: '85');
  final _examController = TextEditingController(text: '90');
  final _projectController = TextEditingController(text: '92');

  double _quizWeight = 0.3; // 30%
  double _examWeight = 0.5; // 50%
  double _projectWeight = 0.2; // 20%

  double _finalGrade = 0.0;
  String _gradeLetter = 'A';
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _calculateGrade();
  }

  void _calculateGrade() {
    final quiz = double.tryParse(_quizController.text) ?? 0;
    final exam = double.tryParse(_examController.text) ?? 0;
    final project = double.tryParse(_projectController.text) ?? 0;

    setState(() {
      _finalGrade =
          (quiz * _quizWeight) + (exam * _examWeight) + (project * _projectWeight);

      if (_finalGrade >= 90) {
        _gradeLetter = 'A (Excellent / High Honors)';
        _statusColor = Colors.green;
      } else if (_finalGrade >= 80) {
        _gradeLetter = 'B (Very Good / Honors)';
        _statusColor = Colors.blue;
      } else if (_finalGrade >= 75) {
        _gradeLetter = 'C (Satisfactory Pass)';
        _statusColor = Colors.orange;
      } else {
        _gradeLetter = 'F (Needs Improvement)';
        _statusColor = Colors.red;
      }
    });
  }

  @override
  void dispose() {
    _quizController.dispose();
    _examController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 2: Interactive Grade Estimator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calculate, color: Colors.teal, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Interactive Inputs & Math Computations',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score Inputs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 500;
                            final inputs = [
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: TextField(
                                  controller: _quizController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Quiz Score (0-100)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.quiz),
                                  ),
                                  onChanged: (_) => _calculateGrade(),
                                ),
                              ),
                              SizedBox(
                                  width: isWide ? 12 : 0,
                                  height: isWide ? 0 : 12),
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: TextField(
                                  controller: _examController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Exam Score (0-100)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.assignment),
                                  ),
                                  onChanged: (_) => _calculateGrade(),
                                ),
                              ),
                              SizedBox(
                                  width: isWide ? 12 : 0,
                                  height: isWide ? 0 : 12),
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: TextField(
                                  controller: _projectController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Project Score (0-100)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.laptop_mac),
                                  ),
                                  onChanged: (_) => _calculateGrade(),
                                ),
                              ),
                            ];

                            if (isWide) {
                              return Row(children: inputs);
                            }
                            return Column(
                              children: inputs
                                  .map((w) => w is Expanded ? w.child : w)
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Weight Allocation Slider',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Adjust Quiz weight (Exam & Project adjust proportionately):',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Slider(
                          value: _quizWeight,
                          min: 0.1,
                          max: 0.7,
                          divisions: 6,
                          label: '${(_quizWeight * 100).round()}% Quiz',
                          onChanged: (val) {
                            setState(() {
                              _quizWeight = val;
                              _examWeight = (1.0 - val) * 0.7;
                              _projectWeight = (1.0 - val) * 0.3;
                              _calculateGrade();
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quiz: ${(_quizWeight * 100).round()}%',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Exam: ${(_examWeight * 100).round()}%',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Project: ${(_projectWeight * 100).round()}%',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Calculation Result Card
                Card(
                  elevation: 4,
                  color: _statusColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Estimated Final Score',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _finalGrade.toStringAsFixed(1),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _gradeLetter,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
