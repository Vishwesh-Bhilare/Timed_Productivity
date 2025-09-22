// providers/session_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_model.dart';
import '../models/category_model.dart';

class SessionProvider with ChangeNotifier {
  List<SessionRecord> _sessions = [];
  List<Category> _categories = [];
  bool _isInitialized = false;
  String? _currentSession;

  // Hive box names
  static const String sessionBoxName = 'sessions';
  static const String categoryBoxName = 'categories';

  SessionProvider() {
    _initialize();
  }

  // ------------------ Getters ------------------
  List<SessionRecord> get sessions => _sessions;
  List<Category> get categories => _categories;
  List<String> get availableSessions => _categories.map((cat) => cat.name).toList();
  bool get isInitialized => _isInitialized;

  String get currentSession {
    return _currentSession ?? (availableSessions.isNotEmpty ? availableSessions.first : "Work");
  }

  set currentSession(String newValue) {
    _currentSession = newValue;
    notifyListeners();
  }

  // ------------------ Initialization ------------------
  Future<void> _initialize() async {
    await _loadCategories();
    await _loadSessions();

    if (_categories.isNotEmpty) {
      _currentSession ??= _categories.first.name;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSessions() async {
    try {
      final box = await Hive.openBox(sessionBoxName);
      _sessions = box.values
          .map((v) => SessionRecord.fromMap(Map<String, dynamic>.from(v)))
          .toList();
    } catch (e) {
      print('Error loading sessions: $e');
      _sessions = [];
    }
  }

  Future<void> _loadCategories() async {
    try {
      final box = await Hive.openBox(categoryBoxName);
      if (box.isEmpty) {
        // Initialize default categories if empty
        _categories = [
          Category(name: 'Work', color: Colors.blue.value),
          Category(name: 'Study', color: Colors.green.value),
          Category(name: 'Reading', color: Colors.orange.value),
          Category(name: 'Coding', color: Colors.purple.value),
        ];
        for (var cat in _categories) {
          await box.add(cat.toMap());
        }
      } else {
        _categories = box.values
            .map((v) => Category.fromMap(Map<String, dynamic>.from(v)))
            .toList();
      }
    } catch (e) {
      print('Error loading categories: $e');
      _categories = [
        Category(name: 'Work', color: Colors.blue.value),
        Category(name: 'Study', color: Colors.green.value),
        Category(name: 'Reading', color: Colors.orange.value),
        Category(name: 'Coding', color: Colors.purple.value),
      ];
    }
  }

  // ------------------ Sessions ------------------
  Future<void> recordSession(String sessionName, int duration) async {
    try {
      final category = _categories.firstWhere(
            (cat) => cat.name == sessionName,
        orElse: () => Category(name: sessionName, color: Colors.blue.value),
      );

      final record = SessionRecord(
        sessionName: sessionName,
        duration: duration,
        date: DateTime.now(),
        color: category.color,
      );

      final box = await Hive.openBox(sessionBoxName);
      await box.add(record.toMap());

      await _loadSessions();
      notifyListeners();
    } catch (e) {
      print('Error recording session: $e');
      rethrow;
    }
  }

  // ------------------ Categories ------------------
  Future<void> addCategory(String name, int colorValue) async {
    try {
      final box = await Hive.openBox(categoryBoxName);
      final newCategory = Category(name: name, color: colorValue);
      await box.add(newCategory.toMap());

      await _loadCategories();
      _currentSession ??= name;
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String oldName, String newName, int colorValue) async {
    try {
      final box = await Hive.openBox(categoryBoxName);
      final key = box.keys.firstWhere(
            (k) => (box.get(k) as Map)['name'] == oldName,
      );
      await box.put(key, Category(name: newName, color: colorValue).toMap());

      await _loadCategories();
      if (_currentSession == oldName) {
        _currentSession = newName;
      }
      notifyListeners();
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String name) async {
    try {
      final box = await Hive.openBox(categoryBoxName);
      final key = box.keys.firstWhere(
            (k) => (box.get(k) as Map)['name'] == name,
      );
      await box.delete(key);

      await _loadCategories();
      if (_currentSession == name && _categories.isNotEmpty) {
        _currentSession = _categories.first.name;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // ------------------ Statistics ------------------
  Map<String, int> getAllSessions() {
    final result = <String, int>{};
    for (var s in _sessions) {
      result[s.sessionName] = (result[s.sessionName] ?? 0) + s.duration;
    }
    return result;
  }

  int getTotalMinutes() => _sessions.fold(0, (total, s) => total + s.duration);

  Future<Map<String, int>> getSessionsByDay(DateTime day) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final filtered = _sessions.where((s) =>
    s.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
        s.date.isBefore(dayEnd));
    return _aggregateSessions(filtered);
  }

  Future<Map<String, int>> getSessionsByWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));

    final filtered = _sessions.where((s) =>
    s.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        s.date.isBefore(weekEnd));
    return _aggregateSessions(filtered);
  }

  Map<String, int> _aggregateSessions(Iterable<SessionRecord> sessions) {
    final result = <String, int>{};
    for (var s in sessions) {
      result[s.sessionName] = (result[s.sessionName] ?? 0) + s.duration;
    }
    return result;
  }
}
