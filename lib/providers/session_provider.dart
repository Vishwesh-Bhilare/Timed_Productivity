// providers/session_provider.dart
import 'package:flutter/material.dart';

class SessionRecord {
  final String sessionName;
  final int duration; // in minutes
  final DateTime date;

  SessionRecord({
    required this.sessionName,
    required this.duration,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionName': sessionName,
      'duration': duration,
      'date': date.millisecondsSinceEpoch,
    };
  }

  static SessionRecord fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      sessionName: map['sessionName'],
      duration: map['duration'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}

class SessionProvider with ChangeNotifier {
  List<SessionRecord> _sessions = [];
  List<String> _availableSessions = ["Work", "Study", "Reading", "Coding"];

  List<SessionRecord> get sessions => _sessions;
  List<String> get availableSessions => _availableSessions;

  void recordSession(String sessionName, int duration) {
    _sessions.add(SessionRecord(
      sessionName: sessionName,
      duration: duration,
      date: DateTime.now(),
    ));
    notifyListeners();
  }

  void addNewSession(String sessionName) {
    if (!_availableSessions.contains(sessionName)) {
      _availableSessions.add(sessionName);
      notifyListeners();
    }
  }

  // Statistics methods
  Map<String, int> getSessionsByDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(Duration(days: 1));

    final daySessions = _sessions.where((session) =>
    session.date.isAfter(dayStart) && session.date.isBefore(dayEnd)
    ).toList();

    Map<String, int> result = {};
    for (var session in daySessions) {
      result[session.sessionName] = (result[session.sessionName] ?? 0) + session.duration;
    }

    return result;
  }

  Map<String, int> getSessionsByWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(Duration(days: 7));

    final weekSessions = _sessions.where((session) =>
    session.date.isAfter(weekStart) && session.date.isBefore(weekEnd)
    ).toList();

    Map<String, int> result = {};
    for (var session in weekSessions) {
      result[session.sessionName] = (result[session.sessionName] ?? 0) + session.duration;
    }

    return result;
  }

  Map<String, int> getAllSessions() {
    Map<String, int> result = {};
    for (var session in _sessions) {
      result[session.sessionName] = (result[session.sessionName] ?? 0) + session.duration;
    }
    return result;
  }

  int getTotalMinutes() {
    return _sessions.fold(0, (total, session) => total + session.duration);
  }
}