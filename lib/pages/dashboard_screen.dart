import 'package:attendec/pages/add_memeber.dart';
import 'package:attendec/pages/calander.dart';
import 'package:attendec/pages/mark_attendence.dart';
import 'package:attendec/pages/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'members_list.dart';

// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class AppColors {
  static const bg            = Color(0xFF12121F);
  static const card          = Color(0xFF1E1E30);
  static const accent        = Color(0xFF3D7BFF);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9898B0);
  static const textMuted     = Color(0xFF5A5A7A);
  static const green         = Color(0xFF2DD4A0);
  static const red           = Color(0xFFFF5A5A);
  static const amber         = Color(0xFFFFB347);
  static const divider       = Color(0xFF2A2A42);
}

// ─────────────────────────────────────────
// ATTENDANCE STEP ENUM
// ─────────────────────────────────────────
enum AttStep { checkIn, breakIn, breakOut, checkOut, done }

extension AttStepExt on AttStep {
  String get label {
    switch (this) {
      case AttStep.checkIn:  return 'Swipe to Check In';
      case AttStep.breakIn:  return 'Swipe to Break In';
      case AttStep.breakOut: return 'Swipe to Break Out';
      case AttStep.checkOut: return 'Swipe to Check Out';
      case AttStep.done:     return 'Day Completed ✓';
    }
  }

  List<Color> get colors {
    switch (this) {
      case AttStep.checkIn:
        return [const Color(0xFF2B5BFF), const Color(0xFF1A3FCC)];
      case AttStep.breakIn:
        return [const Color(0xFFFFB347), const Color(0xFFE09030)];
      case AttStep.breakOut:
        return [const Color(0xFF2DD4A0), const Color(0xFF1AA880)];
      case AttStep.checkOut:
        return [const Color(0xFFFF5A5A), const Color(0xFFCC3030)];
      case AttStep.done:
        return [const Color(0xFF2DD4A0), const Color(0xFF1AA880)];
    }
  }
}

