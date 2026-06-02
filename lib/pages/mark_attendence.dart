import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const divider = Color(0xFF2A2A42);
  static const tp      = Color(0xFFFFFFFF);
  static const ts      = Color(0xFF9898B0);
  static const tm      = Color(0xFF5A5A7A);
}

// ─────────────────────────────────────────
// STATUS ENUM
// ─────────────────────────────────────────
enum AttStatus { present, absent, leave, none }

extension AttStatusExt on AttStatus {
  String get label {
    switch (this) {
      case AttStatus.present: return 'Present';
      case AttStatus.absent:  return 'Absent';
      case AttStatus.leave:   return 'Leave';
      case AttStatus.none:    return 'Mark';
    }
  }

  Color get color {
    switch (this) {
      case AttStatus.present: return C.green;
      case AttStatus.absent:  return C.red;
      case AttStatus.leave:   return C.amber;
      case AttStatus.none:    return C.tm;
    }
  }

  IconData get icon {
    switch (this) {
      case AttStatus.present: return Icons.check_circle_rounded;
      case AttStatus.absent:  return Icons.cancel_rounded;
      case AttStatus.leave:   return Icons.beach_access_rounded;
      case AttStatus.none:    return Icons.radio_button_unchecked_rounded;
    }
  }

  static AttStatus fromString(String s) {
    switch (s) {
      case 'Present': return AttStatus.present;
      case 'Absent':  return AttStatus.absent;
      case 'Leave':   return AttStatus.leave;
      default:        return AttStatus.none;
    }
  }
}

