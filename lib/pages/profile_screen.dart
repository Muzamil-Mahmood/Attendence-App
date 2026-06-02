import 'package:attendec/pages/privacy_policy.dart';
import 'package:attendec/pages/terms&conditions.dart';
import 'package:attendec/pages/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Authentication/login.dart';

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
// PROFILE PAGE
// ─────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── Real stats from Firebase ─────────────
  int    _totalMembers  = 0;
  int    _totalPresent  = 0;
  int    _totalAbsent   = 0;
  int    _totalLeave    = 0;
  int    _workingDays   = 0;
  bool   _statsLoading  = true;
  bool   _loggingOut    = false;

  String get uid => widget.user.uid;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));

    _loadStats();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Load real stats from Firestore ───────
  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      // Total members
      final membersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('members')
          .get();

      // Attendance summary docs for this month
      final now        = DateTime.now();
      final daysInMonth =
      DateUtils.getDaysInMonth(now.year, now.month);

      int present = 0, absent = 0, leave = 0, days = 0;

      for (int d = 1; d <= daysInMonth; d++) {
        final key =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${d.toString().padLeft(2, '0')}';

        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .doc(key)
            .get();

        if (snap.exists) {
          final data = snap.data()!;
          present += (data['totalPresent'] as int? ?? 0);
          absent  += (data['totalAbsent']  as int? ?? 0);
          leave   += (data['totalLeave']   as int? ?? 0);
          days++;
        }
      }

      setState(() {
        _totalMembers = membersSnap.docs.length;
        _totalPresent = present;
        _totalAbsent  = absent;
        _totalLeave   = leave;
        _workingDays  = days;
        _statsLoading = false;
      });
    } catch (e) {
      setState(() => _statsLoading = false);
    }
  }

  // ── Logout ───────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      setState(() => _loggingOut = false);
      _showSnack('Logout failed: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
      isError ? AppColors.red : AppColors.green,
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 24, 20, 60),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ── Stats Row ──────────
                      _buildStatsRow(),
                      const SizedBox(height: 28),

                      // ── Account Info ───────
                      _buildSectionLabel(
                          'Account Information'),
                      const SizedBox(height: 14),
                      _buildInfoCard(),
                      const SizedBox(height: 28),

                      // ── Menu ───────────────
                      _buildSectionLabel('General'),
                      const SizedBox(height: 14),
                      _buildMenuGroup([
                        _MenuItem(
                          icon: Icons.security_rounded,
                          iconColor: AppColors.accent,
                          label: 'Privacy Policy',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const PrivacyPolicyPage()),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.article_outlined,
                          iconColor: AppColors.green,
                          label: 'Terms & Conditions',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const TermsConditionsPage()),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          iconColor: AppColors.amber,
                          label: 'Help & Support',
                          onTap: () =>
                              _showSupportDialog(),
                        ),

                      ]),
                      const SizedBox(height: 28),

                      // ── Logout ─────────────
                      _buildLogoutButton(),
                      const SizedBox(height: 16),

                      // ── App version ─────────
                      Center(
                        child: Text(
                          'HR Attendance v1.0.0',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted
                                  .withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver App Bar ───────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: AppColors.bg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A2A50), Color(0xFF12121F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3D7BFF),
                      Color(0xFF2DD4A0)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bg,
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: widget.user.photoURL != null
                        ? NetworkImage(widget.user.photoURL!)
                        : null,
                    backgroundColor: AppColors.card,
                    child: widget.user.photoURL == null
                        ? Text(
                      (widget.user.displayName
                          ?.isNotEmpty ==
                          true)
                          ? widget.user.displayName![0]
                          .toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent),
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.user.displayName ?? 'User',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.email ?? '',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              // Active badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.green),
                    ),
                    const SizedBox(width: 6),
                    const Text('Active',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Row (real data) ────────────────
  Widget _buildStatsRow() {
    if (_statsLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
            child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _statItem('$_totalMembers', 'Members',
              AppColors.accent),
          _statDivider(),
          _statItem('$_totalPresent', 'Present',
              AppColors.green),
          _statDivider(),
          _statItem('$_totalAbsent', 'Absent',
              AppColors.red),
          _statDivider(),
          _statItem('$_workingDays', 'Days\nRecorded',
              AppColors.amber),
        ],
      ),
    );
  }

  Widget _statItem(
      String value, String label, Color color) =>
      Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.4)),
          ],
        ),
      );

  Widget _statDivider() => Container(
      width: 1, height: 36, color: AppColors.divider);

  // ── Section Label ────────────────────────
  Widget _buildSectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8));

  // ── Info Card (from Firebase Auth) ───────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email',
              widget.user.email ?? '—', AppColors.accent),
          _divider(),
          _infoRow(
              Icons.perm_identity_rounded,
              'Name ',
              widget.user.displayName ?? '—',
              const Color(0xFFB47FFF)),
          _divider(),
          _infoRow(
              Icons.verified_rounded,
              'Account',
              widget.user.emailVerified
                  ? 'Verified ✓'
                  : 'Not Verified',
              widget.user.emailVerified
                  ? AppColors.green
                  : AppColors.red),
          _divider(),


        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value,
      Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
            
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5),
                maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.divider, height: 1);

  // ── Menu Group ───────────────────────────
  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: e.value.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: e.value.iconColor
                              .withOpacity(0.12),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Icon(e.value.icon,
                            color: e.value.iconColor,
                            size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(e.value.label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                AppColors.textPrimary)),
                      ),
                      const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: Divider(
                      color: AppColors.divider, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Support Dialog ───────────────────────
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _supportRow(Icons.email_outlined,
                'support_hrattendance@gmail.com'),
            const SizedBox(height: 10),
            _supportRow(Icons.phone_outlined,
                '+92 (302) 000-9573'),
            const SizedBox(height: 10),
            _supportRow(Icons.access_time_rounded,
                'Mon–Fri, 9:00 AM – 6:00 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
  Widget _buildThemeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFB47FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: const Color(0xFFB47FFF), size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Toggle switch
          Switch(
            value: isDark,
            onChanged: (_) => themeProvider.toggle(),
            activeColor: const Color(0xFFB47FFF),
            activeTrackColor:
            const Color(0xFFB47FFF).withOpacity(0.25),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.divider,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
  Widget _supportRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: AppColors.accent, size: 16),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13)),
      ),
    ],
  );

  // ── Logout Button ────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _loggingOut ? null : _logout,
        icon: _loggingOut
            ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: AppColors.red, strokeWidth: 2))
            : const Icon(Icons.logout_rounded,
            color: Color(0xFFFF5A5A), size: 18),
        label: Text(
          _loggingOut ? 'Logging out...' : 'Log Out',
          style: const TextStyle(
              color: Color(0xFFFF5A5A),
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
              color: Color(0xFF3A1A1A), width: 1.5),
          backgroundColor: const Color(0xFF1E1414),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// MENU ITEM MODEL
// ─────────────────────────────────────────
class _MenuItem {
  final IconData     icon;
  final Color        iconColor;
  final String       label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });
}