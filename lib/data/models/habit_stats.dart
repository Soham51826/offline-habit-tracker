class HabitStats {
  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final double completionRate7Days;
  final double completionRate30Days;
  final double allTimeCompletionRate;
  final double consistencyScore; // 0.0 to 100.0
  final DateTime? lastCompletedDate;

  const HabitStats({
    required this.habitId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.completionRate7Days,
    required this.completionRate30Days,
    required this.allTimeCompletionRate,
    required this.consistencyScore,
    this.lastCompletedDate,
  });

  factory HabitStats.empty(String habitId) {
    return HabitStats(
      habitId: habitId,
      currentStreak: 0,
      longestStreak: 0,
      totalCompletions: 0,
      completionRate7Days: 0.0,
      completionRate30Days: 0.0,
      allTimeCompletionRate: 0.0,
      consistencyScore: 0.0,
      lastCompletedDate: null,
    );
  }
}
