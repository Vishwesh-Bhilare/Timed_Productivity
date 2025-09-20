// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/session_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _sessionController = TextEditingController();
  final TextEditingController _sessionTimeController = TextEditingController();
  final TextEditingController _breakTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _sessionTimeController.text = timerProvider.sessionTime.toString();
    _breakTimeController.text = timerProvider.breakTime.toString();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _sessionTimeController.dispose();
    _breakTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);

    // Check if timer completed and record session if needed
    if (timerProvider.remainingSeconds == 0 && !timerProvider.isRunning && timerProvider.isSession) {
      Future.delayed(Duration.zero, () {
        sessionProvider.recordSession(timerProvider.currentSession, timerProvider.sessionTime);
        timerProvider.resetTimer();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Focus Timer'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/stats');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Session selector with type-able field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sessionController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Session Name',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                    ),
                    onChanged: (value) {
                      if (sessionProvider.availableSessions.contains(value)) {
                        timerProvider.currentSession = value;
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (_sessionController.text.isNotEmpty) {
                      sessionProvider.addNewSession(_sessionController.text);
                      timerProvider.currentSession = _sessionController.text;
                      _sessionController.clear();
                    }
                  },
                ),
              ],
            ),
          ),

          // Current session display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Current: ${timerProvider.currentSession}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),

          SizedBox(height: 16),

          // Timer display
          Expanded(
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
                SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        value: timerProvider.progress,
                        strokeWidth: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          timerProvider.isSession ? Colors.white : Colors.green,
                        ),
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                    Text(
                      timerProvider.formattedTime,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: timerProvider.toggleTimer,
                      child: Icon(
                        timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: timerProvider.resetTimer,
                      child: Icon(Icons.refresh, size: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Settings
          ExpansionTile(
            title: Text('Settings', style: TextStyle(color: Colors.white)),
            children: [
              // Session time
              ListTile(
                title: Text('Session Duration (min)', style: TextStyle(color: Colors.white)),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _sessionTimeController,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null && intValue > 0) {
                        timerProvider.sessionTime = intValue;
                      }
                    },
                  ),
                ),
              ),

              // Break time
              ListTile(
                title: Text('Break Duration (min)', style: TextStyle(color: Colors.white)),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _breakTimeController,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null && intValue > 0) {
                        timerProvider.breakTime = intValue;
                      }
                    },
                  ),
                ),
              ),

              // Manage sessions
              ListTile(
                title: Text('Manage Sessions', style: TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () => _showManageSessionsDialog(context, sessionProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManageSessionsDialog(BuildContext context, SessionProvider sessionProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Manage Sessions', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessionProvider.availableSessions.length,
              itemBuilder: (context, index) {
                final session = sessionProvider.availableSessions[index];
                return ListTile(
                  title: Text(session, style: TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      sessionProvider.deleteSession(session);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}