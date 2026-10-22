import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/habit.dart';
import '../core/app_constants.dart';
import '../viewmodels/habit_viewmodel.dart';

/// Form screen for creating new habits or modifying existing habits,
/// including category selection, custom icons, numeric targets, and habit stacking.
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
  late int _targetCount;
  late String _unit;
  String? _reminderTime;
  String? _anchorHabitId;

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
    _targetCount = h?.targetCount ?? 1;
    _unit = h?.unit ?? 'times';
    _reminderTime = h?.reminderTime;
    _anchorHabitId = h?.anchorHabitId;
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

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

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
        targetCount: _targetCount,
        unit: _unit,
        reminderTime: _reminderTime,
        anchorHabitId: _anchorHabitId,
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
        targetCount: _targetCount,
        unit: _unit,
        reminderTime: _reminderTime,
        anchorHabitId: _anchorHabitId,
        updatedAt: now,
      );
      habitVm.updateHabit(updated);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habitToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: Color(0xFF10B981),
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
            // 1. Habit Title
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: 'Habit Title *',
                hintText: 'e.g. Read 20 pages, Morning Run',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a habit title';
                }
                return null;
              },
              onSaved: (val) => _title = val!.trim(),
            ),
            const SizedBox(height: 14),

            // 2. Habit Description
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(
                labelText: 'Description / Purpose (Optional)',
                hintText: 'Why is this habit important to you?',
                prefixIcon: Icon(Icons.subject_rounded),
              ),
              onSaved: (val) => _description = val?.trim() ?? '',
            ),
            const SizedBox(height: 20),

            // 3. Category Selector
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
            const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                            ? Color(_colorValue).withValues(alpha: 0.2)
                            : (isDark ? const Color(0xFF141C2E) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? Color(_colorValue) : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(icon, color: isSelected ? Color(_colorValue) : Colors.grey),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 5. Frequency Selection
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekdays', label: Text('Mon-Fri')),
                ButtonSegment(value: 'weekends', label: Text('Sat-Sun')),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (newSet) {
                setState(() => _frequencyType = newSet.first);
              },
            ),
            const SizedBox(height: 20),

            // 6. Target Count & Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _targetCount.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Daily Target Count',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n <= 0) return 'Enter >= 1';
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
                      labelText: 'Unit (e.g. times, mins)',
                      prefixIcon: Icon(Icons.straighten_rounded),
                    ),
                    onSaved: (val) => _unit = val?.trim().isNotEmpty == true ? val!.trim() : 'times',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7. Reminder Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141C2E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text('Daily Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _reminderTime ?? 'No reminder set',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reminderTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
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

            // 8. Habit Stacking Configuration (Anchor Habit)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link_rounded, color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Text(
                        'Habit Stacking (James Clear Formula)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pair this new habit right after an already automated Anchor Habit to leverage procedural memory.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _anchorHabitId,
                    decoration: const InputDecoration(
                      labelText: 'Anchor Habit (Do this immediately after...)',
                      filled: true,
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
            const SizedBox(height: 32),

            // Save Button
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
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
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
