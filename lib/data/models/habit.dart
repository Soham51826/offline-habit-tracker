/// Habit type: 'positive' = build a habit, 'negative' = break a habit (sobriety counter).
enum HabitType {
  positive,
  negative;

  String get dbValue => name;
  static HabitType fromDb(String? v) =>
      v == 'negative' ? HabitType.negative : HabitType.positive;
}

class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final int colorValue;
  final String iconName;
  final String frequencyType; // 'daily', 'weekdays', 'weekends', 'custom', 'x_per_week'
  final String customDays; // comma separated ints: "1,2,3,4,5"
  final int frequencyTargetDays; // For 'x_per_week': how many days per week (1-7)
  final int targetCount;
  final String unit;
  final String? reminderTime; // "08:30"
  final String? anchorHabitId; // ID of another habit to stack after
  final bool isArchived;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final double geofenceRadius; // in meters
  final HabitType habitType; // positive = build, negative = break
  final int sortOrder; // for drag-and-drop reordering
  final int streakFreezesRemaining; // Streak freeze/grace days
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.colorValue,
    required this.iconName,
    this.frequencyType = 'daily',
    this.customDays = '1,2,3,4,5,6,7',
    this.frequencyTargetDays = 3,
    this.targetCount = 1,
    this.unit = 'times',
    this.reminderTime,
    this.anchorHabitId,
    this.isArchived = false,
    this.latitude,
    this.longitude,
    this.locationName,
    this.geofenceRadius = 150.0,
    this.habitType = HabitType.positive,
    this.sortOrder = 0,
    this.streakFreezesRemaining = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isNumeric => targetCount > 1;
  bool get hasLocation => latitude != null && longitude != null;
  bool get isNegative => habitType == HabitType.negative;
  bool get isXPerWeek => frequencyType == 'x_per_week';

  bool isScheduledForWeekday(int weekday) {
    // DateTime weekday: 1 = Monday, 7 = Sunday
    if (frequencyType == 'daily') return true;
    if (frequencyType == 'weekdays') return weekday >= 1 && weekday <= 5;
    if (frequencyType == 'weekends') return weekday == 6 || weekday == 7;
    if (frequencyType == 'custom') {
      final days = customDays.split(',').map((s) => int.tryParse(s.trim()) ?? 0).toList();
      return days.contains(weekday);
    }
    // 'x_per_week': any day is eligible — tracking happens at the weekly window level
    if (frequencyType == 'x_per_week') return true;
    return true;
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? colorValue,
    String? iconName,
    String? frequencyType,
    String? customDays,
    int? frequencyTargetDays,
    int? targetCount,
    String? unit,
    String? reminderTime,
    String? anchorHabitId,
    bool? isArchived,
    double? latitude,
    double? longitude,
    String? locationName,
    double? geofenceRadius,
    HabitType? habitType,
    int? sortOrder,
    int? streakFreezesRemaining,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      frequencyType: frequencyType ?? this.frequencyType,
      customDays: customDays ?? this.customDays,
      frequencyTargetDays: frequencyTargetDays ?? this.frequencyTargetDays,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      reminderTime: reminderTime ?? this.reminderTime,
      anchorHabitId: anchorHabitId ?? this.anchorHabitId,
      isArchived: isArchived ?? this.isArchived,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      habitType: habitType ?? this.habitType,
      sortOrder: sortOrder ?? this.sortOrder,
      streakFreezesRemaining: streakFreezesRemaining ?? this.streakFreezesRemaining,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'color_value': colorValue,
      'icon_name': iconName,
      'frequency_type': frequencyType,
      'custom_days': customDays,
      'frequency_target_days': frequencyTargetDays,
      'target_count': targetCount,
      'unit': unit,
      'reminder_time': reminderTime,
      'anchor_habit_id': anchorHabitId,
      'is_archived': isArchived ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'geofence_radius': geofenceRadius,
      'habit_type': habitType.dbValue,
      'sort_order': sortOrder,
      'streak_freezes_remaining': streakFreezesRemaining,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Health',
      colorValue: map['color_value'] as int,
      iconName: (map['icon_name'] as String?) ?? 'check_circle',
      frequencyType: (map['frequency_type'] as String?) ?? 'daily',
      customDays: (map['custom_days'] as String?) ?? '1,2,3,4,5,6,7',
      frequencyTargetDays: (map['frequency_target_days'] as int?) ?? 3,
      targetCount: (map['target_count'] as int?) ?? 1,
      unit: (map['unit'] as String?) ?? 'times',
      reminderTime: map['reminder_time'] as String?,
      anchorHabitId: map['anchor_habit_id'] as String?,
      isArchived: (map['is_archived'] as int?) == 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['location_name'] as String?,
      geofenceRadius: (map['geofence_radius'] as num?)?.toDouble() ?? 150.0,
      habitType: HabitType.fromDb(map['habit_type'] as String?),
      sortOrder: (map['sort_order'] as int?) ?? 0,
      streakFreezesRemaining: (map['streak_freezes_remaining'] as int?) ?? 2,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Converts to JSON-compatible map for backup export.
  Map<String, dynamic> toJson() => toMap();

  factory Habit.fromJson(Map<String, dynamic> json) => Habit.fromMap(json);
}
