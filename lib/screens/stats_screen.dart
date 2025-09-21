// lib/screens/stats_screen.dart
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
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final stats = await _getStats(sessionProvider);

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final totalMinutes = _stats.values.fold<int>(0, (sum, v) => sum + (v ?? 0));
    final maxValue = _stats.values.isNotEmpty
        ? _stats.values.reduce((a, b) => a > b ? a : b)
        : 0;

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
              dropdownColor: Colors.grey[900],
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  setState(() {
                    _selectedTimeFrame = newValue;
                    _isLoading = true;
                  });
                  await _loadStats();
                }
              },
              items: ['Today', 'This Week', 'This Month', 'Total']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildStats(_stats, totalMinutes, maxValue),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getStats(SessionProvider sessionProvider) async {
    switch (_selectedTimeFrame) {
      case 'Today':
        return await sessionProvider.getSessionsByDay(DateTime.now());
      case 'This Week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return await sessionProvider.getSessionsByWeek(weekStart);
      case 'This Month':
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        final monthSessions = sessionProvider.sessions.where((s) =>
        s.date.isAfter(monthStart) && s.date.isBefore(monthEnd)
        );

        Map<String, int> result = {};
        for (var s in monthSessions) {
          result[s.sessionName] = (result[s.sessionName] ?? 0) + s.duration;
        }
        return result;

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
          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
        ),
      );
    }

    final List<Color> colors = [
      Colors.white,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return ListView(
      children: [
        // Total time
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Total Focus Time (${_selectedTimeFrame})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  '$totalMinutes minutes',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                Text(
                  '${(totalMinutes / 60).toStringAsFixed(1)} hours',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),

        // Bar chart
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Time by Session Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
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
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${entry.value}',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _abbreviateSessionName(entry.key),
                              style: TextStyle(fontSize: 8, color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Distribution
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Time Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                Column(
                  children: stats.entries.map((entry) {
                    final index = stats.keys.toList().indexOf(entry.key);
                    final percentage = totalMinutes > 0 ? (entry.value / totalMinutes * 100) : 0.0;
                    final progressValue = (percentage / 100).toDouble();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: CustomProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey[800]!,
                              valueColor: colors[index % colors.length],
                              height: 6,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
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
      ],
    );
  }

  String _abbreviateSessionName(String name) {
    if (name.length <= 6) return name;
    return name.substring(0, 5) + '..';
  }
}