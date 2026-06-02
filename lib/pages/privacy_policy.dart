import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class _C {
  static const bg      = Color(0xFF12121F);
  static const card    = Color(0xFF1E1E30);
  static const accent  = Color(0xFF3D7BFF);
  static const green   = Color(0xFF2DD4A0);
  static const amber   = Color(0xFFFFB347);
  static const purple  = Color(0xFFB47FFF);
  static const divider = Color(0xFF2A2A42);
  static const tp      = Color(0xFFFFFFFF);
  static const ts      = Color(0xFF9898B0);
  static const tm      = Color(0xFF5A5A7A);
}

// ─────────────────────────────────────────
// PRIVACY POLICY PAGE
// ─────────────────────────────────────────
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});
  @override
  State<PrivacyPolicyPage> createState() =>
      _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState
    extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;
  final Set<int> _expanded = {};

  static const _sections = [
    _Section(
      icon: Icons.info_outline_rounded,
      color: Color(0xFF3D7BFF),
      title: '1. Information Collection and Use',
      body:
      'The Application collects information when you download and use it. '
          'This may include:\n\n'
          '• Your device IP address\n'
          '• Pages visited, time and date\n'
          '• Time spent on the app\n'
          '• Mobile device operating system\n\n'
          'The Application does NOT collect precise location data.\n\n'
          'Personal information may be requested when necessary and will be '
          'retained and used as described in this policy.',
    ),

    _Section(
      icon: Icons.smart_toy_outlined,
      color: Color(0xFF2DD4A0),
      title: '2. Use of Data & AI',
      body:
      'The Application does NOT use Artificial Intelligence (AI) '
          'technologies to process your data or provide features.\n\n'
          'Collected information may be used to:\n'
          '• Improve app performance\n'
          '• Provide important updates\n'
          '• Send notifications or promotions',
    ),

    _Section(
      icon: Icons.share_outlined,
      color: Color(0xFFFFB347),
      title: '3. Third-Party Services',
      body:
      'Only anonymized and aggregated data may be shared with external '
          'services to improve the Application.\n\n'
          'The app uses third-party services:\n'
          '• Google Analytics for Firebase\n'
          '• Firebase Crashlytics\n\n'
          'These services have their own privacy policies.',
    ),

    _Section(
      icon: Icons.gavel_rounded,
      color: Color(0xFFB47FFF),
      title: '4. Information Disclosure',
      body:
      'Information may be disclosed:\n\n'
          '• As required by law or legal process\n'
          '• To protect rights and user safety\n'
          '• To investigate fraud\n'
          '• To trusted service providers who follow this policy',
    ),

    _Section(
      icon: Icons.block_rounded,
      color: Color(0xFF3D7BFF),
      title: '5. Opt-Out Rights',
      body:
      'You can stop all data collection by uninstalling the Application.\n\n'
          'Use your device or app store uninstall process to opt out completely.',
    ),

    _Section(
      icon: Icons.storage_outlined,
      color: Color(0xFF2DD4A0),
      title: '6. Data Retention',
      body:
      'User data is retained for as long as you use the Application and for '
          'a reasonable time afterward.\n\n'
          'To request deletion of your data, contact:\n'
          'malikmuzamilmahmood47@gmail.com',
    ),

    _Section(
      icon: Icons.child_care_outlined,
      color: Color(0xFFFFB347),
      title: '7. Children’s Privacy',
      body:
      'The Application does NOT target children under 13 years of age.\n\n'
          'No personal data is knowingly collected from children. If such data '
          'is discovered, it will be deleted immediately.\n\n'
          'Parents can contact support for necessary action.',
    ),

    _Section(
      icon: Icons.lock_outline_rounded,
      color: Color(0xFFB47FFF),
      title: '8. Security',
      body:
      'The Service Provider implements safeguards to protect your data:\n\n'
          '• Physical security measures\n'
          '• Electronic protections\n'
          '• Secure data handling procedures\n\n'
          'However, no system is 100% secure.',
    ),

    _Section(
      icon: Icons.update_rounded,
      color: Color(0xFF3D7BFF),
      title: '9. Changes to This Policy',
      body:
      'This Privacy Policy may be updated at any time.\n\n'
          'Changes will be posted within the Application.\n'
          'Continued use means acceptance of updates.\n\n'
          'Effective Date: March 25, 2026',
    ),

    _Section(
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF2DD4A0),
      title: '10. Your Consent',
      body:
      'By using the Application, you agree to the collection and use of '
          'information as described in this Privacy Policy.',
    ),

    _Section(
      icon: Icons.mail_outline_rounded,
      color: Color(0xFFFFB347),
      title: '11. Contact Us',
      body:
      'If you have any questions regarding privacy, contact:\n\n'
          '📧 malikmuzamilmahmood47@gmail.com',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600))
      ..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.ts, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy Policy',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _C.tp)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              const Text('Policy Details',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.ts,
                      letterSpacing: 0.8)),
              const SizedBox(height: 12),
              ..._sections.asMap().entries
                  .map((e) => _buildSection(e.key, e.value)),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        _C.accent.withOpacity(0.15),
        _C.purple.withOpacity(0.08)
      ]),
      borderRadius: BorderRadius.circular(20),
      border:
      Border.all(color: _C.accent.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.privacy_tip_rounded,
                color: _C.accent, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Policy',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.tp)),
                Text('HR Attendance System',
                    style:
                    TextStyle(fontSize: 11, color: _C.ts)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(color: _C.divider, height: 1),
        const SizedBox(height: 12),
        const Text(
          'Your privacy is important to us. This policy explains how '
              'we collect, use, and protect your personal information.',
          style: TextStyle(
              fontSize: 13, color: _C.ts, height: 1.6),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _badge(Icons.calendar_today_rounded,
              'Updated', 'Mar 25, 2026'),
          const SizedBox(width: 10),
          _badge(
              Icons.language_rounded, 'Version', '2.0'),
        ]),
      ],
    ),
  );

  Widget _badge(IconData icon, String label, String val) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.divider),
          ),
          child: Row(children: [
            Icon(icon, color: _C.accent, size: 13),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9, color: _C.tm)),
                  Text(val,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _C.tp,
                          fontWeight: FontWeight.w600)),
                ]),
          ]),
        ),
      );



  Widget _commitTile(
      IconData icon, Color color, String t, String s) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(t,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(s,
                    style: const TextStyle(
                        fontSize: 9, color: _C.ts),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );

  Widget _buildSection(int i, _Section s) {
    final open = _expanded.contains(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: open ? s.color.withOpacity(0.35) : _C.divider,
          width: open ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          InkWell(
            onTap: () => setState(() =>
            open ? _expanded.remove(i) : _expanded.add(i)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                  Icon(s.icon, color: s.color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                          open ? s.color : _C.tp)),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration:
                  const Duration(milliseconds: 200),
                  child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: open ? s.color : _C.tm,
                      size: 22),
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: open
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Divider(
                        color: s.color.withOpacity(0.2),
                        height: 1),
                    const SizedBox(height: 12),
                    Text(s.body,
                        style: const TextStyle(
                            fontSize: 13,
                            color: _C.ts,
                            height: 1.7)),
                  ]),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.divider),
    ),
    child: Column(children: [
      const Icon(Icons.handshake_outlined,
          color: _C.accent, size: 30),
      const SizedBox(height: 10),
      const Text('Your Agreement',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.tp)),
      const SizedBox(height: 8),
      const Text(
        'By using the HR Attendance app, you agree to the collection '
            'and use of information in accordance with this Privacy Policy.',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 12, color: _C.ts, height: 1.6),
      ),
    ]),
  );
}

class _Section {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   body;
  const _Section(
      {required this.icon,
        required this.color,
        required this.title,
        required this.body});
}