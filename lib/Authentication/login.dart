import 'package:attendec/pages/dashboard_screen.dart';
import 'package:attendec/pages/terms&conditions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../pages/privacy_policy.dart';
import 'sign_in_with_google.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  bool _isLoading       = false;
  bool _isAppleLoading  = false;

  late AnimationController _fadeCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double>  _fadeAnim;
  late Animation<Offset>  _slideAnim;
  late Animation<double>  _floatAnim;
  late Animation<double>  _pulseAnim;
  late Animation<double>  _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000))
      ..forward();

    _fadeAnim = CurvedAnimation(
        parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _fadeCtrl, curve: Curves.easeOutCubic));

    // Floating logo animation
    _floatCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(
        parent: _floatCtrl, curve: Curves.easeInOut));

    // Pulse ring animation
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(
        parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(
        parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Google Sign In ───────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = GoogleAuthService();
      final User? user = await authService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) =>
                DashboardScreen(user: user),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration:
            const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFFF5A5A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated background ───────────
          _buildBackground(size),

          // ── Decorative circles ────────────
          _buildDecorCircles(size),

          // ── Main content ──────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        _buildLogo(),
                        const SizedBox(height: 36),

                        // Heading
                        _buildHeading(),
                        const SizedBox(height: 36),

                        // Sign in card
                        _buildSignInCard(),
                        const SizedBox(height: 28),

                        // Terms text
                        _buildTermsText(),
                      ],
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

  // ── Background ───────────────────────────
  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A18),
            Color(0xFF0D1B3E),
            Color(0xFF0A0A18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ── Decorative floating circles ──────────
  Widget _buildDecorCircles(Size size) {
    return Stack(children: [
      // Top-right large circle
      Positioned(
        top: -60,
        right: -60,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3D7BFF).withOpacity(0.18),
                    const Color(0xFF3D7BFF).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Bottom-left circle
      Positioned(
        bottom: 80,
        left: -80,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9A7).withOpacity(0.1),
                    const Color(0xFF00C9A7).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Small accent dot top-left
      Positioned(
        top: size.height * 0.15,
        left: 30,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3D7BFF).withOpacity(0.6),
          ),
        ),
      ),

      // Small accent dot bottom-right
      Positioned(
        bottom: size.height * 0.2,
        right: 40,
        child: Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00C9A7).withOpacity(0.5),
          ),
        ),
      ),
    ]);
  }

  // ── Logo ─────────────────────────────────
  Widget _buildLogo() {
    return Center(
      child: AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3D7BFF)
                        .withOpacity(_pulseAnim.value * 0.4),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Inner glow ring
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00C9A7)
                      .withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),

            // Logo circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3D7BFF),
                    Color(0xFF00C9A7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3D7BFF)
                        .withOpacity(0.5),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00C9A7)
                        .withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Heading ──────────────────────────────
  Widget _buildHeading() {
    return Column(children: [
      // App name chip
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF3D7BFF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3D7BFF).withOpacity(0.25),
            ),
          ),
          child: const Text(
            'ATTENDANCE MANAGEMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D7BFF),
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      const Text(
        'Welcome To AttendyPro',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Sign in to Manage Employee Attendance and view reports',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.45),
          height: 1.5,
          letterSpacing: 0.1,
        ),
      ),
    ]);
  }

  // ── Sign In Card ─────────────────────────
  Widget _buildSignInCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF3D7BFF).withOpacity(0.05),
            blurRadius: 60,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 1,
                color: Colors.white.withOpacity(0.12),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                child: Text(
                  'Choose sign-in method',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.35),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 1,
                color: Colors.white.withOpacity(0.12),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Google button
          _buildGoogleButton(),
          const SizedBox(height: 14),

          // Divider
          Row(children: [
            Expanded(
                child: Divider(
                    color: Colors.white.withOpacity(0.08))),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14),
              child: Text('or',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 12)),
            ),
            Expanded(
                child: Divider(
                    color: Colors.white.withOpacity(0.08))),
          ]),
          const SizedBox(height: 14),

          // Apple button
          _buildAppleButton(),
        ],
      ),
    );
  }

  // ── Google Button ─────────────────────────
  Widget _buildGoogleButton() {
    return _AuthButton(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      isLoading: _isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFF3D7BFF), Color(0xFF1A4FCC)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      shadowColor: const Color(0xFF3D7BFF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Continue with Google',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Apple Button ──────────────────────────
  Widget _buildAppleButton() {
    return _AuthButton(
      onTap: () {
        Fluttertoast.showToast(
          msg: 'Coming Soon! Apple Sign-In is under development.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF1E1E30),
          textColor: Colors.white,
          fontSize: 13.0,
        );
      },
      isLoading: _isAppleLoading,
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.06),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      shadowColor: Colors.transparent,
      hasBorder: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(Icons.apple_rounded,
                  color: Colors.black, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Continue with Apple',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Terms Text ────────────────────────────
  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 12,
          height: 1.7,
        ),
        children: [
          const TextSpan(
              text:
              'By signing in, you agree to our\n'),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(
              color: Color(0xFF3D7BFF),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF3D7BFF),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const TermsConditionsPage()),
              ),
          ),
          TextSpan(
            text: '  •  ',
            style: TextStyle(
                color: Colors.white.withOpacity(0.2)),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: Color(0xFF00C9A7),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF00C9A7),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const PrivacyPolicyPage()),
              ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// REUSABLE AUTH BUTTON WIDGET
// ─────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final Gradient gradient;
  final Color shadowColor;
  final Widget child;
  final bool hasBorder;

  const _AuthButton({
    required this.onTap,
    required this.isLoading,
    required this.gradient,
    required this.shadowColor,
    required this.child,
    this.hasBorder = false,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double>   _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(
        parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) => Transform.scale(
          scale: _pressAnim.value,
          child: child,
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            border: widget.hasBorder
                ? Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1)
                : null,
            boxShadow: widget.shadowColor != Colors.transparent
                ? [
              BoxShadow(
                color: widget.shadowColor
                    .withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5))
                : widget.child,
          ),
        ),
      ),
    );
  }
}