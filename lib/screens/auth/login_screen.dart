import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _masterCtrl;
  late AnimationController _auroraCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _buttonCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardOpacity;
  late Animation<double> _auroraRotate;
  late Animation<double> _pulse;
  late Animation<double> _shakeX;
  late Animation<double> _buttonScale;

  bool _obscure = true;
  bool _rememberMe = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passwordFocus.addListener(() => setState(() => _passwordFocused = _passwordFocus.hasFocus));
  }

  void _setupAnimations() {
    _masterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _auroraCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _buttonCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.0, 0.5)));

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.0, 0.3)),
    );

    _cardSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );

    _cardOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.3, 0.7)),
    );

    _auroraRotate = Tween(begin: 0.0, end: 2 * math.pi).animate(_auroraCtrl);

    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _shakeX = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _buttonScale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut),
    );

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _masterCtrl.dispose();
    _auroraCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _buttonCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    await _buttonCtrl.forward();
    await _buttonCtrl.reverse();
    developer.log('Attempting login for: ${_emailCtrl.text}', name: 'LOGIN');
    try {
      await ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
    } catch (e) {
      developer.log('Login error: $e', name: 'LOGIN', error: e);
    }
  }

  void _showEliteSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'GOT IT',
          textColor: Colors.white.withOpacity(0.85),
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Min 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    ref.listen<AsyncValue<UserModel?>>(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null && mounted) {
            _showEliteSnackbar('Welcome back, ${user.fullName} 🔥', isError: false);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go('/dashboard');
            });
          }
        },
        error: (err, stack) {
          _shakeCtrl.forward(from: 0);
          _showEliteSnackbar(err.toString());
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Aurora background ──────────────────────────────────
          _AuroraBackground(animation: _auroraRotate, size: size),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _LogoWidget(pulse: _pulse),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Brand text
                    FadeTransition(
                      opacity: _cardOpacity,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFF38BDF8), Color(0xFF34D399)],
                            ).createShader(bounds),
                            child: const Text(
                              'Pondai Housing',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF818CF8).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF818CF8).withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              '✦  Student Accommodation Management',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Glass card ────────────────────────────────
                    AnimatedBuilder(
                      animation: _shakeX,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeX.value, 0),
                        child: child,
                      ),
                      child: SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardOpacity,
                          child: _GlassCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Your portal awaits 👀',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Email field
                                  _NeonField(
                                    controller: _emailCtrl,
                                    focusNode: _emailFocus,
                                    isFocused: _emailFocused,
                                    label: 'Email',
                                    hint: 'agent@pondaihousing.com',
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  _NeonField(
                                    controller: _passwordCtrl,
                                    focusNode: _passwordFocus,
                                    isFocused: _passwordFocused,
                                    label: 'Password',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) => _login(),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() => _obscure = !_obscure),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          key: ValueKey(_obscure),
                                          size: 18,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Remember + Forgot
                                  Row(
                                    children: [
                                      _PillToggle(
                                        value: _rememberMe,
                                        label: 'Remember me',
                                        onChanged: (v) => setState(() => _rememberMe = v),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => _showEliteSnackbar(
                                          'Reset link sent! Check your inbox 📬',
                                          isError: false,
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Forgot?',
                                          style: TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign in button
                                  ScaleTransition(
                                    scale: _buttonScale,
                                    child: _SignInButton(
                                      isLoading: authState.isLoading,
                                      onPressed: _login,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Demo hint
                    FadeTransition(
                      opacity: _cardOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🧪', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            Text(
                              'agent@pondaihousing.com · admin1234',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }
}

// ── Aurora animated background ─────────────────────────────────────────────────
class _AuroraBackground extends StatelessWidget {
  final Animation<double> animation;
  final Size size;
  const _AuroraBackground({required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(color: Color(0xFF060B18)),
          child: Stack(
            children: [
              // Orb 1 — purple
              Positioned(
                top: -100 + math.sin(animation.value) * 60,
                left: -80 + math.cos(animation.value * 0.7) * 40,
                child: _Orb(
                  diameter: 380,
                  color: const Color(0xFF818CF8).withOpacity(0.25),
                ),
              ),
              // Orb 2 — cyan
              Positioned(
                bottom: -120 + math.cos(animation.value * 0.5) * 50,
                right: -80 + math.sin(animation.value * 0.8) * 30,
                child: _Orb(
                  diameter: 340,
                  color: const Color(0xFF38BDF8).withOpacity(0.18),
                ),
              ),
              // Orb 3 — emerald
              Positioned(
                top: size.height * 0.4 + math.sin(animation.value * 1.3) * 40,
                left: size.width * 0.3 + math.cos(animation.value * 0.9) * 20,
                child: _Orb(
                  diameter: 220,
                  color: const Color(0xFF34D399).withOpacity(0.12),
                ),
              ),
              // Noise overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF060B18).withOpacity(0.3),
                      Colors.transparent,
                      const Color(0xFF060B18).withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double diameter;
  final Color color;
  const _Orb({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

// ── Pulsing logo ───────────────────────────────────────────────────────────────
class _LogoWidget extends StatelessWidget {
  final Animation<double> pulse;
  const _LogoWidget({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) => Transform.scale(scale: pulse.value, child: child),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF818CF8).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF818CF8), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF818CF8).withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

// ── Glass card ────────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Neon input field ──────────────────────────────────────────────────────────
class _NeonField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _NeonField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF818CF8).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused
                ? const Color(0xFF818CF8)
                : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: Icon(icon,
              size: 18,
              color: isFocused ? const Color(0xFF818CF8) : const Color(0xFF475569)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isFocused
              ? const Color(0xFF818CF8).withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ── Remember me pill toggle ───────────────────────────────────────────────────
class _PillToggle extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const _PillToggle({required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF818CF8).withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: value
                ? const Color(0xFF818CF8).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? const Color(0xFF818CF8) : Colors.transparent,
                border: Border.all(
                  color: value ? const Color(0xFF818CF8) : const Color(0xFF475569),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF818CF8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign in button ────────────────────────────────────────────────────────────
class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFF38BDF8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? const Color(0xFF1E293B) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}