// ─────────────────────────────────────────
// EMPLOYEE MODEL
// ─────────────────────────────────────────
class Employee {
  final String id;
  final String name;
  final String role;
  final String avatar;
  final String imageUrl;
  AttStatus status;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
    this.imageUrl = '',
    this.status = AttStatus.none,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data     = doc.data() as Map<String, dynamic>;
    final name     = data['name'] ?? '';
    final parts    = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Employee(
      id:       data['employeeId'] ?? doc.id,
      name:     name,
      role:     data['role'] ?? 'Employee',
      avatar:   initials,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

// ─────────────────────────────────────────
// MARK ATTENDANCE PAGE
// ─────────────────────────────────────────
class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});
  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  // ── Selected date (user can change) ─────
  DateTime _selectedDate = DateTime.now();

  bool   _saving          = false;
  bool   _loading         = true;
  bool   _alreadySaved    = false; // true = records exist for selected date
  String _search          = '';
  List<Employee> _employees = [];

  // ── Date key e.g. "2025-04-17" ──────────
  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // ── Is selected date today? ──────────────
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year  == now.year  &&
        _selectedDate.month == now.month &&
        _selectedDate.day   == now.day;
  }

  // ── Future dates are not allowed ─────────
  bool get _isFutureDate =>
      _selectedDate.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load employees + saved attendance ────
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Fetch only this user's members
      final empSnap = await FirebaseFirestore.instance
          .collection('users')       // ← scoped to user
          .doc(uid)
          .collection('members')
          .get();

      final employees =
      empSnap.docs.map(Employee.fromFirestore).toList();

      // 2. Load this user's attendance for selected date
      final attSnap = await FirebaseFirestore.instance
          .collection('users')       // ← scoped to user
          .doc(uid)
          .collection('attendance')
          .doc(_dateKey)
          .collection('records')
          .get();

      if (attSnap.docs.isNotEmpty) {
        _alreadySaved = true;
        final saved = {
          for (var d in attSnap.docs)
            d.data()['employeeId']: d.data()
        };
        for (final emp in employees) {
          emp.status = saved.containsKey(emp.id)
              ? AttStatusExt.fromString(
              saved[emp.id]!['status'] ?? '')
              : AttStatus.none;
        }
      } else {
        _alreadySaved = false;
        for (final emp in employees) {
          emp.status = AttStatus.none;
        }
      }

      setState(() {
        _employees = employees;
        _loading   = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Failed to load: $e', isError: true);
    }
  }

  // ── Date picker ──────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // ← cannot pick future date
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: C.accent,
            surface: C.card,
            onSurface: C.tp,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _employees    = [];
      });
      await _loadData(); // reload data for new date
    }
  }

  // ── Filtered list ────────────────────────
  List<Employee> get _filtered => _employees
      .where((e) =>
  e.name.toLowerCase().contains(_search.toLowerCase()) ||
      e.id.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  // ── Stats ────────────────────────────────
  int get _present  => _employees.where((e) => e.status == AttStatus.present).length;
  int get _absent   => _employees.where((e) => e.status == AttStatus.absent).length;
  int get _leave    => _employees.where((e) => e.status == AttStatus.leave).length;
  int get _unmarked => _employees.where((e) => e.status == AttStatus.none).length;

  void _markAll(AttStatus s) =>
      setState(() { for (var e in _employees) e.status = s; });

  // ── Save / Update ─────────────────────────
  Future<void> _save() async {
    if (_isFutureDate) {
      _showSnack('Cannot mark attendance for future dates!',
          isError: true);
      return;
    }
    if (_unmarked > 0) {
      _showConfirm();
      return;
    }
    await _doSave();
  }

  void _showConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Unmarked Employees',
            style: TextStyle(
                color: C.tp, fontWeight: FontWeight.w700)),
        content: Text(
          '$_unmarked employee(s) are still unmarked. Save anyway?',
          style: const TextStyle(color: C.ts),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: C.ts)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _doSave();
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Save/Update Firestore  ──
  Future<void> _doSave() async {
    setState(() => _saving = true);
    try {
      final uid   = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < _employees.length; i++) {
        final emp = _employees[i];

        final ref = FirebaseFirestore.instance
            .collection('users')       // ← scoped to user
            .doc(uid)
            .collection('attendance')
            .doc(_dateKey)
            .collection('records')
            .doc('row_${i + 1}');

        batch.set(ref, {
          'row':        i + 1,
          'name':       emp.name,
          'employeeId': emp.id,
          'status':     emp.status.label,
          'date':       _dateKey,
          'ownerUid':   uid,
          'updatedAt':  FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Summary doc
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .doc(_dateKey),
        {
          'dateKey':        _dateKey,
          'totalPresent':   _present,
          'totalAbsent':    _absent,
          'totalLeave':     _leave,
          'totalEmployees': _employees.length,
          'ownerUid':       uid,
          'updatedAt':      FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      setState(() { _alreadySaved = true; _saving = false; });
      if (!mounted) return;
      _showSnack('Attendance saved successfully!');
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Failed to save: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? C.red : C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: C.bg,
        body: Center(
            child: CircularProgressIndicator(color: C.accent)),
      );
    }

    final list = _filtered;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDateBar(),
          if (_alreadySaved) _buildUpdateBanner(),
          _buildStatsRow(),
          _buildSearchAndQuickMark(),
          Expanded(child: _buildList(list)),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  // ── App Bar ──────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: C.bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: C.ts, size: 18),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Mark Attendance',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: C.tp)),
    centerTitle: true,

  );

  // ── Date bar (tappable) ──────────────────
  Widget _buildDateBar() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: C.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: C.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmtDate(_selectedDate),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.tp)),
              const SizedBox(height: 2),
              Text(
                _isToday ? "Today's Attendance" : 'Tap to change date',
                style: const TextStyle(
                    fontSize: 10, color: C.ts),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: C.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_calendar_rounded,
                    color: C.accent, size: 13),
                SizedBox(width: 4),
                Text('Change',
                    style: TextStyle(
                        fontSize: 11,
                        color: C.accent,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // ── Update banner (shown when editing existing) ──
  Widget _buildUpdateBanner() => Container(
    margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: C.amber.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.amber.withOpacity(0.3)),
    ),
    child: Row(
      children: const [
        Icon(Icons.edit_note_rounded,
            color: C.amber, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Attendance already saved for this date. '
                'Any changes will update the existing record.',
            style: TextStyle(
                fontSize: 12,
                color: C.amber,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  // ── Stats Row ────────────────────────────
  Widget _buildStatsRow() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(
      children: [
        _statChip('$_present', 'Present', C.green),
        const SizedBox(width: 10),
        _statChip('$_absent',  'Absent',  C.red),
        const SizedBox(width: 10),
        _statChip('$_leave',   'Leave',   C.amber),
        const SizedBox(width: 10),
        _statChip('$_unmarked', 'Pending', C.tm),
      ],
    ),
  );

  Widget _statChip(String val, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(val,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: C.ts)),
            ],
          ),
        ),
      );

  // ── Search + Quick Mark ───────────────────
  Widget _buildSearchAndQuickMark() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.divider),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: C.tp, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Search by name or ID…',
              hintStyle: TextStyle(color: C.tm, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: C.tm, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Mark All:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: C.ts)),
            const SizedBox(width: 10),
            _quickBtn('Present', C.green,
                    () => _markAll(AttStatus.present)),
            const SizedBox(width: 8),
            _quickBtn('Absent', C.red,
                    () => _markAll(AttStatus.absent)),
            const SizedBox(width: 8),
            _quickBtn('Leave', C.amber,
                    () => _markAll(AttStatus.leave)),
          ],
        ),
      ],
    ),
  );

  Widget _quickBtn(
      String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      );

  // ── Employee List ─────────────────────────
  Widget _buildList(List<Employee> list) {
    if (list.isEmpty && _search.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded,
                color: C.tm, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No employees found.\nAdd members first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: C.ts, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: C.accent.withOpacity(0.3)),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: C.accent,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      return const Center(
          child: Text('No results found',
              style: TextStyle(color: C.ts)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      itemCount: list.length,
      itemBuilder: (_, i) => _EmployeeCard(
        employee: list[i],
        onStatusChanged: (s) =>
            setState(() => list[i].status = s),
      ),
    );
  }

  // ── Save / Update Bar ─────────────────────
  Widget _buildSaveBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    decoration: BoxDecoration(
      color: C.card,
      border: Border(top: BorderSide(color: C.divider)),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: _saving ? null : _save,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D7BFF), Color(0xFF1A4FCC)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: C.accent.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _saving
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _alreadySaved
                      ? Icons.update_rounded
                      : Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _alreadySaved
                      ? 'Update Attendance  ($_present/${_employees.length})'
                      : 'Submit Attendance  ($_present/${_employees.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────
// EMPLOYEE CARD
// ─────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final ValueChanged<AttStatus> onStatusChanged;

  const _EmployeeCard({
    required this.employee,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = employee.status;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: s == AttStatus.none
              ? C.divider
              : s.color.withOpacity(0.35),
          width: s == AttStatus.none ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            _Avatar(
                initials: employee.avatar,
                imageUrl: employee.imageUrl,
                status: s),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.tp)),
                  const SizedBox(height: 3),
                  Text(employee.role,
                      style: const TextStyle(
                          fontSize: 11, color: C.ts)),
                  const SizedBox(height: 2),
                  Text(employee.id,
                      style: const TextStyle(
                          fontSize: 10,
                          color: C.tm,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            // Always editable — no lock
            _StatusButtons(
                current: s, onChanged: onStatusChanged),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// AVATAR
// ─────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final String imageUrl;
  final AttStatus status;
  const _Avatar(
      {required this.initials,
        required this.imageUrl,
        required this.status});

  static const _colors = [
    Color(0xFF3D7BFF), Color(0xFF2DD4A0), Color(0xFFB47FFF),
    Color(0xFFFFB347), Color(0xFFFF7F7F),
  ];

  @override
  Widget build(BuildContext context) {
    final color =
    _colors[initials.codeUnitAt(0) % _colors.length];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.18),
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null,
          child: imageUrl.isEmpty
              ? Text(initials,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800))
              : null,
        ),
        if (status != AttStatus.none)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.color,
                border: Border.all(color: C.card, width: 2),
              ),
              child: Icon(status.icon,
                  color: Colors.white, size: 8),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// STATUS BUTTONS
// ─────────────────────────────────────────
class _StatusButtons extends StatelessWidget {
  final AttStatus current;
  final ValueChanged<AttStatus> onChanged;
  const _StatusButtons(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Btn(
          icon: Icons.check_rounded,
          color: C.green,
          selected: current == AttStatus.present,
          onTap: () => onChanged(AttStatus.present)),
      const SizedBox(width: 6),
      _Btn(
          icon: Icons.close_rounded,
          color: C.red,
          selected: current == AttStatus.absent,
          onTap: () => onChanged(AttStatus.absent)),
      const SizedBox(width: 6),
      _Btn(
          icon: Icons.beach_access_rounded,
          color: C.amber,
          selected: current == AttStatus.leave,
          onTap: () => onChanged(AttStatus.leave)),
    ],
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Btn(
      {required this.icon,
        required this.color,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selected
            ? color
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? color
              : color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ]
            : null,
      ),
      child: Icon(icon,
          color: selected
              ? Colors.white
              : color.withOpacity(0.5),
          size: 16),
    ),
  );
}