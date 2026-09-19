import 'package:flutter/material.dart';

class HabitCategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  const HabitCategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppConstants {
  static const List<HabitCategoryInfo> categories = [
    HabitCategoryInfo(
      name: 'Health & Wellness',
      icon: Icons.favorite_rounded,
      color: Color(0xFF10B981), // Emerald
    ),
    HabitCategoryInfo(
      name: 'Productivity & Focus',
      icon: Icons.laptop_chromebook_rounded,
      color: Color(0xFF6366F1), // Indigo
    ),
    HabitCategoryInfo(
      name: 'Mindfulness & Mental',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFFF59E0B), // Amber
    ),
    HabitCategoryInfo(
      name: 'Fitness & Movement',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFF43F5E), // Rose
    ),
    HabitCategoryInfo(
      name: 'Learning & Reading',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF06B6D4), // Cyan
    ),
    HabitCategoryInfo(
      name: 'Creativity & Arts',
      icon: Icons.palette_rounded,
      color: Color(0xFF8B5CF6), // Purple
    ),
  ];

  static const List<Color> habitColors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Rose
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF3B82F6), // Blue
  ];

  static const List<Map<String, dynamic>> habitIcons = [
    {'name': 'check_circle', 'icon': Icons.check_circle_outline_rounded},
    {'name': 'favorite', 'icon': Icons.favorite_rounded},
    {'name': 'laptop', 'icon': Icons.laptop_chromebook_rounded},
    {'name': 'self_improvement', 'icon': Icons.self_improvement_rounded},
    {'name': 'fitness_center', 'icon': Icons.fitness_center_rounded},
    {'name': 'menu_book', 'icon': Icons.menu_book_rounded},
    {'name': 'water_drop', 'icon': Icons.water_drop_rounded},
    {'name': 'bedtime', 'icon': Icons.bedtime_rounded},
    {'name': 'wb_sunny', 'icon': Icons.wb_sunny_rounded},
    {'name': 'directions_walk', 'icon': Icons.directions_walk_rounded},
    {'name': 'coffee', 'icon': Icons.local_cafe_rounded},
    {'name': 'timer', 'icon': Icons.timer_rounded},
  ];

  static IconData getIconData(String iconName) {
    for (final item in habitIcons) {
      if (item['name'] == iconName) {
        return item['icon'] as IconData;
      }
    }
    return Icons.check_circle_outline_rounded;
  }

  static HabitCategoryInfo getCategoryInfo(String categoryName) {
    return categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => categories.first,
    );
  }
}
