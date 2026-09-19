import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int streakDays;
  final bool isAtRisk;
  final bool isSmall;

  const StreakBadge({
    super.key,
    required this.streakDays,
    this.isAtRisk = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (streakDays <= 0) {
      return const SizedBox.shrink();
    }

    final isThemeDark = Theme.of(context).brightness == Brightness.dark;
    final flameColor = isAtRisk
        ? const Color(0xFFEF4444)
        : (streakDays >= 21
            ? const Color(0xFFF59E0B)
            : const Color(0xFFF97316));

    final bgColor = flameColor.withValues(alpha: isThemeDark ? 0.2 : 0.12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flameColor.withValues(alpha: isAtRisk ? 0.8 : 0.4),
          width: isAtRisk ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAtRisk ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
            size: isSmall ? 14 : 16,
            color: flameColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$streakDays ${streakDays == 1 ? 'day' : 'days'}',
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: flameColor,
            ),
          ),
        ],
      ),
    );
  }
}
