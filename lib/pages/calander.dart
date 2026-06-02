import 'package:flutter/material.dart';


// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class C {
  static const bg      = Color(0xFF12121F);
  static const card    = Color(0xFF1E1E30);
  static const accent  = Color(0xFF3D7BFF);
  static const green   = Color(0xFF2DD4A0);
  static const red     = Color(0xFFFF5A5A);
  static const amber   = Color(0xFFFFB347);
  static const purple  = Color(0xFFB47FFF);
  static const divider = Color(0xFF2A2A42);
  static const tp      = Color(0xFFFFFFFF);
  static const ts      = Color(0xFF9898B0);
  static const tm      = Color(0xFF5A5A7A);
}

// ─────────────────────────────────────────
// EVENT TYPE
// ─────────────────────────────────────────
enum EventType { holiday, vacation, meeting, other }

extension EventTypeExt on EventType {
  String get label {
    switch (this) {
      case EventType.holiday:  return 'Holiday';
      case EventType.vacation: return 'Vacation';
      case EventType.meeting:  return 'Meeting';
      case EventType.other:    return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case EventType.holiday:  return C.red;
      case EventType.vacation: return C.green;
      case EventType.meeting:  return C.accent;
      case EventType.other:    return C.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.holiday:  return Icons.flag_rounded;
      case EventType.vacation: return Icons.beach_access_rounded;
      case EventType.meeting:  return Icons.groups_rounded;
      case EventType.other:    return Icons.event_note_rounded;
    }
  }
}

// ─────────────────────────────────────────
// EVENT MODEL
// ─────────────────────────────────────────
class CalEvent {
  final String id;
  final String title;
  final DateTime date;
  final EventType type;
  final String? note;

  CalEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.note,
  });
}

