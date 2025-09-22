// lib/screens/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/session_provider.dart';
import '../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _sessionMinController;
  late TextEditingController _sessionSecController;
  late TextEditingController _breakMinController;
  late TextEditingController _breakSecController;
  bool _hasSessionBeenRecorded = false;

  // Animation for tappable timer circle
  late AnimationController _circleController;
  late Animation<double> _circleScale;

  // FAB menus state
  bool _showSettingsMenu = false;
  bool _showCategoriesMenu = false;

  @override
  void initState() {
    super.initState();
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    _sessionMinController =
        TextEditingController(text: '${timerProvider.sessionTime ~/ 60}');
    _sessionSecController =
        TextEditingController(text: '${timerProvider.sessionTime % 60}');
    _breakMinController =
        TextEditingController(text: '${timerProvider.breakTime ~/ 60}');
    _breakSecController =
        TextEditingController(text: '${timerProvider.breakTime % 60}');

    // Animation controller for timer circle
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _circleScale =
        CurvedAnimation(parent: _circleController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _sessionMinController.dispose();
    _sessionSecController.dispose();
    _breakMinController.dispose();
    _breakSecController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  void _showSessionRecordedSnackbar(
      BuildContext context, String sessionName, int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[700],
        content: Text(
          '✅ $minutes min of "$sessionName" recorded!',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _collapseAllMenus() {
    if (_showSettingsMenu || _showCategoriesMenu) {
      setState(() {
        _showSettingsMenu = false;
        _showCategoriesMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);

    // Current category color safely
    final currentCategory = sessionProvider.categories.firstWhere(
          (cat) => cat.name == sessionProvider.currentSession,
      orElse: () => Category(
          name: sessionProvider.currentSession, color: Colors.blue.value),
    );
    final categoryColor = Color(currentCategory.color);

    // Record session on completion
    if (timerProvider.remainingSeconds == 0 &&
        timerProvider.isRunning &&
        timerProvider.isSession &&
        !_hasSessionBeenRecorded) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _hasSessionBeenRecorded = true;

        final totalSeconds = timerProvider.sessionTime * 60;
        final completedSeconds = totalSeconds - timerProvider.remainingSeconds;
        final completedMinutes = (completedSeconds / 60).ceil();

        if (completedMinutes > 0) {
          try {
            await sessionProvider.recordSession(
              sessionProvider.currentSession,
              completedMinutes,
            );
            _showSessionRecordedSnackbar(
                context, sessionProvider.currentSession, completedMinutes);
          } catch (e) {
            debugPrint('Error recording session: $e');
          }
        }

        timerProvider.pauseTimer();
        timerProvider.switchTimerMode();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _hasSessionBeenRecorded = false;
            });
          }
        });
      });
    }

    // Responsive sizing
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isSmall = screenWidth < 360;
    final circleSize = screenWidth * 0.55;

    return GestureDetector(
      onTap: _collapseAllMenus,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'FOCUS TIMER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
              onPressed: () => Navigator.pushNamed(context, '/stats'),
              tooltip: 'View Statistics',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Main content - wrapped in IgnorePointer to prevent interactions when menus are open
            IgnorePointer(
              ignoring: _showSettingsMenu || _showCategoriesMenu,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: media.size.height -
                          kToolbarHeight -
                          media.padding.top -
                          24),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Removed the dropdown menu card
                        const SizedBox(height: 18),

                        // Timer section - UPDATED FOR BETTER CENTERING
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Mode pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: timerProvider.isSession
                                        ? categoryColor.withOpacity(0.95)
                                        : Colors.green[700],
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: timerProvider.isSession
                                            ? categoryColor.withOpacity(0.28)
                                            : Colors.green.withOpacity(0.28),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    timerProvider.isSession
                                        ? 'FOCUS MODE'
                                        : 'BREAK MODE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Circular timer with animation - UPDATED LAYOUT
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: circleSize,
                                    maxHeight: circleSize,
                                  ),
                                  child: GestureDetector(
                                    onTapDown: (_) => _circleController.reverse(),
                                    onTapUp: (_) => _circleController.forward(),
                                    onTapCancel: () => _circleController.forward(),
                                    onTap: timerProvider.toggleTimer,
                                    onLongPress: () {
                                      timerProvider.resetTimer();
                                    },
                                    child: Semantics(
                                      button: true,
                                      label: 'Timer, tap to start or pause',
                                      child: ScaleTransition(
                                        scale: _circleScale,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: circleSize,
                                              height: circleSize,
                                              child: CircularProgressIndicator(
                                                value: timerProvider.progress,
                                                strokeWidth: isSmall ? 8 : 10,
                                                valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  timerProvider.isSession
                                                      ? categoryColor
                                                      : Colors.green,
                                                ),
                                                backgroundColor: Colors.grey[800]!
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  timerProvider.formattedTime,
                                                  style: TextStyle(
                                                    fontSize: isSmall ? 40 : 48,
                                                    fontWeight: FontWeight.w300,
                                                    color: Colors.white,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures()
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[850],
                                                    borderRadius:
                                                    BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        timerProvider.isRunning
                                                            ? Icons.pause_circle
                                                            : Icons.play_circle,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        sessionProvider
                                                            .currentSession,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white70,
                                                          fontWeight:
                                                          FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Control buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildControlButton(
                                      icon: timerProvider.isRunning
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      onPressed: timerProvider.toggleTimer,
                                      color: timerProvider.isRunning
                                          ? Colors.red[400]!
                                          : Colors.green[400]!,
                                      tooltip: timerProvider.isRunning
                                          ? 'Pause'
                                          : 'Start',
                                      semanticLabel: timerProvider.isRunning
                                          ? 'Pause timer'
                                          : 'Start timer',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildControlButton(
                                      icon: Icons.refresh,
                                      onPressed: timerProvider.resetTimer,
                                      color: Colors.blueGrey[600]!,
                                      tooltip: 'Reset',
                                      semanticLabel: 'Reset timer',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildControlButton(
                                      icon: Icons.skip_next,
                                      onPressed: () => _skipSession(timerProvider),
                                      color: Colors.orange[400]!,
                                      tooltip: 'Skip',
                                      semanticLabel: 'Skip session',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildControlButton(
                                      icon: Icons.add_circle_outline,
                                      onPressed: () => _showManualSessionSheet(
                                          context, sessionProvider),
                                      color: Colors.purple[400]!,
                                      tooltip: 'Manual Record',
                                      semanticLabel: 'Record manual session',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Semi-transparent overlay when menus are visible
            if (_showSettingsMenu || _showCategoriesMenu)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.01), // Almost transparent but catches taps
                  ),
                ),
              ),

            // Bottom-right FAB menus
            Positioned(
              right: 16,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings menu
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        if (_showSettingsMenu) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900]!.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildMiniFabOption(
                                  icon: Icons.access_time,
                                  label: 'Focus Time',
                                  onTap: () => _showTimeSettingsSheet(
                                      context, timerProvider, true),
                                ),
                                const SizedBox(height: 10),
                                _buildMiniFabOption(
                                  icon: Icons.free_breakfast,
                                  label: 'Break Time',
                                  onTap: () => _showTimeSettingsSheet(
                                      context, timerProvider, false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              _showSettingsMenu = !_showSettingsMenu;
                              _showCategoriesMenu = false;
                            });
                          },
                          backgroundColor: Colors.blue[700],
                          mini: true,
                          child: Icon(_showSettingsMenu ? Icons.close : Icons.settings,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Categories menu
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        if (_showCategoriesMenu) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900]!.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                ...sessionProvider.categories.take(4).map((category) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildMiniFabOption(
                                      icon: Icons.category,
                                      label: category.name,
                                      color: Color(category.color),
                                      onTap: () {
                                        sessionProvider.currentSession = category.name;
                                        timerProvider.currentSession = category.name;
                                        setState(() => _showCategoriesMenu = false);
                                      },
                                    ),
                                  );
                                }).toList(),
                                if (sessionProvider.categories.length > 4)
                                  _buildMiniFabOption(
                                    icon: Icons.more_horiz,
                                    label: 'More',
                                    onTap: () => _showCategoriesSheet(
                                        context, sessionProvider, timerProvider),
                                  ),
                                const SizedBox(height: 8),
                                _buildMiniFabOption(
                                  icon: Icons.add,
                                  label: 'Add',
                                  onTap: () => _showAddCategorySheet(
                                      context, sessionProvider, timerProvider),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              _showCategoriesMenu = !_showCategoriesMenu;
                              _showSettingsMenu = false;
                            });
                          },
                          backgroundColor: Colors.purple[700],
                          mini: true,
                          child: Icon(_showCategoriesMenu ? Icons.close : Icons.category,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    String? tooltip,
    String? semanticLabel,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        label: semanticLabel ?? tooltip ?? '',
        button: true,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.36),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  void _skipSession(TimerProvider timerProvider) {
    timerProvider.pauseTimer();
    timerProvider.resetTimer();
    timerProvider.switchTimerMode();
    _hasSessionBeenRecorded = false;
  }

  // ----------------- Bottom sheets -----------------

  void _showTimeSettingsSheet(
      BuildContext context, TimerProvider timerProvider, bool isSession) {
    final minController = TextEditingController(
        text: isSession
            ? '${timerProvider.sessionTime ~/ 60}'
            : '${timerProvider.breakTime ~/ 60}');
    final secController = TextEditingController(
        text: isSession
            ? '${timerProvider.sessionTime % 60}'
            : '${timerProvider.breakTime % 60}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Increased size to prevent keyboard blocking
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Extra padding for keyboard
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    Text(
                      isSession ? 'Focus Time Settings' : 'Break Time Settings',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: 'Minutes',
                              labelStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  BorderSide(color: Colors.grey[700]!)),
                              filled: true,
                              fillColor: Colors.grey[850],
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: secController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: 'Seconds',
                              labelStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  BorderSide(color: Colors.grey[700]!)),
                              filled: true,
                              fillColor: Colors.grey[850],
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.grey))),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final mins = int.tryParse(minController.text) ?? 0;
                            final secs = int.tryParse(secController.text) ?? 0;
                            if (isSession) {
                              timerProvider.setSessionTime(mins, secs);
                            } else {
                              timerProvider.setBreakTime(mins, secs);
                            }
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text('Save',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManualSessionSheet(
      BuildContext context, SessionProvider sessionProvider) {
    final minutesController = TextEditingController(text: '25');
    final secondsController = TextEditingController(text: '0');
    String selectedCategory = sessionProvider.currentSession;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65, // Increased size to prevent keyboard blocking
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Extra padding for keyboard
                left: 18,
                right: 18,
                top: 16,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                              width: 48,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(4))),
                        ),
                        const Text('Record Manual Session',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        const Text('Select Category:',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[700]!)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              dropdownColor: Colors.grey[850],
                              isExpanded: true,
                              items: sessionProvider.availableSessions
                                  .map((value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style:
                                      const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => selectedCategory = newValue);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Session Duration:',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minutesController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                    labelText: 'Minutes',
                                    labelStyle:
                                    const TextStyle(color: Colors.grey),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[700]!)),
                                    filled: true,
                                    fillColor: Colors.grey[850]),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: secondsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                    labelText: 'Seconds',
                                    labelStyle:
                                    const TextStyle(color: Colors.grey),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[700]!)),
                                    filled: true,
                                    fillColor: Colors.grey[850]),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.grey))),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final minutes =
                                    int.tryParse(minutesController.text) ?? 0;
                                final seconds =
                                    int.tryParse(secondsController.text) ?? 0;
                                final totalMinutes = minutes +
                                    (seconds > 0 ? 1 : 0);

                                if (totalMinutes > 0) {
                                  sessionProvider.recordSession(
                                      selectedCategory, totalMinutes);
                                  Navigator.of(context).pop();
                                  _showSessionRecordedSnackbar(context,
                                      selectedCategory, totalMinutes);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Record Session',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCategorySheet(BuildContext context,
      SessionProvider sessionProvider, TimerProvider timerProvider) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Increased size to prevent keyboard blocking
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Extra padding for keyboard
                left: 18,
                right: 18,
                top: 18,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: StatefulBuilder(builder: (context, setState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                            width: 48,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(4))),
                      ),
                      const Text('Create New Category',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              BorderSide(color: Colors.grey[700]!)),
                          filled: true,
                          fillColor: Colors.grey[850],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Select Color:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildColorOption(Colors.red, selectedColor,
                                  () => setState(() => selectedColor = Colors.red)),
                          _buildColorOption(Colors.blue, selectedColor,
                                  () => setState(() => selectedColor = Colors.blue)),
                          _buildColorOption(Colors.green, selectedColor,
                                  () => setState(() => selectedColor = Colors.green)),
                          _buildColorOption(Colors.orange, selectedColor,
                                  () => setState(() => selectedColor = Colors.orange)),
                          _buildColorOption(Colors.purple, selectedColor,
                                  () => setState(() => selectedColor = Colors.purple)),
                          _buildColorOption(Colors.teal, selectedColor,
                                  () => setState(() => selectedColor = Colors.teal)),
                          _buildColorOption(Colors.pink, selectedColor,
                                  () => setState(() => selectedColor = Colors.pink)),
                          _buildColorOption(Colors.amber, selectedColor,
                                  () => setState(() => selectedColor = Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.grey))),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                sessionProvider.addCategory(
                                    nameController.text, selectedColor.value);
                                timerProvider.currentSession =
                                    nameController.text;
                                sessionProvider.currentSession =
                                    nameController.text;
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text('Create',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )
                    ],
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoriesSheet(BuildContext context,
      SessionProvider sessionProvider, TimerProvider timerProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.34,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                children: [
                  Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4))),
                  const Text('Categories',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: sessionProvider.categories.length + 1,
                      separatorBuilder: (_, __) =>
                      const Divider(color: Colors.grey),
                      itemBuilder: (context, index) {
                        if (index == sessionProvider.categories.length) {
                          return ListTile(
                            leading:
                            const Icon(Icons.add, color: Colors.white),
                            title: const Text('Create Category',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showAddCategorySheet(
                                  context, sessionProvider, timerProvider);
                            },
                          );
                        }
                        final cat = sessionProvider.categories[index];
                        return ListTile(
                          leading: CircleAvatar(
                              backgroundColor: Color(cat.color), radius: 18),
                          title: Text(cat.name,
                              style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            sessionProvider.currentSession = cat.name;
                            timerProvider.currentSession = cat.name;
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(Color color, Color selectedColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: color == selectedColor
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.grey[600]!, width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
      ),
    );
  }
}