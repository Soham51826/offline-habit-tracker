enum InsightType {
  habitStacking,
  weekendSlump,
  optimalTiming,
  streakRisk,
  overloadWarning,
  momentumMilestone,
  recoveryOpportunity;

  String get name => toString().split('.').last;
}

enum InsightSeverity {
  urgent,
  warning,
  suggestion,
  celebration;

  String get name => toString().split('.').last;
}

class BehavioralInsight {
  final String id;
  final String? habitId;
  final InsightType type;
  final String title;
  final String message;
  final String actionableStep;
  final String psychologyPrinciple;
  final InsightSeverity severity;
  final DateTime generatedAt;
  final bool isDismissed;

  const BehavioralInsight({
    required this.id,
    this.habitId,
    required this.type,
    required this.title,
    required this.message,
    required this.actionableStep,
    required this.psychologyPrinciple,
    required this.severity,
    required this.generatedAt,
    this.isDismissed = false,
  });

  BehavioralInsight copyWith({
    String? id,
    String? habitId,
    InsightType? type,
    String? title,
    String? message,
    String? actionableStep,
    String? psychologyPrinciple,
    InsightSeverity? severity,
    DateTime? generatedAt,
    bool? isDismissed,
  }) {
    return BehavioralInsight(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actionableStep: actionableStep ?? this.actionableStep,
      psychologyPrinciple: psychologyPrinciple ?? this.psychologyPrinciple,
      severity: severity ?? this.severity,
      generatedAt: generatedAt ?? this.generatedAt,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'type': type.name,
      'title': title,
      'message': message,
      'actionable_step': actionableStep,
      'psychology_principle': psychologyPrinciple,
      'severity': severity.name,
      'generated_at': generatedAt.toIso8601String(),
      'is_dismissed': isDismissed ? 1 : 0,
    };
  }

  factory BehavioralInsight.fromMap(Map<String, dynamic> map) {
    return BehavioralInsight(
      id: map['id'] as String,
      habitId: map['habit_id'] as String?,
      type: InsightType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InsightType.habitStacking,
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      actionableStep: map['actionable_step'] as String,
      psychologyPrinciple: map['psychology_principle'] as String,
      severity: InsightSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => InsightSeverity.suggestion,
      ),
      generatedAt: DateTime.parse(map['generated_at'] as String),
      isDismissed: (map['is_dismissed'] as int?) == 1,
    );
  }
}
