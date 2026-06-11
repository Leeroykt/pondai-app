import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  final String? studentId;
  const AddStudentScreen({super.key, this.studentId});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen>
    with TickerProviderStateMixin {
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _uniCtrl    = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _idCtrl     = TextEditingController();
  bool _loading     = false;
  StudentModel? _existing;

  late AnimationController _headerCtrl;
  late AnimationController _btnCtrl;
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _btnCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

    if (widget.studentId != null) _loadExisting();

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  void _loadExisting() {
    final id   = int.tryParse(widget.studentId!);
    final list = ref.read(studentProvider).valueOrNull ?? [];
    _existing  = list.firstWhere((s) => s.id == id, orElse: () => list.first);
    if (_existing != null) {
      _nameCtrl.text   = _existing!.fullName;
      _phoneCtrl.text  = _existing!.phone;
      _emailCtrl.text  = _existing!.email;
      _uniCtrl.text    = _existing!.university;
      _courseCtrl.text = _existing!.course;
      _idCtrl.text     = _existing!.nationalId;
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _btnCtrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _uniCtrl.dispose(); _courseCtrl.dispose(); _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      _showSnack('Name, phone and email are required', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final s = StudentModel(
        id: _existing?.id, localId: _existing?.localId,
        fullName: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(), university: _uniCtrl.text.trim(),
        course: _courseCtrl.text.trim(), nationalId: _idCtrl.text.trim(),
      );
      if (_existing != null) {
        await ref.read(studentProvider.notifier).updateStudent(s);
      } else {
        await ref.read(studentProvider.notifier).add(s);
      }
      if (mounted) {
        _showSnack(_existing != null ? 'Student updated 🎉' : 'Student added 🎉',
          isError: false);
        context.go('/students');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    final fields = [
      _FieldConfig('FULL NAME',    _nameCtrl,   'e.g. Tatenda Moyo',          Icons.person_outline_rounded,  TextInputType.name),
      _FieldConfig('PHONE',        _phoneCtrl,  'e.g. 0771234567',            Icons.phone_outlined,           TextInputType.phone),
      _FieldConfig('EMAIL',        _emailCtrl,  'e.g. tatenda@email.com',     Icons.email_outlined,           TextInputType.emailAddress),
      _FieldConfig('UNIVERSITY',   _uniCtrl,    'e.g. University of Zimbabwe', Icons.school_outlined,         TextInputType.text),
      _FieldConfig('COURSE',       _courseCtrl, 'e.g. Computer Science',      Icons.book_outlined,            TextInputType.text),
      _FieldConfig('NATIONAL ID',  _idCtrl,     'e.g. 63-123456A78',          Icons.badge_outlined,           TextInputType.text),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(children: [
        // Ambient glows
        Positioned(top: -100, right: -80,
          child: _GlowBlob(color: const Color(0xFF7C3AED).withOpacity(0.2), size: 280)),
        Positioned(bottom: -60, left: -60,
          child: _GlowBlob(color: const Color(0xFF06B6D4).withOpacity(0.12), size: 200)),

        Column(children: [
          // Custom AppBar
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.go('/students'),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1F2937)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'Edit Student' : 'Add Student',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]).createShader(b),
                      child: Text(isEdit ? 'update details' : 'fill in the deets',
                        style: const TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w500)),
                    ),
                  ],
                )),
                // Step indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: Row(children: [
                    Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F2937), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F2937), shape: BoxShape.circle)),
                  ]),
                ),
              ]),
            ),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(children: [
              // Avatar preview
              FadeTransition(
                opacity: CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
                child: Center(child: _AvatarPreview(nameCtrl: _nameCtrl)),
              ),
              const SizedBox(height: 28),
              // Fields
              ...List.generate(fields.length, (i) => _AnimatedField(
                index: i,
                config: fields[i],
                focused: _focusedIndex == i,
                onFocus: () => setState(() => _focusedIndex = i),
                onUnfocus: () => setState(() {
                  if (_focusedIndex == i) _focusedIndex = -1;
                }),
              )),
            ]),
          )),
        ]),

        // Sticky save button
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOutCubic)),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1E),
                border: const Border(
                  top: BorderSide(color: Color(0xFF111827))),
              ),
              child: _SaveButton(loading: _loading, isEdit: isEdit, onSave: _save),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Avatar Preview ───────────────────────────────────────────────────────────

class _AvatarPreview extends StatefulWidget {
  final TextEditingController nameCtrl;
  const _AvatarPreview({required this.nameCtrl});

  @override
  State<_AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<_AvatarPreview> {
  @override
  void initState() {
    super.initState();
    widget.nameCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.nameCtrl.text;
    final initials = name.isNotEmpty
      ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
      : '?';

    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(child: Text(initials,
          style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 26))),
      ),
      const SizedBox(height: 10),
      Text(name.isEmpty ? 'New Student' : name,
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}

// ─── Animated Field ───────────────────────────────────────────────────────────

class _FieldConfig {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  const _FieldConfig(this.label, this.ctrl, this.hint, this.icon, this.type);
}

class _AnimatedField extends StatefulWidget {
  final int index;
  final _FieldConfig config;
  final bool focused;
  final VoidCallback onFocus;
  final VoidCallback onUnfocus;
  const _AnimatedField({required this.index, required this.config,
    required this.focused, required this.onFocus, required this.onUnfocus});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: 80 * widget.index + 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                color: widget.focused ? const Color(0xFF7C3AED) : const Color(0xFF4B5563)),
              child: Text(widget.config.label)),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.focused
                    ? const Color(0xFF7C3AED).withOpacity(0.7)
                    : const Color(0xFF1F2937),
                  width: widget.focused ? 1.5 : 1),
                boxShadow: widget.focused ? [
                  BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.15),
                    blurRadius: 12, offset: const Offset(0, 4)),
                ] : [],
              ),
              child: TextField(
                controller: widget.config.ctrl,
                keyboardType: widget.config.type,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onTap: widget.onFocus,
                onEditingComplete: widget.onUnfocus,
                decoration: InputDecoration(
                  hintText: widget.config.hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF374151), fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(widget.config.icon,
                        key: ValueKey(widget.focused),
                        size: 18,
                        color: widget.focused
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF374151)),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool loading;
  final bool isEdit;
  final VoidCallback onSave;
  const _SaveButton({required this.loading, required this.isEdit, required this.onSave});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 120), lowerBound: 0.96, upperBound: 1.0)
      ..value = 1.0;
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (!widget.loading) _pressCtrl.reverse(); },
      onTapUp: (_) { _pressCtrl.forward(); if (!widget.loading) widget.onSave(); },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.loading ? null : const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
            color: widget.loading ? const Color(0xFF1F2937) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.loading ? [] : [
              BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.45),
                blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: widget.loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFF7C3AED)))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(widget.isEdit ? Icons.save_rounded : Icons.person_add_rounded,
                    color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(widget.isEdit ? 'Update Student' : 'Add Student',
                    style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2)),
                ]),
          ),
        ),
      ),
    );
  }
}

// ─── Glow Blob ────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color,
          blurRadius: size * 0.8, spreadRadius: size * 0.2)]),
    );
  }
}