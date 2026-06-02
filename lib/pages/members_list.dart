import 'package:attendec/assets/create_pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import './mark_attendence.dart';

// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class AppColors {
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
// MEMBERS LIST PAGE
// ─────────────────────────────────────────
class MembersListPage extends StatefulWidget {
  const MembersListPage({super.key});

  @override
  State<MembersListPage> createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  String _search = '';

  static const _avatarColors = [
    AppColors.accent, AppColors.green,
    AppColors.purple, AppColors.amber, AppColors.red,
  ];

  Color  _avatarColor(String name) =>
      _avatarColors[name.codeUnitAt(0) % _avatarColors.length];

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    final d = (ts as Timestamp).toDate();
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _membersRef => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('members');


  // ── Delete member ────────────────────────
  Future<void> _deleteMember(
      String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Member',
            style: TextStyle(
                color: AppColors.tp,
                fontWeight: FontWeight.w700)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.ts,
                fontSize: 14,
                height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: name,
                style: const TextStyle(
                    color: AppColors.tp,
                    fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                  text: ' ? You Only See the Attendance Report of the Employee. you can\'t undo this action.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.ts)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_rounded,
                color: Colors.white, size: 16),
            label: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _membersRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name deleted successfully'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Edit member bottom sheet ──────────────
  void _showEditSheet(
      String docId, Map<String, dynamic> data) {
    final nameCtrl  = TextEditingController(text: data['name']       ?? '');
    final empIdCtrl = TextEditingController(text: data['employeeId'] ?? '');
    final emailCtrl = TextEditingController(text: data['email']      ?? '');
    final phoneCtrl = TextEditingController(text: data['phone']      ?? '');
    final roleCtrl  = TextEditingController(text: data['role']       ?? '');
    final addrCtrl  = TextEditingController(text: data['address']    ?? '');
    bool saving     = false;

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
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Member',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tp)),
                ]),
                const SizedBox(height: 20),

                // Fields
                _editField(nameCtrl,  'Full Name',    Icons.person_outline_rounded,   AppColors.accent),
                const SizedBox(height: 14),
                _editField(empIdCtrl, 'Employee ID',  Icons.badge_outlined,            AppColors.amber),
                const SizedBox(height: 14),
                _editField(emailCtrl, 'Email',        Icons.email_outlined,            AppColors.green,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _editField(phoneCtrl, 'Phone',        Icons.phone_outlined,            AppColors.purple,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 14),
                _editField(roleCtrl,  'Role / Designation', Icons.work_outline_rounded, AppColors.accent),
                const SizedBox(height: 14),
                _editField(addrCtrl,  'Address',      Icons.location_on_outlined,      AppColors.red,
                    maxLines: 2),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setSheet(() => saving = true);
                      try {
                        await _membersRef.doc(docId).update({
                          'name':       nameCtrl.text.trim(),
                          'employeeId': empIdCtrl.text.trim(),
                          'email':      emailCtrl.text.trim(),
                          'phone':      phoneCtrl.text.trim(),
                          'role':       roleCtrl.text.trim(),
                          'address':    addrCtrl.text.trim(),
                          'updatedAt':  FieldValue.serverTimestamp(),
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: const Text(
                                'Member updated successfully!'),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                          ));
                        }
                      } catch (e) {
                        setSheet(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: AppColors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                          ));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5))
                        : const Text('Save Changes',
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
      ),
    );
  }

  Widget _editField(
      TextEditingController ctrl,
      String hint,
      IconData icon,
      Color iconColor, {
        TextInputType? keyboard,
        int maxLines = 1,
      }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.tp, fontSize: 14),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle:
          const TextStyle(color: AppColors.ts, fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
          ),
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.accent, width: 1.5),
          ),
        ),
      );

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopBanner(),
          _buildSearchBar(),
          Expanded(child: _buildMembersList()),
        ],
      ),

    );
  }

  // ── AppBar ───────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: AppColors.ts, size: 18),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Team Members',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.tp)),
    centerTitle: true,
  );

  // ── Top Banner ───────────────────────────
  Widget _buildTopBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: _membersRef.snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2A50), Color(0xFF1E1E30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.people_rounded,
                  color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.tp)),
                const Text('Total Employees',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.ts)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                      const AttendanceReportPage())),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3D7BFF),
                      Color(0xFF1A4FCC)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Report',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── Search Bar ───────────────────────────
  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(
            color: AppColors.tp, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, ID or role…',
          hintStyle: const TextStyle(
              color: AppColors.tm, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.tm, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.tm, size: 18),
            onPressed: () =>
                setState(() => _search = ''),
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ),
  );

  // ── Members List ─────────────────────────
  Widget _buildMembersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _membersRef
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(
                          color: AppColors.ts)),
                ]),
          );
        }
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name']       ?? '').toLowerCase();
          final id   = (data['employeeId'] ?? '').toLowerCase();
          final role = (data['role']       ?? '').toLowerCase();
          final q    = _search.toLowerCase();
          return name.contains(q) ||
              id.contains(q) ||
              role.contains(q);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text('No results for "$_search"',
                style: const TextStyle(
                    color: AppColors.ts, fontSize: 14)),
          );
        }

        return ListView.builder(
          padding:
          const EdgeInsets.fromLTRB(20, 8, 20, 120),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc  = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _MemberCard(
              index:       i,
              docId:       doc.id,           // ← Firestore doc ID
              name:        data['name']       ?? 'Unknown',
              employeeId:  data['employeeId'] ?? '—',
              role:        data['role']       ?? 'Employee',
              email:       data['email']      ?? '',
              phone:       data['phone']      ?? '',
              imageUrl:    data['imageUrl']   ?? '',
              joinDate:    _fmtDate(data['joiningDate']),
              avatarColor: _avatarColor(data['name'] ?? 'A'),
              initials:    _initials(data['name'] ?? '?'),
              onEdit:      () => _showEditSheet(doc.id, data),
              onDelete:    () => _deleteMember(
                  doc.id, data['name'] ?? 'this member'),
              onAttendanceTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const MarkAttendancePage()),
              ),
            );
          },
        );
      },
    );
  }

  // ── Empty State ──────────────────────────
  Widget _buildEmptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: AppColors.accent, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No members yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp)),
          const SizedBox(height: 6),
          const Text(
              'Tap + to add your first member',
              style:
              TextStyle(fontSize: 13, color: AppColors.ts)),
        ]),
  );


}

