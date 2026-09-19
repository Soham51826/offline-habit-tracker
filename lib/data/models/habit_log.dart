class HabitLog {
  final String id;
  final String habitId;
  final String date; // 'YYYY-MM-DD'
  final String status; // 'completed', 'skipped', 'failed'
  final int value; // e.g. 1 completion, or count like 5 glasses
  final String? notes;
  final DateTime loggedAt;
  final int? moodScore; // 1 (struggled) to 5 (effortless)

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.value = 1,
    this.notes,
    required this.loggedAt,
    this.moodScore,
  });

  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get isFailed => status == 'failed';

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? date,
    String? status,
    int? value,
    String? notes,
    DateTime? loggedAt,
    int? moodScore,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
      moodScore: moodScore ?? this.moodScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date,
      'status': status,
      'value': value,
      'notes': notes,
      'logged_at': loggedAt.toIso8601String(),
      'mood_score': moodScore,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: map['date'] as String,
      status: map['status'] as String,
      value: (map['value'] as int?) ?? 1,
      notes: map['notes'] as String?,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      moodScore: map['mood_score'] as int?,
    );
  }
}
