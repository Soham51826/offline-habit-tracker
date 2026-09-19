/// Behavioral Psychology Heuristics & Local Cognitive Templates
/// Formats raw algorithmic findings into structured, empathetic coach insights.
class LocalCoachPrompts {
  static Map<String, String> formatHabitStacking({
    required String anchorHabitTitle,
    required String targetHabitTitle,
    required double anchorConsistency,
    required double targetConsistency,
  }) {
    return {
      'title': '🔗 Habit Stacking Opportunity: $targetHabitTitle',
      'message': 'You have an outstanding ${(anchorConsistency * 100).toInt()}% consistency with "$anchorHabitTitle", while "$targetHabitTitle" is currently at ${(targetConsistency * 100).toInt()}%. By anchoring your new behavior to an already automated neurological circuit, you remove decision friction.',
      'actionable_step': 'Formula: "Immediately after I finish $anchorHabitTitle, I will do $targetHabitTitle for just 2 minutes."',
      'psychology_principle': 'James Clear: Implementation Intentions & Neural Piggybacking',
    };
  }

  static Map<String, String> formatWeekendSlump({
    required String habitTitle,
    required double weekdayRate,
    required double weekendRate,
    required double dropPercent,
  }) {
    return {
      'title': '📉 Weekend Slump Detected: $habitTitle',
      'message': 'Your completion rate drops from ${(weekdayRate * 100).toInt()}% on weekdays down to ${(weekendRate * 100).toInt()}% on weekends (a ${dropPercent.toInt()}% drop). Weekends break workday environmental cues, creating cognitive drift.',
      'actionable_step': 'Adopt a Weekend Minimum Viable Habit (MVH): On Saturday & Sunday, reduce the requirement by 75% to preserve the neural loop without burnout.',
      'psychology_principle': 'BJ Fogg Tiny Habits: Scaled Ability & Context Flexibility',
    };
  }

  static Map<String, String> formatOptimalTiming({
    required String habitTitle,
    required String bestWindowName,
    required double bestRate,
    required String worstWindowName,
    required double worstRate,
  }) {
    return {
      'title': '⏰ Circadian Friction Alert: $habitTitle',
      'message': 'Logs show a ${(bestRate * 100).toInt()}% success rate during $bestWindowName, compared to only ${(worstRate * 100).toInt()}% during $worstWindowName. Willpower depletes progressively throughout the day (ego depletion).',
      'actionable_step': 'Shift "$habitTitle" into your peak $bestWindowName window before decision fatigue sets in.',
      'psychology_principle': 'Roy Baumeister: Ego Depletion & Chronobiology Alignment',
    };
  }

  static Map<String, String> formatStreakAtRisk({
    required String habitTitle,
    required int streakDays,
  }) {
    return {
      'title': '🔥 Streak Defense Alert: $habitTitle',
      'message': 'You have an active $streakDays-day streak on "$habitTitle" that is uncompleted today. The psychological pain of breaking a momentum chain triggers the "what-the-hell" effect.',
      'actionable_step': 'Do the "2-Minute Rule" check-in right now: Complete the absolute minimum version to keep the streak flame alive!',
      'psychology_principle': 'Daniel Kahneman: Loss Aversion & Momentum Preservation',
    };
  }

  static Map<String, String> formatNeverMissTwice({
    required String habitTitle,
  }) {
    return {
      'title': '🛡️ "Never Miss Twice" Recovery: $habitTitle',
      'message': 'You missed "$habitTitle" yesterday. In behavioral psychology, missing one day is an outlier; missing two consecutive days begins the formation of a counter-habit.',
      'actionable_step': 'Prioritize "$habitTitle" before noon today. Even a 30-second token action resets your identity commitment.',
      'psychology_principle': 'James Clear: "Never Miss Twice" Identity Rule',
    };
  }

  static Map<String, String> formatCognitiveOverload({
    required int totalHabits,
    required double overallRate,
  }) {
    return {
      'title': '⚠️ Cognitive Load Warning: $totalHabits Active Habits',
      'message': 'Tracking $totalHabits daily habits simultaneously has decreased your overall completion rate to ${(overallRate * 100).toInt()}%. High cognitive switching costs cause habit abandonment.',
      'actionable_step': 'Identify 2 "Keystone Habits" and put the rest on maintenance mode (2-minute scale) for the next 7 days.',
      'psychology_principle': 'George Miller: Working Memory Limits & Keystone Habit Focus',
    };
  }

  static Map<String, String> formatMilestoneCelebration({
    required String habitTitle,
    required int streakDays,
  }) {
    String thresholdNote = 'Great momentum!';
    if (streakDays >= 66) {
      thresholdNote = 'Psychological milestone reached: 66 days is the average scientific threshold for true automaticity (Lally et al., 2009).';
    } else if (streakDays >= 21) {
      thresholdNote = '21 days achieved: Strong synaptic consolidation has begun.';
    } else if (streakDays >= 7) {
      thresholdNote = 'Full week milestone: You have successfully navigated weekend resistance.';
    }

    return {
      'title': '🎉 $streakDays-Day Streak Milestone: $habitTitle',
      'message': '$thresholdNote Your procedural memory is now running "$habitTitle" with significantly reduced conscious effort.',
      'actionable_step': 'Celebrate this identity shift! Acknowledge yourself as someone who naturally practices $habitTitle.',
      'psychology_principle': 'Dr. Phillippa Lally: Habit Automaticity Curve',
    };
  }
}
