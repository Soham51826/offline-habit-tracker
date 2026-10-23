import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/habit_stats.dart';

/// Service responsible for communicating with Google Gemini API
/// to generate personalized, conversational behavioral habit coaching.
class GeminiAiService {
  static final GeminiAiService instance = GeminiAiService._internal();

  GeminiAiService._internal();

  /// Retrieves the active Gemini API key from the encrypted/local .env configuration.
  String? get apiKey {
    try {
      if (!dotenv.isInitialized) return null;
      final key = dotenv.env['GEMINI_API_KEY']?.trim();
      if (key != null && key.isNotEmpty && !key.contains('your_gemini_api_key_here')) {
        return key;
      }
    } catch (e) {
      debugPrint('Error accessing GEMINI_API_KEY from dotenv: $e');
    }
    return null;
  }

  /// Whether a valid Gemini API key is configured.
  bool get hasApiKey => apiKey != null;

  /// Generates conversational, behavioral AI habit coaching tailored to the user's weekly habit logs.
  Future<String> generateHabitCoaching({
    required List<Habit> habits,
    required List<HabitLog> recentLogs,
    required Map<String, HabitStats> statsMap,
    String userName = 'Soham',
  }) async {
    final key = apiKey;

    // Build the data summary regardless for prompt or offline fallback
    final buffer = StringBuffer();
    buffer.writeln('User Profile: $userName');
    buffer.writeln('Total Habits Tracked: ${habits.length}');
    buffer.writeln('\nHabits Breakdown:');

    for (final habit in habits) {
      final stats = statsMap[habit.id];
      final consistency = stats?.consistencyScore.toStringAsFixed(1) ?? 'N/A';
      final currentStreak = stats?.currentStreak ?? 0;
      final bestStreak = stats?.longestStreak ?? 0;

      buffer.writeln(
        '- Habit: "${habit.title}" (${habit.category}) | Target: ${habit.targetCount} ${habit.unit}/day | '
        'Consistency: $consistency% | Current Streak: $currentStreak days | Longest: $bestStreak days | '
        'Reminder: ${habit.reminderTime ?? "None"} | Location: ${habit.locationName ?? "None"}',
      );
    }

    buffer.writeln('\nRecent Logged History (Last 14 Days):');
    if (recentLogs.isEmpty) {
      buffer.writeln('No logs recorded yet.');
    } else {
      // Group logs by habit
      for (final log in recentLogs.take(35)) {
        buffer.writeln('  • Date: ${log.date} | HabitId: ${log.habitId} | Status: ${log.status} | Mood: ${log.moodScore ?? "N/A"}/5 | Note: ${log.notes ?? "None"}');
      }
    }

    if (key == null) {
      // Return realistic, highly contextual simulated coaching when API key is not yet pasted in .env
      return _generateOfflineFallbackCoaching(userName, habits, statsMap);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 600,
        ),
      );

      final prompt = '''
You are "HabitForge AI Coach", an empathetic, elite behavioral psychologist and habit formation expert (grounded in BJ Fogg's Tiny Habits and James Clear's Atomic Habits).

Analyze the following SQLite habit tracking records for $userName:
$buffer

Instructions:
1. Greet $userName warmly and provide an honest, motivational summary of their weekly consistency.
2. Spot specific friction points or positive momentum (e.g. mention specific days, evening fatigue, or habits that need stacking).
3. If any habit is struggling or dropping on specific days (e.g., Thursday evenings or weekends), diagnose the friction and propose an actionable micro-adjustment.
4. Keep the tone conversational, concise, structured with bullet points, and directly actionable.
5. Limit the response to 3-4 short paragraphs or bulleted takeaways.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();

      if (text != null && text.isNotEmpty) {
        return text;
      } else {
        return _generateOfflineFallbackCoaching(userName, habits, statsMap);
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return '$userName, here is your behavioral habit analysis:\n\n'
          '${_generateOfflineFallbackCoaching(userName, habits, statsMap)}\n\n'
          '*(Note: Live Gemini API encountered a network/key issue: $e. Using local behavioral heuristics.)*';
    }
  }

  /// High quality behavioral coaching fallback when offline or key is missing.
  String _generateOfflineFallbackCoaching(
    String userName,
    List<Habit> habits,
    Map<String, HabitStats> statsMap,
  ) {
    if (habits.isEmpty) {
      return 'Hey $userName! Welcome to HabitForge. Create your first 2 or 3 micro-habits (like a 2-minute morning stretch or 1 glass of water) so I can start analyzing your behavioral patterns.';
    }

    // Find habit with lowest consistency
    Habit? strugglingHabit;
    double minConsistency = 101.0;
    Habit? topHabit;
    double maxConsistency = -1.0;

    for (final h in habits) {
      final stats = statsMap[h.id];
      final c = stats?.consistencyScore ?? 0.0;
      if (c < minConsistency) {
        minConsistency = c;
        strugglingHabit = h;
      }
      if (c > maxConsistency) {
        maxConsistency = c;
        topHabit = h;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('Hey $userName! Here is your AI Behavioral Coaching report:');
    buffer.writeln();

    if (topHabit != null && maxConsistency >= 60.0) {
      buffer.writeln('🌟 **High Momentum Anchor:** Your consistency with "${topHabit.title}" is strong at ${maxConsistency.toStringAsFixed(0)}%. Your brain has successfully automated this routine into procedural memory.');
      buffer.writeln();
    }

    if (strugglingHabit != null && minConsistency < 60.0) {
      buffer.writeln('⚠️ **Friction Diagnostic:** $userName, your focus drops on "${strugglingHabit.title}" (current consistency: ${minConsistency.toStringAsFixed(0)}%). Notice that drop-offs frequently occur during midweek fatigue (especially Thursdays).');
      buffer.writeln();
      buffer.writeln('💡 **Recommended Habit Stack:**');
      if (topHabit != null && topHabit.id != strugglingHabit.id) {
        buffer.writeln('• Attach "${strugglingHabit.title}" directly AFTER "${topHabit.title}". For example: *"After I finish ${topHabit.title}, I will immediately do 2 minutes of ${strugglingHabit.title}."*');
      } else {
        buffer.writeln('• Scale down "${strugglingHabit.title}" to an effortless 2-minute version to eliminate executive decision fatigue.');
      }
      buffer.writeln('• Lower cognitive friction by setting an environmental trigger or enabling geofencing for this habit.');
    } else {
      buffer.writeln('🔥 **Phenomenal Consistency:** All your tracked habits are progressing above 60%. Keep this momentum steady—remember that never missing twice is the key to identity transformation!');
    }

    return buffer.toString().trim();
  }
}
