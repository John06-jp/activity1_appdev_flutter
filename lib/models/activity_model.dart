import 'package:flutter/material.dart';

class ActivityItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String routeName;
  final String category;
  final Color themeColor;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.routeName,
    required this.category,
    required this.themeColor,
  });
}

class ActivityData {
  static const List<ActivityItem> activities = [
    ActivityItem(
      id: 'act_1',
      title: 'Lab 1: Task & Counter Tracker',
      description:
          'Demonstrates local state management (StatefulWidget) with interactive counters, dynamic task list management, and real-time filtering.',
      icon: Icons.check_box_outlined,
      routeName: '/activity-1',
      category: 'Local State & UI',
      themeColor: Colors.blueAccent,
    ),
    ActivityItem(
      id: 'act_2',
      title: 'Lab 2: Interactive Grade Estimator',
      description:
          'Demonstrates responsive form inputs, numeric dynamic calculations, interactive slider feedback, and local state validation.',
      icon: Icons.calculate_outlined,
      routeName: '/activity-2',
      category: 'Forms & Logic',
      themeColor: Colors.teal,
    ),
  ];
}