// ─────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNav    = 0;
  int _selectedDateIndex = 3;
  late List<DateTime> _weekDates;

  // ── Attendance state ─────────────────────
  AttStep   _currentStep = AttStep.checkIn;
  DateTime? _checkInTime;
  DateTime? _breakInTime;
  DateTime? _breakOutTime;
  DateTime? _checkOutTime;
  int       _breakMinutes = 0;
  bool      _loadingAtt   = false;

  // ── Swipe state ──────────────────────────
  double _dragPosition = 0.0;
  static const double _maxDrag = 240.0;

  // ── Swipe controller ─────────────────────
  late AnimationController _swipeController;
  late Animation<double>   _swipeAnim;

  String get uid => widget.user.uid;

  DateTime get _selectedDate =>
      _weekDates[_selectedDateIndex];

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year  == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day   == now.day;
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _weekDates = List.generate(
        7, (i) => today.subtract(Duration(days: 3 - i)));

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _swipeAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
          parent: _swipeController, curve: Curves.easeInOut),
    );

    _loadAttendance();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  // ── Load attendance for selected date ────
  Future<void> _loadAttendance() async {
    setState(() => _loadingAtt = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_checkouts')
          .doc(_dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        DateTime? parse(String key) {
          final ts = data[key];
          if (ts == null) return null;
          return (ts as Timestamp).toDate();
        }

        setState(() {
          _checkInTime  = parse('checkIn');
          _breakInTime  = parse('breakIn');
          _breakOutTime = parse('breakOut');
          _checkOutTime = parse('checkOut');
          _breakMinutes = data['breakMinutes'] ?? 0;

          // Determine current step
          if (_checkOutTime != null) {
            _currentStep = AttStep.done;
          } else if (_breakOutTime != null) {
            _currentStep = AttStep.checkOut;
          } else if (_breakInTime != null) {
            _currentStep = AttStep.breakOut;
          } else if (_checkInTime != null) {
            _currentStep = AttStep.breakIn;
          } else {
            _currentStep = AttStep.checkIn;
          }
        });
      } else {
        // No record for this date
        setState(() {
          _checkInTime  = null;
          _breakInTime  = null;
          _breakOutTime = null;
          _checkOutTime = null;
          _breakMinutes = 0;
          _currentStep  = AttStep.checkIn;
        });
      }
    } catch (e) {
      _showSnack('Failed to load: $e', isError: true);
    } finally {
      setState(() => _loadingAtt = false);
    }
  }

  // ── Save attendance to Firebase ──────────
  Future<void> _saveAttendance() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_checkouts')
          .doc(_dateKey)
          .set({
        'date':         _dateKey,
        'checkIn':      _checkInTime  != null ? Timestamp.fromDate(_checkInTime!)  : null,
        'breakIn':      _breakInTime  != null ? Timestamp.fromDate(_breakInTime!)  : null,
        'breakOut':     _breakOutTime != null ? Timestamp.fromDate(_breakOutTime!) : null,
        'checkOut':     _checkOutTime != null ? Timestamp.fromDate(_checkOutTime!) : null,
        'breakMinutes': _breakMinutes,
        'ownerUid':     uid,
        'updatedAt':    FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    }
  }

  // ── Handle swipe complete ─────────────────
  Future<void> _onSwipeComplete() async {
    if (!_isToday) {
      _showSnack('Cannot mark attendance for past dates!',
          isError: true);
      return;
    }
    if (_currentStep == AttStep.done) return;

    final now = DateTime.now();

    setState(() {
      switch (_currentStep) {
        case AttStep.checkIn:
          _checkInTime = now;
          _currentStep = AttStep.breakIn;
          break;
        case AttStep.breakIn:
          _breakInTime = now;
          _currentStep = AttStep.breakOut;
          break;
        case AttStep.breakOut:
          _breakOutTime = now;
          // Calculate break duration in minutes
          if (_breakInTime != null) {
            _breakMinutes = _breakOutTime!
                .difference(_breakInTime!)
                .inMinutes;
          }
          _currentStep = AttStep.checkOut;
          break;
        case AttStep.checkOut:
          _checkOutTime = now;
          _currentStep  = AttStep.done;
          break;
        case AttStep.done:
          break;
      }
    });

    await _saveAttendance();
    _showSnack(_getSuccessMessage(), isError: false);
  }

  String _getSuccessMessage() {
    switch (_currentStep) {
      case AttStep.breakIn:  return '✅ Checked In at ${_fmt(_checkInTime!)}';
      case AttStep.breakOut: return '☕ Break started at ${_fmt(_breakInTime!)}';
      case AttStep.checkOut: return '✅ Break ended — ${_breakMinutes}m break';
      case AttStep.done:     return '🏠 Checked out at ${_fmt(_checkOutTime!)}';
      default:               return 'Saved!';
    }
  }

  // ── Formatters ───────────────────────────
  String _fmt(DateTime d) {
    final h  = d.hour   % 12 == 0 ? 12 : d.hour   % 12;
    final m  = d.minute.toString().padLeft(2, '0');
    final ap = d.hour < 12 ? 'am' : 'pm';
    return '$h:$m $ap';
  }

  String _dayLabel(DateTime d) {
    const n = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return n[d.weekday - 1];
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.red : AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildDateStrip(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Today Attendance'),
                    const SizedBox(height: 14),
                    _buildAttendanceGrid(),
                    const SizedBox(height: 24),
                    _buildActivityHeader(),
                    const SizedBox(height: 14),
                    _buildActivityLog(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Swipe bar only for today
            _buildSwipeBar(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ───────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
            Border.all(color: AppColors.accent, width: 2),
            image: widget.user.photoURL != null
                ? DecorationImage(
              image: NetworkImage(widget.user.photoURL!),
              fit: BoxFit.cover,
            )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.displayName ?? 'User',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.email ?? '',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

      ],
    );
  }

  // ── Date Strip ───────────────────────────
  Widget _buildDateStrip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_weekDates.length, (i) {
        final date     = _weekDates[i];
        final selected = i == _selectedDateIndex;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDateIndex = i;
              _dragPosition      = 0;
            });
            _loadAttendance();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 64,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent
                  : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? [
                BoxShadow(
                    color: AppColors.accent
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(_dayLabel(date),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Section Title ────────────────────────
  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));

  // ── Attendance Grid ──────────────────────
  Widget _buildAttendanceGrid() {
    if (_loadingAtt) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.accent));
    }

    // Calculate total work hours
    String workHours = '—';
    if (_checkInTime != null && _checkOutTime != null) {
      final totalMins =
          _checkOutTime!.difference(_checkInTime!).inMinutes -
              _breakMinutes;
      final h = totalMins ~/ 60;
      final m = totalMins % 60;
      workHours = '${h}h ${m}m';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _attCard(
                icon: Icons.login_rounded,
                iconColor: AppColors.accent,
                label: 'Check In',
                value: _checkInTime != null
                    ? _fmt(_checkInTime!)
                    : '—',
                sub: _checkInTime != null
                    ? 'On Time'
                    : 'Not marked',
                subColor: _checkInTime != null
                    ? AppColors.green
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _attCard(
                icon: Icons.logout_rounded,
                iconColor: AppColors.red,
                label: 'Check Out',
                value: _checkOutTime != null
                    ? _fmt(_checkOutTime!)
                    : '—',
                sub: _checkOutTime != null
                    ? 'Go Home'
                    : 'Pending',
                subColor: _checkOutTime != null
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _attCard(
                icon: Icons.timer_outlined,
                iconColor: AppColors.green,
                label: 'Break Time',
                value: _breakMinutes > 0
                    ? '$_breakMinutes min'
                    : '—',
                sub: _breakMinutes > 0
                    ? 'Total Break'
                    : 'No break yet',
                subColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _attCard(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFFFFB347),
                label: 'Work Hours',
                value: workHours,
                sub: _checkOutTime != null
                    ? 'Total Today'
                    : 'In Progress',
                subColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _attCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required Color subColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border:
          Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  // ── Activity Header ──────────────────────
  Widget _buildActivityHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        _isToday
            ? 'Today\'s Activity'
            : 'Activity — ${_fmtDate(_selectedDate)}',
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
      ),
    ],
  );

  // ── Activity Log (timeline) ──────────────
  Widget _buildActivityLog() {
    final List<Map<String, dynamic>> events = [];

    if (_checkInTime != null) {
      events.add({
        'icon':  Icons.login_rounded,
        'color': AppColors.accent,
        'title': 'Check In',
        'time':  _fmt(_checkInTime!),
        'sub':   'On Time',
      });
    }
    if (_breakInTime != null) {
      events.add({
        'icon':  Icons.free_breakfast_outlined,
        'color': AppColors.amber,
        'title': 'Break In',
        'time':  _fmt(_breakInTime!),
        'sub':   'Break started',
      });
    }
    if (_breakOutTime != null) {
      events.add({
        'icon':  Icons.play_arrow_rounded,
        'color': AppColors.green,
        'title': 'Break Out',
        'time':  _fmt(_breakOutTime!),
        'sub':   '$_breakMinutes min break',
      });
    }
    if (_checkOutTime != null) {
      events.add({
        'icon':  Icons.logout_rounded,
        'color': AppColors.red,
        'title': 'Check Out',
        'time':  _fmt(_checkOutTime!),
        'sub':   'Day completed',
      });
    }

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('No activity recorded yet.',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13)),
        ),
      );
    }

    return Column(
      children: events
          .map((e) => _activityItem(
        icon: e['icon'],
        iconColor: e['color'],
        title: e['title'],
        time: e['time'],
        sub: e['sub'],
      ))
          .toList(),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String sub,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(time,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      );

  // ── Swipe Bar ────────────────────────────
  Widget _buildSwipeBar() {
    // Hide swipe bar for past dates or done state on past dates
    final bool isPast = !_isToday;
    final bool isDone = _currentStep == AttStep.done;

    // For past dates just show a read-only info bar
    if (isPast) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: Text(
            '📅 ${_fmtDate(_selectedDate)} — View Only',
            style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ),
      );
    }

    if (isDone) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2DD4A0), Color(0xFF1AA880)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Day Completed ✓',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 58,
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _currentStep.colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentStep.colors[0].withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Label text
          Opacity(
            opacity:
            1.0 - (_dragPosition / _maxDrag).clamp(0.0, 1.0),
            child: Text(
              _currentStep.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Swipe thumb
          Positioned(
            left: 6 + _dragPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition =
                      (_dragPosition + details.delta.dx)
                          .clamp(0.0, _maxDrag);
                });
              },
              onHorizontalDragEnd: (_) async {
                if (_dragPosition > _maxDrag * 0.75) {
                  await _onSwipeComplete();
                }
                setState(() => _dragPosition = 0);
              },
              child: AnimatedBuilder(
                animation: _swipeAnim,
                builder: (_, __) => Transform.translate(
                  offset: _dragPosition < 10
                      ? Offset(_swipeAnim.value, 0)
                      : Offset.zero,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _currentStep.colors[0],
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────
  Widget _buildBottomNav() {
    final icons = [
      Icons.home_outlined,
      Icons.person_add_alt_1,
      null,
      Icons.mark_chat_read_sharp,
      Icons.person_outline,
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.card,
        border:
        Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          if (icons[i] == null) {
            return InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MembersListPage())),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3D7BFF),
                      Color(0xFF1A4FCC)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                      AppColors.accent.withOpacity(0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.people_rounded,
                    color: Colors.white, size: 28),
              ),
            );
          }

          return IconButton(
            onPressed: () {
              setState(() => _selectedNav = i);
              switch (i) {
                case 0:
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DashboardScreen(
                              user: widget.user)));
                  break;
                case 1:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddMemberPage()));
                  break;
                case 3:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                           MarkAttendancePage()));
                  break;
                case 4:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProfilePage(user: widget.user)));
                  break;
              }
            },
            icon: Icon(
              icons[i],
              size: 28,
              color: _selectedNav == i
                  ? AppColors.accent
                  : AppColors.textMuted,
            ),
          );
        }),
      ),
    );
  }
}