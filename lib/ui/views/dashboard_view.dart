import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../core/widgets/habit_card.dart';
import '../core/widgets/progress_ring.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../../data/models/behavioral_insight.dart';
import 'add_edit_habit_view.dart';

/// Main interactive dashboard showcasing the horizontal calendar strip,
/// daily progress ring, urgent streak alerts, and staggered habit checklist.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  final DateFormat _dayFormat = DateFormat('E');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitViewModel>().loadHabits();
      context.read<InsightsViewModel>().runBehavioralAnalysis();
    });
  }

  void _showLogDetailDialog(BuildContext context, dynamic item) {
    final habit = item.habit;
    final log = item.log;
    final noteController = TextEditingController(text: log?.notes ?? '');
    int selectedMood = log?.moodScore ?? 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rate your effort / mood for today\'s session:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMoodOption(1, '😫', 'Struggled', selectedMood, (val) {
                        setModalState(() => selectedMood = val);
                      }),
                      _buildMoodOption(2, '😕', 'Hard', selectedMood, (val) {
                        setModalState(() => selectedMood = val);
                      }),
                      _buildMoodOption(3, '😐', 'Neutral', selectedMood, (val) {
                        setModalState(() => selectedMood = val);
                      }),
                      _buildMoodOption(4, '🙂', 'Good', selectedMood, (val) {
                        setModalState(() => selectedMood = val);
                      }),
                      _buildMoodOption(5, '🔥', 'Effortless', selectedMood, (val) {
                        setModalState(() => selectedMood = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Daily Reflection / Note (Optional)',
                      hintText: 'Add an optional reflection or note on obstacles/wins...',
                      helperText: 'Keep track of your thoughts and what helped you succeed',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<HabitViewModel>().toggleHabitCompletion(
                              habit.id,
                              moodScore: selectedMood,
                              notes: noteController.text.trim(),
                            );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(habit.colorValue),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        item.isCompletedToday ? 'Update Log & Mood' : 'Complete Habit & Log Note',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodOption(int score, String emoji, String label, int current, Function(int) onSelect) {
    final isSelected = score == current;
    return GestureDetector(
      onTap: () => onSelect(score),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final habitVm = context.watch<HabitViewModel>();
    final insightsVm = context.watch<InsightsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if any urgent streak risk alert exists
    final streakRiskInsight = insightsVm.insights.cast<BehavioralInsight?>().firstWhere(
      (i) => i?.severity == InsightSeverity.urgent,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authVm.userName.isNotEmpty && authVm.userName != 'Guest'
                  ? 'Hello, ${authVm.userName} 👋'
                  : 'HabitForge',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              _monthFormat.format(habitVm.selectedDate),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Habits & Insights',
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981)),
            onPressed: () async {
              await habitVm.loadHabits();
              await insightsVm.runBehavioralAnalysis();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habits and insights refreshed!')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72), // Leave clearance for floating nav
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditHabitView()),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await habitVm.loadHabits();
          await insightsVm.runBehavioralAnalysis();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Horizontal Date Strip with smooth selection
            _buildDateStrip(habitVm, isDark),
            const SizedBox(height: 16),

            // 2. High-Priority Streak Defense Alert (if urgent)
            if (streakRiskInsight != null) ...[
              _buildStreakRiskBanner(streakRiskInsight),
              const SizedBox(height: 16),
            ],

            // 3. Today's Progress Ring
            ProgressRing(
              percentage: habitVm.completionPercentage,
              completed: habitVm.totalCompletedCount,
              total: habitVm.totalScheduledCount,
            ),
            const SizedBox(height: 16),

            // 4. Category Filter Chips
            _buildCategoryFilters(habitVm, isDark),
            const SizedBox(height: 16),

            // 5. Staggered Animated Habits Checklist
            if (habitVm.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (habitVm.filteredHabits.isEmpty)
              _buildEmptyState(context, habitVm)
            else
              ...habitVm.filteredHabits.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return TweenAnimationBuilder<double>(
                  key: ValueKey('stagger_${item.habit.id}_${habitVm.selectedDate}'),
                  duration: Duration(milliseconds: 220 + (index * 60)),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1.0 - value) * 24),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: HabitCard(
                    item: item,
                    onToggle: () => habitVm.toggleHabitCompletion(item.habit.id),
                    onProgressChange: (delta) =>
                        habitVm.updateHabitProgress(item.habit.id, delta),
                    onTap: () => _showLogDetailDialog(context, item),
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditHabitView(habitToEdit: item.habit),
                        ),
                      );
                    },
                    onDelete: () => _showDeleteConfirmation(context, item.habit.id),
                  ),
                );
              }),

            const SizedBox(height: 110), // clearance for floating nav + FAB
          ],
        ),
      ),
    );
  }

  Widget _buildDateStrip(HabitViewModel habitVm, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 15,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: 7 - index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(habitVm.selectedDate);
          final isCurrentDay = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(today);

          return GestureDetector(
            onTap: () => habitVm.setSelectedDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF141C2E) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrentDay && !isSelected
                      ? const Color(0xFF10B981)
                      : (isSelected
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0))),
                  width: isCurrentDay ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayFormat.format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakRiskBanner(dynamic insight) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEF4444), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.actionableStep,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(HabitViewModel habitVm, bool isDark) {
    final categories = ['All', ...AppConstants.categories.map((c) => c.name)];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = habitVm.selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF10B981) : null,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => habitVm.setSelectedCategory(cat),
              backgroundColor: isDark ? const Color(0xFF141C2E) : const Color(0xFFF1F5F9),
              selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, HabitViewModel habitVm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.spa_rounded, size: 56, color: Color(0xFF10B981)),
            const SizedBox(height: 14),
            const Text(
              'No habits scheduled for this day',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create your first daily habit or tap below to explore with sample routines!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => habitVm.seedDemoData(),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Add Starter Habits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String habitId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: const Text('This will permanently delete this habit and all its past logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HabitViewModel>().deleteHabit(habitId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
