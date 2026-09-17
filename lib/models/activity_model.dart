import 'package:flutter/material.dart';

class ActivityTask {
  final String title;
  bool isCompleted;

  ActivityTask({required this.title, this.isCompleted = false});
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String routeName;
  final Color themeColor;
  final List<ActivityTask> tasks;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.routeName,
    required this.themeColor,
    required this.tasks,
  });
}

class ActivityData {
  static List<ActivityItem> get activities => [
        ActivityItem(
          id: 'act_1',
          title: 'Activity 1',
          subtitle: 'Data Structures',
          description:
              'Implement basic data structures and algorithms.',
          icon: Icons.code_rounded,
          routeName: '/activity-1',
          themeColor: const Color(0xFF10B981),
          tasks: [
            ActivityTask(title: 'Arrays and Lists', isCompleted: true),
            ActivityTask(title: 'Stacks and Queues', isCompleted: true),
            ActivityTask(title: 'Trees and Graphs', isCompleted: false),
            ActivityTask(title: 'Sorting and Searching', isCompleted: false),
          ],
        ),
        ActivityItem(
          id: 'act_2',
          title: 'Activity 2',
          subtitle: 'Web Development',
          description:
              'Build a simple responsive web application.',
          icon: Icons.language_rounded,
          routeName: '/activity-2',
          themeColor: const Color(0xFF8B5CF6),
          tasks: [
            ActivityTask(title: 'HTML & CSS Basics', isCompleted: true),
            ActivityTask(title: 'JavaScript Fundamentals', isCompleted: true),
            ActivityTask(title: 'API Integration', isCompleted: false),
            ActivityTask(title: 'Deployment', isCompleted: false),
          ],
        ),
        ActivityItem(
          id: 'act_3',
          title: 'Activity 3',
          subtitle: 'Mobile Development',
          description:
              'Create a cross-platform mobile application using Flutter.',
          icon: Icons.phone_android_rounded,
          routeName: '/activity-3',
          themeColor: const Color(0xFFF59E0B),
          tasks: [
            ActivityTask(title: 'Flutter Basics', isCompleted: true),
            ActivityTask(title: 'State Management', isCompleted: false),
            ActivityTask(title: 'Navigation', isCompleted: false),
            ActivityTask(title: 'API & Backend', isCompleted: false),
          ],
        ),
        ActivityItem(
          id: 'act_4',
          title: 'Activity 4',
          subtitle: 'Machine Learning',
          description:
              'Build and train basic machine learning models.',
          icon: Icons.psychology_rounded,
          routeName: '/activity-4',
          themeColor: const Color(0xFFEF4444),
          tasks: [
            ActivityTask(title: 'Data Preprocessing', isCompleted: false),
            ActivityTask(title: 'Model Training', isCompleted: false),
            ActivityTask(title: 'Evaluation Metrics', isCompleted: false),
            ActivityTask(title: 'Model Deployment', isCompleted: false),
          ],
        ),
      ];
}
