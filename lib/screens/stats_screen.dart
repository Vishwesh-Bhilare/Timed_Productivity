// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/session_provider.dart';
import '../models/session_model.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedTimeFrame = 'Total';
  String _selectedView = 'Overview'; // Overview, Sessions, Trends
  Map<String, int> _stats = {};
  List<SessionRecord> _filteredSessions = [];
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
    final sessions = _getFilteredSessions(sessionProvider.sessions);

    setState(() {
      _stats = stats;
      _filteredSessions = sessions;
      _isLoading = false;
    });
  }

  List<SessionRecord> _getFilteredSessions(List<SessionRecord> allSessions) {
    final now = DateTime.now();

    switch (_selectedTimeFrame) {
      case 'Today':
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(Duration(days: 1));
        return allSessions.where((s) =>
        s.date.isAfter(todayStart) && s.date.isBefore(todayEnd)
        ).toList();

      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(Duration(days: 7));
        return allSessions.where((s) =>
        s.date.isAfter(weekStart) && s.date.isBefore(weekEnd)
        ).toList();

      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return allSessions.where((s) =>
        s.date.isAfter(monthStart) && s.date.isBefore(monthEnd)
        ).toList();

      case 'Total':
      default:
        return allSessions;
    }
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
        return _aggregateSessions(monthSessions);
      case 'Total':
      default:
        return sessionProvider.getAllSessions();
    }
  }

  Map<String, int> _aggregateSessions(Iterable<SessionRecord> sessions) {
    final result = <String, int>{};
    for (var s in sessions) {
      result[s.sessionName] = (result[s.sessionName] ?? 0) + s.duration;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final totalMinutes = _stats.values.fold<int>(0, (sum, v) => sum + (v ?? 0));
    final totalHours = totalMinutes / 60;
    final maxValue = _stats.values.isNotEmpty ? _stats.values.reduce((a, b) => a > b ? a : b) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
        children: [
          // Header with filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTimeFrame,
                      dropdownColor: Colors.grey[800],
                      underline: const SizedBox(),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
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
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedView,
                    dropdownColor: Colors.grey[800],
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedView = newValue;
                        });
                      }
                    },
                    items: ['Overview', 'Sessions', 'Trends']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedView == 'Overview'
                ? _buildOverview(totalMinutes, totalHours, maxValue)
                : _selectedView == 'Sessions'
                ? _buildSessionsList()
                : _buildTrendsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(int totalMinutes, double totalHours, int maxValue) {
    if (_stats.isEmpty) {
      return _buildEmptyState();
    }

    final sortedStats = _stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Time',
                '${totalMinutes}m\n${totalHours.toStringAsFixed(1)}h',
                Icons.access_time,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sessions',
                _filteredSessions.length.toString(),
                Icons.assignment_turned_in,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Categories',
                _stats.length.toString(),
                Icons.category,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg/Session',
                '${_filteredSessions.isNotEmpty ? (totalMinutes / _filteredSessions.length).toStringAsFixed(1) : 0}m',
                Icons.av_timer,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Distribution Chart
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ...sortedStats.map((entry) {
                  final percentage = totalMinutes > 0 ? (entry.value / totalMinutes * 100) : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[700],
                            color: _getCategoryColor(entry.key),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Top Categories
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ...sortedStats.take(3).map((entry) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(entry.key),
                      child: Text(
                        entry.key[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      '${entry.value}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: LinearProgressIndicator(
                      value: entry.value / maxValue,
                      backgroundColor: Colors.grey[700],
                      color: _getCategoryColor(entry.key),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList() {
    if (_filteredSessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(session.sessionName),
              child: Text(
                session.sessionName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              session.sessionName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(session.date),
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.duration}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${(session.duration / 60).toStringAsFixed(1)}h',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendsView() {
    // Simple trends view - you can expand this with charts
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Trends Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Weekly and monthly trends coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildTrendChip('This Week', '${_getWeeklyTotal()}m'),
                _buildTrendChip('This Month', '${_getMonthlyTotal()}m'),
                _buildTrendChip('Daily Avg', '${_getDailyAverage()}m'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Data Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some sessions to see statistics',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  int _getWeeklyTotal() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekSessions = _filteredSessions.where((s) =>
    s.date.isAfter(weekStart) && s.date.isBefore(weekStart.add(Duration(days: 7)))
    );
    return weekSessions.fold(0, (sum, session) => sum + session.duration);
  }

  int _getMonthlyTotal() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final monthSessions = _filteredSessions.where((s) =>
    s.date.isAfter(monthStart) && s.date.isBefore(monthEnd)
    );
    return monthSessions.fold(0, (sum, session) => sum + session.duration);
  }

  double _getDailyAverage() {
    if (_filteredSessions.isEmpty) return 0;
    final days = _filteredSessions.map((s) => s.date.day).toSet().length;
    return days > 0 ? totalMinutes / days : 0;
  }

  int get totalMinutes => _stats.values.fold<int>(0, (sum, v) => sum + (v ?? 0));
}