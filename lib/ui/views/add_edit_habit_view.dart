import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/habit.dart';
import '../../services/geofence_service.dart';
import '../core/app_constants.dart';
import '../viewmodels/habit_viewmodel.dart';

/// Form screen for creating new habits or modifying existing habits,
/// featuring airtight input validation, Material 3 high-contrast theme,
/// Google Maps SDK location geofencing, and James Clear habit stacking.
class AddEditHabitView extends StatefulWidget {
  final Habit? habitToEdit;

  const AddEditHabitView({super.key, this.habitToEdit});

  @override
  State<AddEditHabitView> createState() => _AddEditHabitViewState();
}

class _AddEditHabitViewState extends State<AddEditHabitView> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  late String _category;
  late int _colorValue;
  late String _iconName;
  late String _frequencyType;
  late int _frequencyTargetDays;
  late HabitType _habitType;
  late int _streakFreezesRemaining;
  late int _targetCount;
  late String _unit;
  String? _reminderTime;
  String? _anchorHabitId;

  // Google Maps SDK & Geofencing state
  bool _enableGeofence = false;
  late String _locationName;
  double? _latitude;
  double? _longitude;
  double _geofenceRadius = 150.0;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final h = widget.habitToEdit;
    _title = h?.title ?? '';
    _description = h?.description ?? '';
    _category = h?.category ?? AppConstants.categories.first.name;
    _colorValue = h?.colorValue ?? AppConstants.categories.first.color.toARGB32();
    _iconName = h?.iconName ?? 'check_circle';
    _frequencyType = h?.frequencyType ?? 'daily';
    _frequencyTargetDays = h?.frequencyTargetDays ?? 3;
    _habitType = h?.habitType ?? HabitType.positive;
    _streakFreezesRemaining = h?.streakFreezesRemaining ?? 2;
    _targetCount = h?.targetCount ?? 1;
    _unit = h?.unit ?? 'times';
    _reminderTime = h?.reminderTime;
    _anchorHabitId = h?.anchorHabitId;

    // Location state initialization
    _enableGeofence = h?.hasLocation ?? false;
    _locationName = h?.locationName ?? '';
    _latitude = h?.latitude;
    _longitude = h?.longitude;
    _geofenceRadius = h?.geofenceRadius ?? 150.0;
  }

  Future<void> _pickReminderTime() async {
    final now = TimeOfDay.now();
    TimeOfDay initial = now;
    if (_reminderTime != null) {
      final parts = _reminderTime!.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? now.hour,
          minute: int.tryParse(parts[1]) ?? now.minute,
        );
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        _reminderTime = '$h:$m';
      });
    }
  }

  /// Obtains current GPS position using Geolocator
  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await GeofenceService.instance.getCurrentPosition();
      if (!mounted) return;

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (_locationName.isEmpty) {
            _locationName = 'Current Location';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 GPS Location Captured: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not obtain GPS coordinates. Please ensure location services are enabled.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  /// Opens an interactive Google Map dialog to place a location marker pin
  Future<void> _openGoogleMapPicker() async {
    final defaultLatLng = LatLng(_latitude ?? 19.0760, _longitude ?? 72.8777);
    LatLng selectedLatLng = defaultLatLng;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Location on Map',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Tap anywhere on the map to set your reminder spot',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: defaultLatLng,
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('geofence_center'),
                              position: selectedLatLng,
                              infoWindow: InfoWindow(title: _locationName.isNotEmpty ? _locationName : 'Reminder Spot'),
                            ),
                          },
                          circles: {
                            Circle(
                              circleId: const CircleId('geofence_radius'),
                              center: selectedLatLng,
                              radius: _geofenceRadius,
                              fillColor: const Color(0xFF059669).withValues(alpha: 0.2),
                              strokeColor: const Color(0xFF059669),
                              strokeWidth: 2,
                            ),
                          },
                          onTap: (latLng) {
                            setModalState(() {
                              selectedLatLng = latLng;
                            });
                          },
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _latitude = selectedLatLng.latitude;
                                _longitude = selectedLatLng.longitude;
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Location set: ${_locationName.isNotEmpty ? _locationName : "Selected Spot"}',
                                  ),
                                  backgroundColor: const Color(0xFF059669),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('Confirm Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
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

  /// Triggers a test proximity notification
  Future<void> _simulateProximityTrigger() async {
    final tempHabit = Habit(
      id: widget.habitToEdit?.id ?? const Uuid().v4(),
      title: _title.isNotEmpty ? _title : 'Demo Habit',
      category: _category,
      colorValue: _colorValue,
      iconName: _iconName,
      locationName: _locationName.isNotEmpty ? _locationName : 'Fitness Center',
      latitude: _latitude ?? 19.0760,
      longitude: _longitude ?? 72.8777,
      geofenceRadius: _geofenceRadius,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await GeofenceService.instance.simulateArrival(habit: tempHabit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔔 Location reminder sent for "${tempHabit.locationName}"!'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors in the form.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    _formKey.currentState!.save();

    // Verify geofence requirements if toggled
    if (_enableGeofence) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select GPS coordinates or tap "Use Current GPS Location".'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
    }

    final habitVm = context.read<HabitViewModel>();
    final now = DateTime.now();

    if (widget.habitToEdit == null) {
      // Create new
      final newHabit = Habit(
        id: const Uuid().v4(),
        title: _title,
        description: _description,
        category: _category,
        colorValue: _colorValue,
        iconName: _iconName,
        frequencyType: _frequencyType,
        frequencyTargetDays: _frequencyTargetDays,
        habitType: _habitType,
        streakFreezesRemaining: _streakFreezesRemaining,
        targetCount: _targetCount,
        unit: _unit,
        reminderTime: _reminderTime,
        anchorHabitId: _anchorHabitId,
        latitude: _enableGeofence ? _latitude : null,
        longitude: _enableGeofence ? _longitude : null,
        locationName: _enableGeofence ? _locationName : null,
        geofenceRadius: _enableGeofence ? _geofenceRadius : 150.0,
        createdAt: now,
        updatedAt: now,
      );
      habitVm.createHabit(newHabit);
    } else {
      // Edit existing
      final updated = widget.habitToEdit!.copyWith(
        title: _title,
        description: _description,
        category: _category,
        colorValue: _colorValue,
        iconName: _iconName,
        frequencyType: _frequencyType,
        frequencyTargetDays: _frequencyTargetDays,
        habitType: _habitType,
        streakFreezesRemaining: _streakFreezesRemaining,
        targetCount: _targetCount,
        unit: _unit,
        reminderTime: _reminderTime,
        anchorHabitId: _anchorHabitId,
        latitude: _enableGeofence ? _latitude : null,
        longitude: _enableGeofence ? _longitude : null,
        locationName: _enableGeofence ? _locationName : null,
        geofenceRadius: _enableGeofence ? _geofenceRadius : 150.0,
        updatedAt: now,
      );
      habitVm.updateHabit(updated);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habitToEdit != null;
    final habitVm = context.watch<HabitViewModel>();

    // Other habits available for anchor habit stacking
    final availableAnchors = habitVm.habitsWithLogs
        .map((e) => e.habit)
        .where((h) => h.id != widget.habitToEdit?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          TextButton(
            onPressed: _saveHabit,
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 0. Habit Mode (Positive vs Negative / Sobriety Counter)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _habitType == HabitType.negative
                    ? const Color(0xFFF43F5E).withValues(alpha: 0.08)
                    : const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _habitType == HabitType.negative
                      ? const Color(0xFFF43F5E).withValues(alpha: 0.3)
                      : const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Habit Type *',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<HabitType>(
                    segments: const [
                      ButtonSegment(
                        value: HabitType.positive,
                        icon: Icon(Icons.add_task_rounded),
                        label: Text('Build Routine'),
                      ),
                      ButtonSegment(
                        value: HabitType.negative,
                        icon: Icon(Icons.do_not_disturb_on_rounded),
                        label: Text('Break Habit'),
                      ),
                    ],
                    selected: {_habitType},
                    onSelectionChanged: (set) {
                      setState(() => _habitType = set.first);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _habitType == HabitType.positive
                        ? 'Build a positive daily habit with streaks, timers, and frequency tracking.'
                        : 'Sobriety & Abstinence counter. Tracks consecutive clean days; logging records a lapse/reset.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _habitType == HabitType.negative
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Habit Title with Airtight Validation
            TextFormField(
              initialValue: _title,
              decoration: InputDecoration(
                labelText: 'Habit Title *',
                hintText: _habitType == HabitType.negative
                    ? 'e.g., No Cigarettes, Zero Social Media Scrolling, No Junk Food'
                    : 'e.g., Morning Meditation, HIIT Workout, Read 20 Pages',
                helperText: 'A concise, actionable name for your habit (3-60 characters)',
                prefixIcon: const Icon(Icons.edit_note_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Habit title is required and cannot be empty.';
                }
                final trimmed = val.trim();
                if (trimmed.length < 3) {
                  return 'Title must be at least 3 characters long.';
                }
                if (trimmed.length > 60) {
                  return 'Title cannot exceed 60 characters.';
                }
                return null;
              },
              onSaved: (val) => _title = val!.trim(),
            ),
            const SizedBox(height: 18),

            // 2. Habit Description / Purpose
            TextFormField(
              initialValue: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description & Motivation (Optional)',
                hintText: 'Why is this habit important? (e.g. Boost focus and physical vitality)',
                helperText: 'Implementation intention or purpose (maximum 250 characters)',
                prefixIcon: Icon(Icons.subject_rounded),
              ),
              validator: (val) {
                if (val != null && val.trim().length > 250) {
                  return 'Description cannot exceed 250 characters.';
                }
                return null;
              },
              onSaved: (val) => _description = val?.trim() ?? '',
            ),
            const SizedBox(height: 20),

            // 3. Category Selector
            const Text(
              'Habit Category *',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.categories.map((cat) {
                final isSelected = _category == cat.name;
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _category = cat.name;
                        _colorValue = cat.color.toARGB32();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Icon Selector
            const Text(
              'Choose Visual Icon *',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.habitIcons.length,
                itemBuilder: (context, index) {
                  final item = AppConstants.habitIcons[index];
                  final name = item['name'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = _iconName == name;

                  return GestureDetector(
                    onTap: () => setState(() => _iconName = name),
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_colorValue).withValues(alpha: 0.15)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? Color(_colorValue) : const Color(0xFFCBD5E1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(icon, color: isSelected ? Color(_colorValue) : const Color(0xFF64748B)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 5. Frequency Selection
            const Text(
              'Schedule & Frequency *',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekdays', label: Text('Mon-Fri')),
                ButtonSegment(value: 'weekends', label: Text('Sat-Sun')),
                ButtonSegment(value: 'x_per_week', label: Text('X / Wk')),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (newSet) {
                setState(() => _frequencyType = newSet.first);
              },
            ),
            if (_frequencyType == 'x_per_week') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Goal: $_frequencyTargetDays days/wk',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4338CA)),
                    ),
                    Expanded(
                      child: Slider(
                        value: _frequencyTargetDays.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        activeColor: const Color(0xFF6366F1),
                        label: '$_frequencyTargetDays days',
                        onChanged: (v) => setState(() => _frequencyTargetDays = v.toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 6. Target Count & Unit (for positive habits)
            if (_habitType == HabitType.positive) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _targetCount.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Target *',
                        hintText: 'e.g., 1, 8, 30',
                        helperText: 'Range: 1 - 1000',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Target required';
                        }
                        final n = int.tryParse(val.trim());
                        if (n == null) return 'Must be a number';
                        if (n < 1) return 'Min is 1';
                        if (n > 1000) return 'Max is 1,000';
                        return null;
                      },
                      onSaved: (val) => _targetCount = int.tryParse(val ?? '1') ?? 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit of Measurement *',
                        hintText: 'e.g., times, glasses, mins',
                        helperText: 'Metric label (max 20 chars)',
                        prefixIcon: Icon(Icons.straighten_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Unit required';
                        }
                        if (val.trim().length > 20) {
                          return 'Max 20 chars';
                        }
                        return null;
                      },
                      onSaved: (val) => _unit = val?.trim().isNotEmpty == true ? val!.trim() : 'times',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 7. Streak Freeze Protection Allowance
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.ac_unit_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Streak Freezes (Grace Days)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Protects your streak automatically if you miss a day.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _streakFreezesRemaining > 0
                            ? () => setState(() => _streakFreezesRemaining--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$_streakFreezesRemaining',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      IconButton(
                        onPressed: _streakFreezesRemaining < 7
                            ? () => setState(() => _streakFreezesRemaining++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. Daily Reminder Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF059669)),
              ),
              title: const Text('Daily Notification Reminder', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              subtitle: Text(
                _reminderTime != null ? 'Scheduled for $_reminderTime' : 'No reminder configured',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reminderTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20, color: Color(0xFFDC2626)),
                      onPressed: () => setState(() => _reminderTime = null),
                    ),
                  TextButton(
                    onPressed: _pickReminderTime,
                    child: Text(_reminderTime == null ? 'Set Time' : 'Change'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),

            // 8. Google Maps SDK & Geofencing Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _enableGeofence ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  width: _enableGeofence ? 1.5 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Remind Me at a Place',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _enableGeofence,
                        activeThumbColor: const Color(0xFF059669),
                        activeTrackColor: const Color(0xFFD1FAE5),
                        onChanged: (val) {
                          setState(() {
                            _enableGeofence = val;
                            if (val && _latitude == null) {
                              _latitude = 19.0760; // Default Campus / Gym coordinate
                              _longitude = 72.8777;
                              if (_locationName.isEmpty) _locationName = 'College Campus / Gym';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attach a physical location (e.g. Gym, Library, Park). You will get a friendly reminder when you arrive nearby.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),

                  if (_enableGeofence) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _locationName,
                      decoration: const InputDecoration(
                        labelText: 'Place / Venue Name *',
                        hintText: 'e.g., Fitness Center, Walking Park, Community Library',
                        helperText: 'Where should we remind you to do this habit?',
                        prefixIcon: Icon(Icons.pin_drop_rounded),
                      ),
                      validator: (val) {
                        if (!_enableGeofence) return null;
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide a place name for the reminder.';
                        }
                        if (val.trim().length < 2) return 'Min 2 characters required.';
                        if (val.trim().length > 60) return 'Max 60 characters.';
                        return null;
                      },
                      onChanged: (val) => _locationName = val.trim(),
                      onSaved: (val) => _locationName = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 14),

                    // Location coordinate buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location_rounded, size: 16),
                            label: const Text('Use Current Location'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMapPicker,
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('Pick on Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0891B2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Coordinates Display Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Coordinates', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                _latitude != null && _longitude != null
                                    ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                                    : 'No coordinates set',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Radius: ${_geofenceRadius.toInt()}m',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Geofence Radius Slider
                    Row(
                      children: [
                        const Text('Radius:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        Expanded(
                          child: Slider(
                            value: _geofenceRadius,
                            min: 50.0,
                            max: 1000.0,
                            divisions: 19,
                            activeColor: const Color(0xFF059669),
                            label: '${_geofenceRadius.toInt()} meters',
                            onChanged: (val) {
                              setState(() => _geofenceRadius = val);
                            },
                          ),
                        ),
                        Text('${_geofenceRadius.toInt()}m', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),

                    // Faculty / Testing Simulator Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _simulateProximityTrigger,
                        icon: const Icon(Icons.notifications_active_rounded, size: 16),
                        label: const Text('Test Location Reminder'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 9. Habit Stacking Configuration (Anchor Habit)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link_rounded, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Link to Another Habit (Habit Stacking)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF312E81)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Do this habit right after an established routine to build an easy, lasting chain.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _anchorHabitId,
                    decoration: const InputDecoration(
                      labelText: 'Do this habit right after...',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None (Independent Habit)'),
                      ),
                      ...availableAnchors.map((anchor) {
                        return DropdownMenuItem(
                          value: anchor.id,
                          child: Text(anchor.title),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _anchorHabitId = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveHabit,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isEditing ? 'Save Changes' : 'Create Habit',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
