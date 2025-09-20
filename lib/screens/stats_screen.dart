// screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../widgets/custom_progress_indicator.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedTimeFrame = 'Total';

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final stats = _getStats(sessionProvider);
    final totalMinutes = sessionProvider.getTotalMinutes();
    final maxValue = stats.values.isNotEmpty ? stats.values.reduce((a, b) => a > b ? a : b) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedTimeFrame,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTimeFrame = newValue;
                  });
                }
              },
              items: ['Today', 'This Week', 'Total']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _buildStats(stats, totalMinutes, maxValue),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getStats(SessionProvider sessionProvider) {
    switch (_selectedTimeFrame) {
      case 'Today':
        return sessionProvider.getSessionsByDay(DateTime.now());
      case 'This Week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return sessionProvider.getSessionsByWeek(weekStart);
      case 'Total':
      default:
        return sessionProvider.getAllSessions();
    }
  }

  Widget _buildStats(Map<String, int> stats, int totalMinutes, int maxValue) {
    if (stats.isEmpty) {
      return Center(
        child: Text(
          'No data available\nComplete some sessions to see statistics',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];

    return ListView(
      children: [
        // Total time
        Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Total Focus Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '$totalMinutes minutes',
                  style: TextStyle(fontSize: 24, color: Colors.deepPurple),
                ),
                Text(
                  '${(totalMinutes / 60).toStringAsFixed(1)} hours',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // Bar chart using custom widgets
        Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Time by Session Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  height: 300,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: stats.entries.map((entry) {
                            final index = stats.keys.toList().indexOf(entry.key);
                            final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
                            final heightFactor = percentage.toDouble();

                            return Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Container(
                                        alignment: Alignment.bottomCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: heightFactor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors[index % colors.length],
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(4),
                                                topRight: Radius.circular(4),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${entry.value}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Text(
                                      _abbreviateSessionName(entry.key),
                                      style: TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Minutes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Distribution as a list
        Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Time Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Column(
                  children: stats.entries.map((entry) {
                    final index = stats.keys.toList().indexOf(entry.key);
                    final percentage = totalMinutes > 0 ? (entry.value / totalMinutes * 100) : 0.0;
                    final progressValue = (percentage / 100).toDouble();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: colors[index % colors.length],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: CustomProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey[200]!,
                              valueColor: colors[index % colors.length],
                              height: 8,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${entry.value} min\n${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Session details
        Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Session Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Column(
                  children: stats.entries.map((entry) {
                    final index = stats.keys.toList().indexOf(entry.key);
                    final percentage = totalMinutes > 0 ? (entry.value / totalMinutes * 100) : 0.0;

                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        color: colors[index % colors.length],
                      ),
                      title: Text(entry.key),
                      subtitle: Text('${percentage.toStringAsFixed(1)}% of total time'),
                      trailing: Text('${entry.value} min'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _abbreviateSessionName(String name) {
    if (name.length <= 8) return name;

    // Try to abbreviate common session types
    final abbreviations = {
      'Programming': 'Code',
      'Development': 'Dev',
      'Reading': 'Read',
      'Writing': 'Write',
      'Studying': 'Study',
      'Exercise': 'Exer',
      'Meditation': 'Med',
      'Planning': 'Plan',
    };

    return abbreviations[name] ?? name.substring(0, 7) + '..';
  }
}