import 'package:flutter/material.dart';
import 'package:habit_tracker/data/repositories/habit_repository.dart';
import '../app_constants.dart';
import 'streak_badge.dart';

/// Interactive habit card featuring tactile micro-bounce check-ins,
/// swipe gestures, and sleek dark mode elevation.
class HabitCard extends StatefulWidget {
  final HabitWithLog item;
  final VoidCallback onToggle;
  final Function(int delta)? onProgressChange;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.item,
    required this.onToggle,
    this.onProgressChange,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTapToggle() async {
    await _bounceController.forward();
    await _bounceController.reverse();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.item.habit;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(habit.colorValue);
    final isCompleted = widget.item.isCompletedToday;
    final iconData = AppConstants.getIconData(habit.iconName);

    return Dismissible(
      key: Key('habit_${habit.id}_${widget.item.isCompletedToday}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to toggle completion
          widget.onToggle();
          return false; // Don't dismiss from tree
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left to delete
          widget.onDelete();
          return false; // Show confirm dialog before removing
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Check In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark
              ? (isCompleted
                  ? const Color(0xFF121B2B)
                  : const Color(0xFF141C2E))
              : (isCompleted
                  ? const Color(0xFFF1FDF5)
                  : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? habitColor.withValues(alpha: isDark ? 0.45 : 0.6)
                : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
            width: isCompleted ? 1.4 : 1.0,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: habitColor.withValues(alpha: isDark ? 0.18 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading Icon Container with subtle neon glow
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: habitColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: habitColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: habitColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title and Habit Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted
                                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                    : null,
                              ),
                            ),
                            if (habit.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                habit.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),

                            // Meta Tags: Category, Reminder time, Streak
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: habitColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    habit.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: habitColor,
                                    ),
                                  ),
                                ),
                                if (habit.reminderTime != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          habit.reminderTime!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (habit.hasLocation && habit.locationName != null && habit.locationName!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 11,
                                          color: Color(0xFF059669),
                                        ),
                                        const SizedBox(width: 3),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 120),
                                          child: Text(
                                            habit.locationName!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF059669),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                StreakBadge(
                                  streakDays: widget.item.stats.currentStreak,
                                  isSmall: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Tactile Micro-Bounce Checkmark Toggle Button
                      if (!habit.isNumeric)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isCompleted
                                  ? [
                                      BoxShadow(
                                        color: habitColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: IconButton(
                              onPressed: _handleTapToggle,
                              style: IconButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? habitColor
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                foregroundColor: isCompleted
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                side: BorderSide(
                                  color: isCompleted
                                      ? habitColor
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  width: 1.2,
                                ),
                              ),
                              icon: Icon(
                                isCompleted ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                      // Action Popup Menu
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') widget.onEdit();
                          if (val == 'delete') widget.onDelete();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Habit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Habit', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Numeric Habit Counter Controls
                  if (habit.isNumeric) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${widget.item.currentCount} / ${habit.targetCount} ${habit.unit}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${(widget.item.progressPercentage * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: widget.item.progressPercentage,
                                  minHeight: 7,
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                  color: isCompleted ? habitColor : habitColor.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Decrement Button
                        IconButton.outlined(
                          onPressed: () => widget.onProgressChange?.call(-1),
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          padding: const EdgeInsets.all(7),
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Increment Button with micro-bounce
                        IconButton.filled(
                          onPressed: () => widget.onProgressChange?.call(1),
                          style: IconButton.styleFrom(
                            backgroundColor: habitColor,
                            shadowColor: habitColor.withValues(alpha: 0.4),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          padding: const EdgeInsets.all(7),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
