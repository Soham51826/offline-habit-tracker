import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../core/app_constants.dart';

/// Archived Habits Vault — lists all soft-archived habits with
/// restore and permanent-delete options.
class ArchivedHabitsView extends StatefulWidget {
  const ArchivedHabitsView({super.key});

  @override
  State<ArchivedHabitsView> createState() => _ArchivedHabitsViewState();
}

class _ArchivedHabitsViewState extends State<ArchivedHabitsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitViewModel>().loadArchivedHabits();
    });
  }

  Future<void> _restore(String habitId, String title) async {
    final vm = context.read<HabitViewModel>();
    await vm.restoreHabit(habitId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('✅ "$title" restored to Today\'s checklist'),
        ),
      );
    }
  }

  Future<void> _delete(String habitId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text(
          'Delete "$title" and ALL its history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final vm = context.read<HabitViewModel>();
      await vm.deleteHabit(habitId);
      await vm.loadArchivedHabits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$title" permanently deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final archivedHabits = context.watch<HabitViewModel>().archivedHabits;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Archive Vault',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                '${archivedHabits.length} archived',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: archivedHabits.isEmpty
          ? _buildEmptyState(textMuted)
          : RefreshIndicator(
              onRefresh: () => context.read<HabitViewModel>().loadArchivedHabits(),
              color: const Color(0xFF10B981),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: archivedHabits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final h = archivedHabits[i];
                  final categoryInfo = AppConstants.getCategoryInfo(h.category);
                  final habitColor = Color(h.colorValue);

                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: habitColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  AppConstants.getIconData(h.iconName),
                                  color: habitColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Title + category
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(categoryInfo.icon, size: 12, color: textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          h.category,
                                          style: TextStyle(fontSize: 12, color: textMuted),
                                        ),
                                        if (h.isNegative) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              '🚫 Break Habit',
                                              style: TextStyle(fontSize: 10, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Archive badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '📦 Archived',
                                  style: TextStyle(fontSize: 11, color: textMuted),
                                ),
                              ),
                            ],
                          ),

                          if (h.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              h.description,
                              style: TextStyle(fontSize: 13, color: textMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _restore(h.id, h.title),
                                  icon: const Icon(Icons.restore_rounded, size: 16),
                                  label: const Text('Restore'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF10B981),
                                    side: const BorderSide(color: Color(0xFF10B981)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () => _delete(h.id, h.title),
                                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Archive Vault is Empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Archived habits appear here.\nSwipe left on a habit or tap the menu to archive it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
