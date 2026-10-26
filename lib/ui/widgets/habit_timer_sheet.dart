import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/habit.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../core/app_constants.dart';

/// Modal bottom sheet providing a dedicated focus/duration timer for any habit.
/// Users can run countdowns (Pomodoro, 15m, 25m, 45m) or custom durations,
/// and upon completion automatically log a session directly into SQLite.
class HabitTimerSheet extends StatefulWidget {
  final Habit habit;

  const HabitTimerSheet({super.key, required this.habit});

  static Future<void> show(BuildContext context, Habit habit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitTimerSheet(habit: habit),
    );
  }

  @override
  State<HabitTimerSheet> createState() => _HabitTimerSheetState();
}

class _HabitTimerSheetState extends State<HabitTimerSheet>
    with SingleTickerProviderStateMixin {
  int _selectedMinutes = 25; // Default Pomodoro
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFinished = false;
  late AnimationController _animController;

  final List<int> _presetMinutes = [5, 10, 15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isFinished = false;
    });
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _selectedMinutes * 60;
    }
    setState(() {
      _isRunning = true;
      _isFinished = false;
    });
    HapticFeedback.lightImpact();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
        });
        HapticFeedback.heavyImpact();
        _animController.forward(from: 0);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    HapticFeedback.selectionClick();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _logCompletionAndClose() async {
    final vm = context.read<HabitViewModel>();
    HapticFeedback.mediumImpact();

    if (widget.habit.isNumeric) {
      await vm.updateHabitProgress(widget.habit.id, 1);
    } else {
      await vm.toggleHabitCompletion(widget.habit.id);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            '⏱️ "${widget.habit.title}" focus session recorded!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final habitColor = Color(widget.habit.colorValue);
    final totalSecs = _selectedMinutes * 60;
    final progress = totalSecs > 0 ? (totalSecs - _remainingSeconds) / totalSecs : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Habit Title & Category
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppConstants.getIconData(widget.habit.iconName),
                  color: habitColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Focus Timer • ${widget.habit.category}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Radial Countdown Display
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: habitColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isFinished ? const Color(0xFF10B981) : habitColor,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _isFinished ? const Color(0xFF10B981) : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isFinished
                        ? '🎉 Session Finished!'
                        : _isRunning
                            ? 'Keep focusing...'
                            : 'Paused',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isFinished ? const Color(0xFF10B981) : textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Duration preset chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _presetMinutes.map((m) {
              final isSel = _selectedMinutes == m && !_isRunning;
              return ChoiceChip(
                label: Text('${m}m'),
                selected: isSel,
                onSelected: _isRunning ? null : (_) => _selectPreset(m),
                selectedColor: habitColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? habitColor : textMuted,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSel ? habitColor : Colors.grey.withValues(alpha: 0.2),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reset',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
                label: Text(
                  _isRunning ? 'Pause' : (_remainingSeconds < totalSecs ? 'Resume' : 'Start Focus'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: habitColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Complete & Log button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logCompletionAndClose,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Log Completion Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