// ─────────────────────────────────────────
// CALENDAR PAGE
// ─────────────────────────────────────────
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  late TabController _tabCtrl;

  // Pre-seeded sample events
  final Map<String, List<CalEvent>> _events = {
    _key(DateTime(DateTime.now().year, DateTime.now().month, 1)): [
      CalEvent(
          id: '1',
          title: "New Year's Day",
          date: DateTime(DateTime.now().year, DateTime.now().month, 1),
          type: EventType.holiday,
          note: 'National public holiday'),
    ],
    _key(DateTime(DateTime.now().year, DateTime.now().month, 15)): [
      CalEvent(
          id: '2',
          title: 'Team Vacation',
          date: DateTime(DateTime.now().year, DateTime.now().month, 15),
          type: EventType.vacation,
          note: 'Annual team retreat'),
    ],
  };

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<CalEvent> _eventsForDay(DateTime d) =>
      _events[_key(d)] ?? [];

  List<CalEvent> get _monthEvents {
    return _events.values
        .expand((e) => e)
        .where((e) =>
    e.date.year == _focusedMonth.year &&
        e.date.month == _focusedMonth.month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Month navigation ─────────────────────
  void _prevMonth() => setState(() =>
  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(() =>
  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  // ── Add event bottom sheet ────────────────
  void _showAddEvent(DateTime date) {
    final titleCtrl = TextEditingController();
    final noteCtrl  = TextEditingController();
    EventType selectedType = EventType.vacation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 20,
          ),
          decoration: const BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: C.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Add Event',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: C.tp)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: C.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_fmtShort(date),
                        style: const TextStyle(
                            fontSize: 12,
                            color: C.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type selector
              const Text('Type',
                  style: TextStyle(
                      fontSize: 12, color: C.ts, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: EventType.values.map((t) {
                    final sel = selectedType == t;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.color.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? t.color
                                : C.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon,
                                color: sel ? t.color : C.tm, size: 14),
                            const SizedBox(width: 6),
                            Text(t.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: sel ? t.color : C.ts,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text('Title',
                  style: TextStyle(
                      fontSize: 12, color: C.ts, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _sheetField(titleCtrl, 'e.g. Annual Leave', Icons.title_rounded),
              const SizedBox(height: 14),

              // Note
              const Text('Note (optional)',
                  style: TextStyle(
                      fontSize: 12, color: C.ts, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _sheetField(noteCtrl, 'Add a note…',
                  Icons.sticky_note_2_outlined, maxLines: 2),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final event = CalEvent(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      date: date,
                      type: selectedType,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    setState(() {
                      final k = _key(date);
                      _events[k] = [...(_events[k] ?? []), event];
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Event',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete event ─────────────────────────
  void _deleteEvent(CalEvent event) {
    setState(() {
      final k = _key(event.date);
      _events[k]?.removeWhere((e) => e.id == event.id);
      if (_events[k]?.isEmpty ?? false) _events.remove(k);
    });
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMonthHeader(),
          _buildWeekLabels(),
          _buildCalendarGrid(),
          _buildTabBar(),
          Expanded(child: _buildTabViews()),
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
        onPressed: () => _showAddEvent(_selectedDay!),
        backgroundColor: C.accent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: 26),
      )
          : null,
    );
  }

  // ── AppBar ───────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: C.bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: C.ts, size: 18),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Schedule',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: C.tp)),
    centerTitle: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.today_rounded, color: C.accent, size: 22),
        tooltip: 'Today',
        onPressed: () => setState(() {
          _focusedMonth =
              DateTime(DateTime.now().year, DateTime.now().month);
          _selectedDay = DateTime.now();
        }),
      ),
    ],
  );

  // ── Month header ─────────────────────────
  Widget _buildMonthHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left_rounded,
              color: C.ts, size: 28),
        ),
        Column(
          children: [
            Text(
              _monthName(_focusedMonth.month),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: C.tp),
            ),
            Text('${_focusedMonth.year}',
                style: const TextStyle(fontSize: 12, color: C.ts)),
          ],
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded,
              color: C.ts, size: 28),
        ),
      ],
    ),
  );

  // ── Week day labels ──────────────────────
  Widget _buildWeekLabels() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          .map((d) => SizedBox(
        width: 36,
        child: Text(d,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: (d == 'Sat' || d == 'Sun')
                    ? C.red.withOpacity(0.7)
                    : C.ts)),
      ))
          .toList(),
    ),
  );

  // ── Calendar grid ────────────────────────
  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // weekday: Mon=1 … Sun=7  → offset for Mon-start grid
    final startOffset = (firstDay.weekday - 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final dayNum = idx - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox(width: 36, height: 44);
              }
              final date = DateTime(
                  _focusedMonth.year, _focusedMonth.month, dayNum);
              return _DayCell(
                date: date,
                isToday: _isToday(date),
                isSelected: _selectedDay != null &&
                    _key(date) == _key(_selectedDay!),
                isWeekend: date.weekday >= 6,
                events: _eventsForDay(date),
                onTap: () => setState(() => _selectedDay = date),
              );
            }),
          );
        }),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────
  Widget _buildTabBar() => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    height: 42,
    decoration: BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.divider),
    ),
    child: TabBar(
      controller: _tabCtrl,
      indicator: BoxDecoration(
        color: C.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: C.ts,
      labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700),
      tabs: [
        Tab(text: 'Selected Day  (${_eventsForDay(_selectedDay ?? DateTime.now()).length})'),
        Tab(text: 'This Month  (${_monthEvents.length})'),
      ],
    ),
  );

  // ── Tab views ────────────────────────────
  Widget _buildTabViews() => TabBarView(
    controller: _tabCtrl,
    children: [
      _buildEventList(
          _eventsForDay(_selectedDay ?? DateTime.now()),
          emptyMsg: 'No events on this day.\nTap + to add one.'),
      _buildEventList(_monthEvents,
          emptyMsg: 'No events this month.\nTap + to add one.'),
    ],
  );

  Widget _buildEventList(List<CalEvent> events,
      {required String emptyMsg}) {
    if (events.isEmpty) {
      return Center(
        child: Text(emptyMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.tm, fontSize: 14, height: 1.6)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      itemCount: events.length,
      itemBuilder: (_, i) => _EventTile(
        event: events[i],
        onDelete: () => _deleteEvent(events[i]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────
  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  String _fmtShort(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _monthName(int m) {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return months[m - 1];
  }

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: C.tp, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.tm, fontSize: 13),
        prefixIcon: Icon(icon, color: C.tm, size: 18),
        filled: true,
        fillColor: C.bg,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.accent, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DAY CELL WIDGET
// ─────────────────────────────────────────
class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final List<CalEvent> events;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = isWeekend ? C.red.withOpacity(0.8) : C.tp;
    if (isSelected) textColor = Colors.white;
    if (!isSelected && isToday) textColor = C.accent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? C.accent
              : isToday
              ? C.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: C.accent.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events
                    .take(3)
                    .map((e) => Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : e.type.color,
                  ),
                ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// EVENT TILE WIDGET
// ─────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final CalEvent event;
  final VoidCallback onDelete;
  const _EventTile({required this.event, required this.onDelete});

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context) {
    final t = event.type;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Color strip
          Container(
            width: 5,
            height: 72,
            decoration: BoxDecoration(
              color: t.color,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 14),
          // Date badge
          Container(
            width: 42,
            height: 48,
            decoration: BoxDecoration(
              color: t.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${event.date.day}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.color)),
                Text(_months[event.date.month - 1],
                    style: TextStyle(
                        fontSize: 9,
                        color: t.color.withOpacity(0.8),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(t.icon, color: t.color, size: 13),
                    const SizedBox(width: 5),
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 10,
                            color: t.color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(event.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.tp)),
                if (event.note != null) ...[
                  const SizedBox(height: 2),
                  Text(event.note!,
                      style: const TextStyle(fontSize: 11, color: C.ts),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: C.tm, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}