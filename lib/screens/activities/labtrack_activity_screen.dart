import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../providers/app_provider.dart';

class LabTrackActivityScreen extends StatefulWidget {
  final ActivityItem activity;

  const LabTrackActivityScreen({super.key, required this.activity});

  @override
  State<LabTrackActivityScreen> createState() =>
      _LabTrackActivityScreenState();
}

class _LabTrackActivityScreenState extends State<LabTrackActivityScreen> {
  late List<ActivityTask> _tasks;

  @override
  void initState() {
    super.initState();
    // Clone tasks so toggling is local state
    _tasks = widget.activity.tasks
        .map((t) => ActivityTask(title: t.title, isCompleted: t.isCompleted))
        .toList();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;
    final activity = widget.activity;

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          activity.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity header card
            Container(
              padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: activity.themeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(activity.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activity.subtitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tasks card
            Container(
              padding: const EdgeInsets.all(20),
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
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(_tasks.length, (index) {
                    final task = _tasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () => _toggleTask(index),
                        child: Row(
                          children: [
                            // Circle checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? activity.themeColor
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: task.isCompleted
                                      ? activity.themeColor
                                      : (isDark
                                          ? const Color(0xFF4B5563)
                                          : const Color(0xFFD1D5DB)),
                                  width: 2,
                                ),
                              ),
                              child: task.isCompleted
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '${index + 1}. ${task.title}',
                              style: TextStyle(
                                fontSize: 15,
                                color: task.isCompleted
                                    ? textSecondary
                                    : textPrimary,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // View Details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6FE8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Viewing details for ${activity.subtitle}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
