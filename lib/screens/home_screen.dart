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
  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);

    // Check if timer completed and record session if needed
    if (timerProvider.remainingSeconds == 0 && !timerProvider.isRunning && timerProvider.isSession) {
      // Add a small delay to allow UI to update first
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
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/stats');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Session selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: timerProvider.currentSession,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  timerProvider.currentSession = newValue;
                }
              },
              items: sessionProvider.availableSessions
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Add new session button
          TextButton(
            onPressed: () {
              _showAddSessionDialog(context, sessionProvider);
            },
            child: Text('+ Add New Session Type'),
          ),

          // Timer display
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timerProvider.isSession ? 'Session' : 'Break',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: CircularProgressIndicator(
                        value: timerProvider.progress,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          timerProvider.isSession ? Colors.deepPurple : Colors.green,
                        ),
                      ),
                    ),
                    Text(
                      timerProvider.formattedTime,
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
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
                        size: 36,
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: timerProvider.resetTimer,
                      child: Icon(Icons.refresh, size: 36),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Settings
          ExpansionTile(
            title: Text('Settings'),
            children: [
              ListTile(
                title: Text('Session Duration: ${timerProvider.sessionTime} minutes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        if (timerProvider.sessionTime > 1) {
                          timerProvider.sessionTime = timerProvider.sessionTime - 1;
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        timerProvider.sessionTime = timerProvider.sessionTime + 1;
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text('Break Duration: ${timerProvider.breakTime} minutes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        if (timerProvider.breakTime > 1) {
                          timerProvider.breakTime = timerProvider.breakTime - 1;
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        timerProvider.breakTime = timerProvider.breakTime + 1;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context, SessionProvider sessionProvider) {
    String newSessionName = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Session Type'),
          content: TextField(
            onChanged: (value) {
              newSessionName = value;
            },
            decoration: InputDecoration(hintText: 'Enter session name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newSessionName.isNotEmpty) {
                  sessionProvider.addNewSession(newSessionName);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}