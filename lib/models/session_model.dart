// models/session_model.dart
class SessionRecord {
  final int? id;
  final String sessionName;
  final int duration;
  final DateTime date;

  SessionRecord({
    this.id,
    required this.sessionName,
    required this.duration,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionName': sessionName,
      'duration': duration,
      'date': date.toIso8601String(),
    };
  }

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'],
      sessionName: map['sessionName'],
      duration: map['duration'],
      date: DateTime.parse(map['date']),
    );
  }
}