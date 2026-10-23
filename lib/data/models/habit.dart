class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final int colorValue;
  final String iconName;
  final String frequencyType; // 'daily', 'weekdays', 'weekends', 'custom'
  final String customDays; // comma separated ints: "1,2,3,4,5"
  final int targetCount;
  final String unit;
  final String? reminderTime; // "08:30"
  final String? anchorHabitId; // ID of another habit to stack after
  final bool isArchived;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final double geofenceRadius; // in meters
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
    this.targetCount = 1,
    this.unit = 'times',
    this.reminderTime,
    this.anchorHabitId,
    this.isArchived = false,
    this.latitude,
    this.longitude,
    this.locationName,
    this.geofenceRadius = 150.0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isNumeric => targetCount > 1;
  bool get hasLocation => latitude != null && longitude != null;

  bool isScheduledForWeekday(int weekday) {
    // DateTime weekday: 1 = Monday, 7 = Sunday
    if (frequencyType == 'daily') return true;
    if (frequencyType == 'weekdays') return weekday >= 1 && weekday <= 5;
    if (frequencyType == 'weekends') return weekday == 6 || weekday == 7;
    if (frequencyType == 'custom') {
      final days = customDays.split(',').map((s) => int.tryParse(s.trim()) ?? 0).toList();
      return days.contains(weekday);
    }
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
    int? targetCount,
    String? unit,
    String? reminderTime,
    String? anchorHabitId,
    bool? isArchived,
    double? latitude,
    double? longitude,
    String? locationName,
    double? geofenceRadius,
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
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      reminderTime: reminderTime ?? this.reminderTime,
      anchorHabitId: anchorHabitId ?? this.anchorHabitId,
      isArchived: isArchived ?? this.isArchived,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
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
      'target_count': targetCount,
      'unit': unit,
      'reminder_time': reminderTime,
      'anchor_habit_id': anchorHabitId,
      'is_archived': isArchived ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'geofence_radius': geofenceRadius,
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
      targetCount: (map['target_count'] as int?) ?? 1,
      unit: (map['unit'] as String?) ?? 'times',
      reminderTime: map['reminder_time'] as String?,
      anchorHabitId: map['anchor_habit_id'] as String?,
      isArchived: (map['is_archived'] as int?) == 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['location_name'] as String?,
      geofenceRadius: (map['geofence_radius'] as num?)?.toDouble() ?? 150.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
