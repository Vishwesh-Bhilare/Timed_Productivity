// models/session_model.dart
import 'package:flutter/material.dart'; // Add this import

class SessionRecord {
  final int? id;
  final String sessionName;
  final int duration;
  final DateTime date;
  final int color;

  SessionRecord({
    this.id,
    required this.sessionName,
    required this.duration,
    required this.date,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sessionName': sessionName,
      'duration': duration,
      'date': date.toIso8601String(),
      'color': color,
    };
  }

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'] as int?,
      sessionName: map['sessionName'] as String,
      duration: (map['duration'] as int?) ?? 0,
      date: DateTime.parse(map['date'] as String),
      color: (map['color'] as int?) ?? Colors.blue.value,
    );
  }
}