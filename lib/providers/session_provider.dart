// providers/session_provider.dart
import 'package:flutter/material.dart';
import './database_helper.dart';
import '../models/session_model.dart';

class SessionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<SessionRecord> _sessions = [];
  List<String> _availableSessions = [];
  bool _isInitialized = false;

  SessionProvider() {
    _initialize();
  }

  List<SessionRecord> get sessions => _sessions;
  List<String> get availableSessions => _availableSessions;
  bool get isInitialized => _isInitialized;

  Future<void> _initialize() async {
    await _loadSessions();
    await _loadCategories();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSessions() async {
    try {
      final sessionsList = await _dbHelper.getSessions();
      _sessions = sessionsList.map((map) => SessionRecord.fromMap(map)).toList();
    } catch (e) {
      print('Error loading sessions: $e');
      _sessions = [];
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesList = await _dbHelper.getCategories();
      _availableSessions = categoriesList.map((map) => map['name'] as String).toList();
    } catch (e) {
      print('Error loading categories: $e');
      _availableSessions = ["Work", "Study", "Reading", "Coding"];
    }
  }

  Future<void> recordSession(String sessionName, int duration) async {
    try {
      final record = SessionRecord(
        sessionName: sessionName,
        duration: duration,
        date: DateTime.now(),
      );

      await _dbHelper.insertSession(record.toMap());
      await _loadSessions(); // Reload sessions to include the new one
      notifyListeners();
      print('Session recorded: $sessionName, $duration minutes');
    } catch (e) {
      print('Error recording session: $e');
    }
  }

  Future<void> addNewSession(String sessionName) async {
    if (!_availableSessions.contains(sessionName) && sessionName.isNotEmpty) {
      try {
        await _dbHelper.insertCategory(sessionName);
        await _loadCategories();
        notifyListeners();
        print('New session added: $sessionName');
      } catch (e) {
        print('Error adding session: $e');
      }
    }
  }

  Future<void> deleteSession(String sessionName) async {
    if (_availableSessions.contains(sessionName)) {
      try {
        await _dbHelper.deleteCategory(sessionName);
        await _loadCategories();
        notifyListeners();
        print('Session deleted: $sessionName');
      } catch (e) {
        print('Error deleting session: $e');
      }
    }
  }

  // ---------------- STATISTICS ----------------

  Future<Map<String, int>> getSessionsByDay(DateTime day) async {
    try {
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(Duration(days: 1));

      final sessions = await _dbHelper.getSessionsByDateRange(dayStart, dayEnd);
      return _aggregateSessions(sessions.map((map) => SessionRecord.fromMap(map)));
    } catch (e) {
      print('Error getting sessions by day: $e');
      return {};
    }
  }

  Future<Map<String, int>> getSessionsByWeek(DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(Duration(days: 7));
      final sessions = await _dbHelper.getSessionsByDateRange(weekStart, weekEnd);
      return _aggregateSessions(sessions.map((map) => SessionRecord.fromMap(map)));
    } catch (e) {
      print('Error getting sessions by week: $e');
      return {};
    }
  }

  Map<String, int> getAllSessions() {
    return _aggregateSessions(_sessions);
  }

  int getTotalMinutes() {
    return _sessions.fold(0, (total, s) => total + s.duration);
  }

  Map<String, int> _aggregateSessions(Iterable<SessionRecord> sessions) {
    final result = <String, int>{};
    for (var s in sessions) {
      result[s.sessionName] = (result[s.sessionName] ?? 0) + s.duration;
    }
    return result;
  }
}