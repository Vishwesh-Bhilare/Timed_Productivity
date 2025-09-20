// providers/timer_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';

class TimerProvider with ChangeNotifier {
  int _sessionTime = 25; // minutes
  int _breakTime = 5; // minutes
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isSession = true;
  String _currentSession = "Work";
  Timer? _timer;

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

  void startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    } else if (_remainingSeconds == 0) {
      // Timer completed
      pauseTimer();
      _isSession = !_isSession;
      _remainingSeconds = _isSession ? _sessionTime * 60 : _breakTime * 60;

      // We'll handle session recording in the UI where we have access to both providers
      notifyListeners();
    }
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress {
    final totalSeconds = _isSession ? _sessionTime * 60 : _breakTime * 60;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}