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
  static const red     = Color(0xFFFF5A5A);
  static const divider = Color(0xFF2A2A42);
  static const tp      = Color(0xFFFFFFFF);
  static const ts      = Color(0xFF9898B0);
  static const tm      = Color(0xFF5A5A7A);
}

// ─────────────────────────────────────────
// TERMS & CONDITIONS PAGE
// ─────────────────────────────────────────
class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});
  @override
  State<TermsConditionsPage> createState() =>
      _TermsConditionsPageState();
}

class _TermsConditionsPageState
    extends State<TermsConditionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;
  final Set<int> _expanded = {};

  static const _sections = [
    _Section(
      icon: Icons.rule_folder_outlined,
      color: Color(0xFF3D7BFF),
      title: '1. Acceptance of Terms',
      body:
      'By downloading or using the Application, you automatically agree '
          'to these Terms & Conditions. Please read them carefully before using the app.',
    ),

    _Section(
      icon: Icons.copyright_outlined,
      color: Color(0xFF2DD4A0),
      title: '2. Intellectual Property',
      body:
      'All intellectual property rights including trademarks, copyrights, '
          'database rights, and content belong to the Service Provider.\n\n'
          'You may NOT:\n'
          '• Copy or modify the Application\n'
          '• Extract source code\n'
          '• Translate or create derivative versions\n'
          '• Use trademarks without permission',
    ),

    _Section(
      icon: Icons.settings_applications_outlined,
      color: Color(0xFFFFB347),
      title: '3. Service Modifications',
      body:
      'The Service Provider may modify the Application or introduce charges '
          'at any time.\n\n'
          'Any paid features or changes will be clearly communicated to users.',
    ),

    _Section(
      icon: Icons.lock_outline_rounded,
      color: Color(0xFFB47FFF),
      title: '4. User Responsibilities',
      body:
      'You are responsible for maintaining the security of your device '
          'and access to the Application.\n\n'
          'Avoid rooting or jailbreaking your device, as it may:\n'
          '• Compromise security\n'
          '• Expose your device to malware\n'
          '• Cause the app to malfunction',
    ),

    _Section(
      icon: Icons.data_usage_outlined,
      color: Color(0xFF3D7BFF),
      title: '5. Data Usage & Connectivity',
      body:
      'Some features require an active internet connection.\n\n'
          'The Service Provider is not responsible for:\n'
          '• App limitations due to no internet\n'
          '• Data exhaustion\n'
          '• Network-related issues',
    ),

    _Section(
      icon: Icons.attach_money_outlined,
      color: Color(0xFF2DD4A0),
      title: '6. Charges & Fees',
      body:
      'Using the Application may result in data charges from your mobile provider.\n\n'
          'You are responsible for:\n'
          '• Data usage costs\n'
          '• Roaming charges (if applicable)\n\n'
          'If you are not the bill payer, ensure you have permission.',
    ),

    _Section(
      icon: Icons.battery_alert_outlined,
      color: Color(0xFFFFB347),
      title: '7. Device Responsibility',
      body:
      'You are responsible for keeping your device charged and functional.\n\n'
          'The Service Provider is not liable if you cannot access the app '
          'due to battery or device issues.',
    ),

    _Section(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFB47FFF),
      title: '8. Limitation of Liability',
      body:
      'The Service Provider strives to keep the app accurate and updated '
          'but relies on third-party data.\n\n'
          'They are not liable for:\n'
          '• Direct or indirect losses\n'
          '• Errors or inaccuracies\n'
          '• Reliance on app functionality',
    ),

    _Section(
      icon: Icons.extension_outlined,
      color: Color(0xFF3D7BFF),
      title: '9. Third-Party Services',
      body:
      'The Application uses third-party services such as:\n'
          '• Google Analytics for Firebase\n'
          '• Firebase Crashlytics\n\n'
          'These services have their own Terms & Conditions.',
    ),

    _Section(
      icon: Icons.system_update_alt_rounded,
      color: Color(0xFF2DD4A0),
      title: '10. Updates & Termination',
      body:
      'The Application may be updated periodically.\n\n'
          'You agree to install updates when provided.\n\n'
          'The Service Provider may:\n'
          '• Discontinue the app at any time\n'
          '• Terminate access without notice\n\n'
          'Upon termination, you must stop using and delete the app.',
    ),

    _Section(
      icon: Icons.update_rounded,
      color: Color(0xFFFFB347),
      title: '11. Changes to Terms',
      body:
      'These Terms may be updated periodically.\n\n'
          'Changes will be posted within the Application.\n'
          'Continued use means acceptance of updated terms.\n\n'
          'Effective Date: March 25, 2026',
    ),

    _Section(
      icon: Icons.mail_outline_rounded,
      color: Color(0xFF3D7BFF),
      title: '12. Contact Us',
      body:
      'If you have any questions or suggestions, contact:\n\n'
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
        title: const Text('Terms & Conditions',
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
              const SizedBox(height: 24),
              const Text('Terms Details',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.ts,
                      letterSpacing: 0.8)),
              const SizedBox(height: 12),
              ..._sections.asMap().entries
                  .map((e) => _buildSection(e.key, e.value)),
              const SizedBox(height: 20),
              _buildAgreement(),
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
        _C.green.withOpacity(0.12),
        _C.accent.withOpacity(0.06)
      ]),
      borderRadius: BorderRadius.circular(20),
      border:
      Border.all(color: _C.green.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.article_rounded,
                color: _C.green, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terms & Conditions',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.tp)),
                Text('HR Attendance System',
                    style: TextStyle(
                        fontSize: 11, color: _C.ts)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(color: _C.divider, height: 1),
        const SizedBox(height: 12),
        const Text(
          'Please read these Terms and Conditions carefully before '
              'using the HR Attendance application. By using the app, '
              'you agree to be bound by these terms.',
          style: TextStyle(
              fontSize: 13, color: _C.ts, height: 1.6),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _badge(Icons.calendar_today_rounded,
              'Effective', 'Mar 25, 2026'),
          const SizedBox(width: 10),
          _badge(Icons.language_rounded, 'Version', '2.0'),
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
            Icon(icon, color: _C.green, size: 13),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: _C.tm)),
                Text(val,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _C.tp,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
        ),
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
                  child: Icon(s.icon,
                      color: s.color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: open ? s.color : _C.tp)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }

  Widget _buildAgreement() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.divider),
    ),
    child: Column(children: [
      const Icon(Icons.verified_rounded,
          color: _C.green, size: 30),
      const SizedBox(height: 10),
      const Text('Agreement',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.tp)),
      const SizedBox(height: 8),
      const Text(
        'By using the HR Attendance application, you confirm that '
            'you have read, understood, and agreed to these Terms and '
            'Conditions.',
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