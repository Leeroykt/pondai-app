import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/landlord_provider.dart';
import '../../models/landlord_model.dart';

class AddLandlordScreen extends ConsumerStatefulWidget {
  final String? landlordId;
  const AddLandlordScreen({super.key, this.landlordId});

  @override
  ConsumerState<AddLandlordScreen> createState() => _AddLandlordScreenState();
}

class _AddLandlordScreenState extends ConsumerState<AddLandlordScreen>
    with TickerProviderStateMixin {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _nameFocus    = FocusNode();
  final _phoneFocus   = FocusNode();
  final _emailFocus   = FocusNode();
  final _addressFocus = FocusNode();

  bool _nameFocused    = false;
  bool _phoneFocused   = false;
  bool _emailFocused   = false;
  bool _addressFocused = false;

  bool _loading = false;
  LandlordModel? _existing;

  late AnimationController _masterCtrl;
  late AnimationController _saveCtrl;
  final List<Animation<double>> _fades = [];
  final List<Animation<Offset>> _slides = [];
  late Animation<double> _saveScale;

  static const int _fieldCount = 5;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _saveCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    for (int i = 0; i < _fieldCount; i++) {
      final start = i * 0.1;
      final end = (start + 0.45).clamp(0.0, 1.0);
      _fades.add(Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _masterCtrl, curve: Interval(start, end, curve: Curves.easeOut)),
      ));
      _slides.add(Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(parent: _masterCtrl, curve: Interval(start, end, curve: Curves.easeOutCubic)),
      ));
    }

    _saveScale = Tween(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _saveCtrl, curve: Curves.easeOut),
    );

    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _phoneFocus.addListener(() => setState(() => _phoneFocused = _phoneFocus.hasFocus));
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _addressFocus.addListener(() => setState(() => _addressFocused = _addressFocus.hasFocus));

    if (widget.landlordId != null) _loadExisting();
    _masterCtrl.forward();
  }

  void _loadExisting() {
    final id   = int.tryParse(widget.landlordId!);
    final list = ref.read(landlordProvider).valueOrNull ?? [];
    _existing  = list.firstWhere((l) => l.id == id, orElse: () => list.first);
    if (_existing != null) {
      _nameCtrl.text    = _existing!.fullName;
      _phoneCtrl.text   = _existing!.phone;
      _emailCtrl.text   = _existing!.email;
      _addressCtrl.text = _existing!.address;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _addressCtrl.dispose();
    _nameFocus.dispose(); _phoneFocus.dispose();
    _emailFocus.dispose(); _addressFocus.dispose();
    _masterCtrl.dispose(); _saveCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      _showSnack('Name, phone and email are required', isError: true);
      return;
    }
    await _saveCtrl.forward();
    await _saveCtrl.reverse();
    setState(() => _loading = true);
    try {
      final l = LandlordModel(
        id: _existing?.id, localId: _existing?.localId,
        fullName: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(), address: _addressCtrl.text.trim(),
      );
      if (_existing != null) {
        await ref.read(landlordProvider.notifier).updateLandlord(l);
      } else {
        await ref.read(landlordProvider.notifier).add(l);
      }
      if (mounted) {
        _showSnack(_existing != null ? 'Landlord updated 🙌' : 'Landlord added 🔥', isError: false);
        context.go('/landlords');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  Widget _staggered(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/landlords'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF38BDF8)],
              ).createShader(bounds),
              child: Text(
                isEdit ? 'Edit Landlord' : 'Add Landlord',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Text(
              isEdit ? 'Update contact details' : 'Register a new landlord',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Avatar placeholder ────────────────────────────────
            _staggered(0, Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF818CF8).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF818CF8).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF818CF8),
                  size: 36,
                ),
              ),
            )),
            const SizedBox(height: 28),

            // ── Name ──────────────────────────────────────────────
            _staggered(1, _FieldCard(
              label: 'FULL NAME',
              icon: Icons.person_outline_rounded,
              child: _NeonInput(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                isFocused: _nameFocused,
                hint: 'e.g. John Moyo',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _phoneFocus.requestFocus(),
              ),
            )),
            const SizedBox(height: 12),

            // ── Phone ─────────────────────────────────────────────
            _staggered(2, _FieldCard(
              label: 'PHONE NUMBER',
              icon: Icons.phone_outlined,
              child: _NeonInput(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                isFocused: _phoneFocused,
                hint: 'e.g. 0771234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
            )),
            const SizedBox(height: 12),

            // ── Email ─────────────────────────────────────────────
            _staggered(3, _FieldCard(
              label: 'EMAIL ADDRESS',
              icon: Icons.alternate_email_rounded,
              child: _NeonInput(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                isFocused: _emailFocused,
                hint: 'e.g. john@email.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _addressFocus.requestFocus(),
              ),
            )),
            const SizedBox(height: 12),

            // ── Address ───────────────────────────────────────────
            _staggered(3, _FieldCard(
              label: 'ADDRESS',
              icon: Icons.location_on_outlined,
              badge: 'Optional',
              child: _NeonInput(
                controller: _addressCtrl,
                focusNode: _addressFocus,
                isFocused: _addressFocused,
                hint: 'e.g. 123 Main St, Harare',
                icon: Icons.location_on_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            )),
            const SizedBox(height: 32),

            // ── Save ──────────────────────────────────────────────
            _staggered(4, ScaleTransition(
              scale: _saveScale,
              child: _SaveButton(
                isEdit: isEdit,
                isLoading: _loading,
                onPressed: _save,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Field card wrapper ─────────────────────────────────────────────────────────
class _FieldCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final Widget child;
  const _FieldCard({required this.label, required this.icon, this.badge, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF818CF8)),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF818CF8),
                  letterSpacing: 1.2,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Neon input ────────────────────────────────────────────────────────────────
class _NeonInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _NeonInput({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused
            ? [BoxShadow(
                color: const Color(0xFF818CF8).withOpacity(0.25),
                blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: Icon(icon, size: 17,
              color: isFocused ? const Color(0xFF818CF8) : const Color(0xFF475569)),
          filled: true,
          fillColor: isFocused
              ? const Color(0xFF818CF8).withOpacity(0.07)
              : Colors.white.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.09)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool isEdit;
  final bool isLoading;
  final VoidCallback onPressed;
  const _SaveButton({required this.isEdit, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFF38BDF8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: isLoading ? const Color(0xFF1E293B) : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLoading ? [] : [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 24, offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEdit ? Icons.save_rounded : Icons.person_add_rounded,
                      color: Colors.white, size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEdit ? 'Update Landlord' : 'Add Landlord',
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}