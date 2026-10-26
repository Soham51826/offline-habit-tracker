import 'package:flutter/material.dart';
import '../../data/repositories/habit_repository.dart';

/// Data class representing a single trophy/milestone badge.
class Achievement {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final bool isUnlocked;
  final String? unlockedOn; // Habit title or date

  const Achievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.isUnlocked,
    this.unlockedOn,
  });
}

/// Trophy Cabinet — showcases all milestone badges earned by the user across
/// all habits. Achievements are computed from live SQLite stats.
class AchievementsView extends StatefulWidget {
  const AchievementsView({super.key});

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView>
    with SingleTickerProviderStateMixin {
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeAchievements());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _computeAchievements() async {
    setState(() => _isLoading = true);
    final repo = HabitRepository();
    final habits = await repo.getAllHabits();

    final List<Achievement> unlocked = [];
    final List<Achievement> locked = [];

    int totalCompletions = 0;
    int habitsWithStreak7 = 0;
    int habitsWithStreak21 = 0;
    int habitsWithStreak66 = 0;
    int habitsWithStreak100 = 0;
    bool hasNegativeHabit = false;
    final hasGeofencedHabit = habits.any((h) => h.hasLocation);

    for (final habit in habits) {
      final stats = await repo.calculateStats(habit.id);
      totalCompletions += stats.totalCompletions;
      if (habit.isNegative) hasNegativeHabit = true;

      final milestones = [
        (7, '7-Day Warrior', '🔥', const Color(0xFFF59E0B)),
        (14, 'Two-Week Champion', '⚡', const Color(0xFF6366F1)),
        (21, 'Habit Formed (21 Days)', '🧠', const Color(0xFF10B981)),
        (30, '30-Day Legend', '🏅', const Color(0xFF0891B2)),
        (66, 'Automatic Pilot (66 Days)', '🚀', const Color(0xFF8B5CF6)),
        (100, '100-Day Elite', '💎', const Color(0xFFF43F5E)),
      ];

      for (final m in milestones) {
        final days = m.$1;
        final label = m.$2;
        final emo = m.$3;
        final col = m.$4;

        if (days == 7 && stats.currentStreak >= 7) habitsWithStreak7++;
        if (days == 21 && stats.currentStreak >= 21) habitsWithStreak21++;
        if (days == 66 && stats.currentStreak >= 66) habitsWithStreak66++;
        if (days == 100 && stats.currentStreak >= 100) habitsWithStreak100++;

        if (stats.longestStreak >= days) {
          unlocked.add(Achievement(
            id: '${habit.id}_streak_$days',
            title: label,
            subtitle: '"${habit.title}" reached a $days-day streak.',
            emoji: emo,
            color: col,
            isUnlocked: true,
            unlockedOn: habit.title,
          ));
        }
      }
    }

    // Global achievements
    final globalList = <Achievement>[];

    void addGlobal(String id, String title, String subtitle, String emoji, Color color, bool unlocked, [String? on]) {
      globalList.add(Achievement(
        id: id,
        title: title,
        subtitle: subtitle,
        emoji: emoji,
        color: color,
        isUnlocked: unlocked,
        unlockedOn: on,
      ));
    }

    addGlobal('first_habit', 'First Step', 'Created your first habit.',
        '🌱', const Color(0xFF10B981), habits.isNotEmpty);
    addGlobal('ten_habits', 'Habit Architect', 'Created 10 or more habits.',
        '🏗️', const Color(0xFF6366F1), habits.length >= 10);
    addGlobal('100_completions', 'Century Club', 'Completed habits 100 total times.',
        '💯', const Color(0xFFF59E0B), totalCompletions >= 100);
    addGlobal('500_completions', 'Relentless', 'Completed habits 500 total times.',
        '⚔️', const Color(0xFFF43F5E), totalCompletions >= 500);
    addGlobal('geofence', 'Location Scout', 'Attached a location geofence to a habit.',
        '📍', const Color(0xFF0891B2), hasGeofencedHabit);
    addGlobal('negative', 'Breaking Bad Habits', 'Created a negative habit tracker.',
        '🚫', const Color(0xFF8B5CF6), hasNegativeHabit);
    addGlobal('multi_streak_7', 'Multi-Warrior', '3+ habits with active 7-day streaks.',
        '🔥🔥🔥', const Color(0xFFF59E0B), habitsWithStreak7 >= 3);
    addGlobal('multi_streak_21', 'Habit Master', '2+ habits with 21-day formed streaks.',
        '🧠', const Color(0xFF10B981), habitsWithStreak21 >= 2);
    addGlobal('streak_66_any', 'Neuroscientist', 'Any habit hit 66 days (automaticity threshold).',
        '🧪', const Color(0xFF14B8A6), habitsWithStreak66 >= 1);
    addGlobal('century_streak', 'Centurion', 'Any habit with a 100-day streak.',
        '👑', const Color(0xFFEC4899), habitsWithStreak100 >= 1);

    for (final g in globalList) {
      if (g.isUnlocked) {
        unlocked.add(g);
      } else {
        locked.add(g);
      }
    }

    if (mounted) {
      setState(() {
        _achievements = [...unlocked, ...locked];
        _isLoading = false;
      });
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trophy Cabinet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            if (!_isLoading)
              Text(
                '$unlockedCount / ${_achievements.length} unlocked',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _computeAchievements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _achievements.isEmpty
              ? _buildEmptyState(textMuted)
              : RefreshIndicator(
                  onRefresh: _computeAchievements,
                  color: const Color(0xFF10B981),
                  child: CustomScrollView(
                    slivers: [
                      // Progress bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Achievement Progress',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: textMuted, fontSize: 13)),
                                  Text(
                                    '${(unlockedCount / _achievements.length * 100).toInt()}%',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _achievements.isEmpty
                                      ? 0
                                      : unlockedCount / _achievements.length,
                                  minHeight: 8,
                                  backgroundColor: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _achievements.any((a) => a.isUnlocked)
                                    ? '🏆 Unlocked'
                                    : 'No achievements yet — keep going!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // Unlocked Achievements Grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 225,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final a = _achievements[i];
                              if (!a.isUnlocked && i == _achievements.indexWhere((a) => !a.isUnlocked)) {
                                // Section header for locked
                                return const SizedBox.shrink();
                              }
                              return _buildAchievementCard(a, cardBg, textMuted, isDark, i);
                            },
                            childCount: _achievements.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Your Trophy Cabinet is Empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Start completing habits to earn achievements!',
              style: TextStyle(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement a, Color cardBg, Color textMuted, bool isDark, int index) {
    final delay = (index * 80).clamp(0, 600);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: a.isUnlocked
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: a.isUnlocked ? a.color.withValues(alpha: 0.35) : Colors.transparent,
            width: a.isUnlocked ? 1.5 : 0,
          ),
          boxShadow: a.isUnlocked
              ? [
                  BoxShadow(
                    color: a.color.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: a.isUnlocked
                    ? a.color.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  a.isUnlocked ? a.emoji : '🔒',
                  style: TextStyle(fontSize: a.isUnlocked ? 22 : 18),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              a.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: a.isUnlocked
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              a.isUnlocked ? (a.unlockedOn ?? a.subtitle) : a.subtitle,
              style: TextStyle(fontSize: 11, color: textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (a.isUnlocked) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Unlocked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: a.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
