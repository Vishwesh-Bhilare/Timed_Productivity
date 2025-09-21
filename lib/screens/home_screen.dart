// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/session_provider.dart';
import '../providers/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _sessionController;
  late TextEditingController _sessionMinController;
  late TextEditingController _sessionSecController;
  late TextEditingController _breakMinController;
  late TextEditingController _breakSecController;
  late TextEditingController _recordMinController;
  late TextEditingController _recordSecController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _showRecordPanel = false;

  @override
  void initState() {
    super.initState();
    _sessionController = TextEditingController();
    _sessionMinController = TextEditingController(text: '25');
    _sessionSecController = TextEditingController(text: '0');
    _breakMinController = TextEditingController(text: '5');
    _breakSecController = TextEditingController(text: '0');
    _recordMinController = TextEditingController(text: '0');
    _recordSecController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _sessionMinController.dispose();
    _sessionSecController.dispose();
    _breakMinController.dispose();
    _breakSecController.dispose();
    _recordMinController.dispose();
    _recordSecController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);

    // Check if a session timer completed and record it.
    if (timerProvider.remainingSeconds == 0 &&
        !timerProvider.isRunning &&
        timerProvider.isSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Timer completed! Recording session: ${timerProvider.currentSession}');
        sessionProvider.recordSession(
          timerProvider.currentSession,
          timerProvider.sessionTime,
        );
        timerProvider.switchTimerMode();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/stats');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Minimal header with session dropdown
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: timerProvider.currentSession,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Current Session',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                    ),
                    items: sessionProvider.availableSessions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        timerProvider.currentSession = newValue;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showAddSessionDialog(context, sessionProvider, timerProvider),
                ),
              ],
            ),
          ),

          // Timer display - Minimal
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timerProvider.isSession ? 'SESSION' : 'BREAK',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: timerProvider.progress,
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            timerProvider.isSession ? Colors.white : Colors.green,
                          ),
                          backgroundColor: Colors.grey[800],
                        ),
                      ),
                      Text(
                        timerProvider.formattedTime,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                        onPressed: timerProvider.toggleTimer,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 32),
                        onPressed: timerProvider.resetTimer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel with settings and record options
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: const Text('Options', style: TextStyle(color: Colors.white, fontSize: 14)),
              children: [
                // Timer settings
                _buildTimeSetting('Session Time', _sessionMinController, _sessionSecController, (mins, secs) {
                  timerProvider.sessionTime = mins + (secs / 60).round();
                }),
                _buildTimeSetting('Break Time', _breakMinController, _breakSecController, (mins, secs) {
                  timerProvider.breakTime = mins + (secs / 60).round();
                }),

                // Record session manually
                ListTile(
                  title: const Text('Record Session', style: TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.note_add, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showRecordPanel = !_showRecordPanel;
                      });
                    },
                  ),
                ),

                if (_showRecordPanel) ...[
                  _buildTimeSetting('Duration', _recordMinController, _recordSecController, null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        final mins = int.tryParse(_recordMinController.text) ?? 0;
                        final secs = int.tryParse(_recordSecController.text) ?? 0;
                        final totalMinutes = mins + (secs / 60).round();

                        if (totalMinutes > 0) {
                          sessionProvider.recordSession(
                            timerProvider.currentSession,
                            totalMinutes,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recorded ${totalMinutes}min session'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          setState(() {
                            _showRecordPanel = false;
                          });
                        }
                      },
                      child: const Text('Record'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSetting(String label, TextEditingController minController, TextEditingController secController, Function(int, int)? onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: SizedBox(
        width: 120,
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: TextField(
                controller: minController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'min',
                  labelStyle: TextStyle(fontSize: 10),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),
                onChanged: (value) {
                  if (onChanged != null) {
                    final mins = int.tryParse(minController.text) ?? 0;
                    final secs = int.tryParse(secController.text) ?? 0;
                    onChanged(mins, secs);
                  }
                },
              ),
            ),
            const Text(':', style: TextStyle(color: Colors.white)),
            SizedBox(
              width: 50,
              child: TextField(
                controller: secController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'sec',
                  labelStyle: TextStyle(fontSize: 10),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),
                onChanged: (value) {
                  if (onChanged != null) {
                    final mins = int.tryParse(minController.text) ?? 0;
                    final secs = int.tryParse(secController.text) ?? 0;
                    onChanged(mins, secs);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context, SessionProvider sessionProvider, TimerProvider timerProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New Session',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sessionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Session Name',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_sessionController.text.isNotEmpty) {
                          sessionProvider.addNewSession(_sessionController.text);
                          timerProvider.currentSession = _sessionController.text;
                          _sessionController.clear();
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _debugDatabase() async {
    print('=== DEBUG DATABASE ===');
    await _dbHelper.debugPrintAllData();
  }
}