// lib/providers/timer_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';

class TimerProvider with ChangeNotifier {
  int _sessionTime = 25; // in minutes
  int _breakTime = 5;    // in minutes
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isSession = true;
  String _currentSession = "Work";
  Timer? _timer;

  TimerProvider();

  int get sessionTime => _sessionTime;
  int get breakTime => _breakTime;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isSession => _isSession;
  String get currentSession => _currentSession;

  set sessionTime(int value) {
    _sessionTime = value;
    if (_isSession) {
      _remainingSeconds = value * 60;
    }
    notifyListeners();
  }

  set breakTime(int value) {
    _breakTime = value;
    if (!_isSession) {
      _remainingSeconds = value * 60;
    }
    notifyListeners();
  }

  set currentSession(String value) {
    _currentSession = value;
    notifyListeners();
  }

  // New method to set time with minutes and seconds
  void setSessionTime(int minutes, int seconds) {
    _sessionTime = minutes + (seconds / 60).round();
    if (_isSession) {
      _remainingSeconds = minutes * 60 + seconds;
    }
    notifyListeners();
  }

  void setBreakTime(int minutes, int seconds) {
    _breakTime = minutes + (seconds / 60).round();
    if (!_isSession) {
      _remainingSeconds = minutes * 60 + seconds;
    }
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      decrementSecond();
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    _remainingSeconds = _isSession ? _sessionTime * 60 : _breakTime * 60;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void decrementSecond() {
    if (_isRunning && _remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else if (_remainingSeconds <= 0) {
      pauseTimer();
    }
  }

  void switchTimerMode() {
    _isSession = !_isSession;
    _remainingSeconds = _isSession ? _sessionTime * 60 : _breakTime * 60;
    notifyListeners();
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress {
    if (_remainingSeconds == 0) return 1.0;
    final totalSeconds = _isSession ? _sessionTime * 60 : _breakTime * 60;
    if (totalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}