// ─────────────────────────────────────────
// MEMBER CARD WIDGET
// ─────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final int      index;
  final String   docId;        // ← Firestore document ID
  final String   name;
  final String   employeeId;
  final String   role;
  final String   email;
  final String   phone;
  final String   imageUrl;
  final String   joinDate;
  final Color    avatarColor;
  final String   initials;
  final VoidCallback onEdit;   // ← edit callback
  final VoidCallback onDelete; // ← delete callback
  final VoidCallback onAttendanceTap;

  const _MemberCard({
    required this.index,
    required this.docId,
    required this.name,
    required this.employeeId,
    required this.role,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.joinDate,
    required this.avatarColor,
    required this.initials,
    required this.onEdit,
    required this.onDelete,
    required this.onAttendanceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            // ── Avatar ─────────────────────
            Stack(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                avatarColor.withOpacity(0.15),
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? Text(initials,
                    style: TextStyle(
                        color: avatarColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800))
                    : null,
              ),
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.card, width: 1.5),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 14),

            // ── Info ───────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tp),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: avatarColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(employeeId,
                          style: TextStyle(
                              fontSize: 10,
                              color: avatarColor,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(role,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ts)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.email_outlined,
                        color: AppColors.tm, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(email,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.tm),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.phone_outlined,
                        color: AppColors.tm, size: 12),
                    const SizedBox(width: 4),
                    Text(phone,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.tm)),
                    const Spacer(),
                    if (joinDate.isNotEmpty)
                      Row(children: [
                        const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.tm, size: 11),
                        const SizedBox(width: 3),
                        Text(joinDate,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.tm)),
                      ]),
                  ]),
                ],
              ),
            ),
          ]),

          // ── Edit / Delete action row ──────
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          Row(children: [
            // Edit button
            Expanded(
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent
                            .withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: AppColors.accent, size: 15),
                      SizedBox(width: 6),
                      Text('Edit',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Delete button
            Expanded(
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                        AppColors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.red, size: 15),
                      SizedBox(width: 6),
                      Text('Delete',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.red,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}