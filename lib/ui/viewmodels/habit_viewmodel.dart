import 'package:flutter/foundation.dart';
import '../../data/models/habit.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/datasources/sample_data_seeder.dart';

typedef DataChangeCallback = Future<void> Function();

/// ViewModel managing habit definitions, day-to-day completion states,
/// and reactive propagation to analytical and insight view models.
class HabitViewModel extends ChangeNotifier {
  final HabitRepository _repository;
  final List<DataChangeCallback> _dataChangeListeners = [];

  HabitViewModel({HabitRepository? repository})
      : _repository = repository ?? HabitRepository();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';
  List<HabitWithLog> _habitsWithLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime get selectedDate => _selectedDate;
  String get selectedCategory => _selectedCategory;
  List<HabitWithLog> get habitsWithLogs => _habitsWithLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Registers a reactive callback invoked whenever database state changes.
  void addDataChangeListener(DataChangeCallback callback) {
    if (!_dataChangeListeners.contains(callback)) {
      _dataChangeListeners.add(callback);
    }
  }

  /// Removes a previously registered reactive callback.
  void removeDataChangeListener(DataChangeCallback callback) {
    _dataChangeListeners.remove(callback);
  }

  /// Dispatches reactive updates to all registered listeners asynchronously.
  void _notifyDataChanged() {
    for (final listener in _dataChangeListeners) {
      listener().catchError((e) {
        debugPrint('Reactive update callback error: $e');
      });
    }
  }

  List<HabitWithLog> get filteredHabits {
    if (_selectedCategory == 'All') return _habitsWithLogs;
    return _habitsWithLogs.where((h) => h.habit.category == _selectedCategory).toList();
  }

  int get totalCompletedCount =>
      _habitsWithLogs.where((h) => h.isCompletedToday).length;

  int get totalScheduledCount => _habitsWithLogs.length;

  double get completionPercentage {
    if (totalScheduledCount == 0) return 0.0;
    return (totalCompletedCount / totalScheduledCount).clamp(0.0, 1.0);
  }

  Future<void> loadHabits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _habitsWithLogs = await _repository.getHabitsForDate(_selectedDate);
    } catch (e) {
      _errorMessage = 'Failed to load habits: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    await loadHabits();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(String habitId, {int? moodScore, String? notes}) async {
    try {
      await _repository.toggleHabitCompletion(habitId, _selectedDate, moodScore: moodScore, notes: notes);
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to update habit: $e';
      notifyListeners();
    }
  }

  Future<void> updateHabitProgress(String habitId, int delta) async {
    try {
      await _repository.updateHabitProgress(habitId, _selectedDate, delta);
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to update habit count: $e';
      notifyListeners();
    }
  }

  Future<void> createHabit(Habit habit) async {
    try {
      await _repository.saveHabit(habit);
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to create habit: $e';
      notifyListeners();
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _repository.updateHabit(habit);
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to save habit: $e';
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to delete habit: $e';
      notifyListeners();
    }
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.clearAllData();
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to clear data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seedDemoData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await SampleDataSeeder.seedRealisticDemoData();
      await loadHabits();
      _notifyDataChanged();
    } catch (e) {
      _errorMessage = 'Failed to seed demo data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
