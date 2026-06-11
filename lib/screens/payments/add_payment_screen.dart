import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../models/payment_model.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen>
    with TickerProviderStateMixin {
  int? _assignmentId;
  String _studentName = '';
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  DateTime? _selectedDate;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _method = 'cash';

  late AnimationController _headerCtrl;
  late AnimationController _btnCtrl;
  int _focusedIndex = -1;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _methodData = [
    _MethodOption('cash', 'Cash', Icons.payments_rounded, Color(0xFF10B981)),
    _MethodOption('ecocash', 'EcoCash', Icons.phone_android_rounded, Color(0xFFF59E0B)),
    _MethodOption('bank', 'Bank Transfer', Icons.account_balance_rounded, Color(0xFF06B6D4)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _btnCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _formattedDate =>
      '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

  String get _monthYearText => '${_months[_selectedMonth - 1]} $_selectedYear';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payment = PaymentModel(
        assignmentId: _assignmentId!,
        studentName: _studentName,
        amount: double.parse(_amountCtrl.text),
        paymentDate: _formattedDate,
        monthPaidFor: _monthYearText,
        method: _method,
        notes: _notesCtrl.text.trim(),
      );
      await ref.read(paymentProvider.notifier).add(payment);
      developer.log('Payment recorded: \$${_amountCtrl.text} for $_studentName', name: 'PAYMENT');
      if (mounted) {
        _showSnack('Payment recorded 🎉', isError: false);
        context.go('/payments');
      }
    } catch (e) {
      developer.log('Payment error: $e', name: 'PAYMENT', error: e);
      if (mounted) _showSnack('Error: ${e.toString().replaceAll('Exception:', '')}', isError: true);
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
    final assignmentsAsync = ref.watch(assignmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(children: [
        Positioned(top: -100, right: -60,
          child: _GlowBlob(color: const Color(0xFF10B981).withOpacity(0.18), size: 260)),
        Positioned(bottom: -60, left: -80,
          child: _GlowBlob(color: const Color(0xFF06B6D4).withOpacity(0.12), size: 200)),

        Column(children: [
          // AppBar
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16, right: 16, bottom: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.go('/payments'),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1F2937))),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Record Payment', style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)]).createShader(b),
                    child: const Text('log the bag 💰',
                        style: TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ])),
              ]),
            ),
          ),

          Expanded(child: assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(
                color: Color(0xFF10B981))),
            error: (e, _) => _buildLoadError(e.toString()),
            data: (assignments) {
              final active = assignments.where((a) => a.status == 'active').toList();
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // ── Student selector ──
                    _buildSectionLabel('WHO PAID?', index: 0),
                    const SizedBox(height: 8),
                    _AnimatedFieldWrap(index: 0, child: _StudentDropdown(
                      assignments: active,
                      value: _assignmentId,
                      onChanged: (id, name) => setState(() {
                        _assignmentId = id;
                        _studentName = name;
                      }),
                    )),
                    const SizedBox(height: 20),

                    // ── Amount ──
                    _buildSectionLabel('AMOUNT (USD)', index: 1),
                    const SizedBox(height: 8),
                    _AnimatedFieldWrap(
                      index: 1,
                      child: _GlowTextField(
                        controller: _amountCtrl,
                        hint: 'e.g. 150.00',
                        icon: Icons.attach_money_rounded,
                        accentColor: const Color(0xFF10B981),
                        focused: _focusedIndex == 1,
                        onFocus: () => setState(() => _focusedIndex = 1),
                        onUnfocus: () => setState(() { if (_focusedIndex == 1) _focusedIndex = -1; }),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Amount is required';
                          final a = double.tryParse(v);
                          if (a == null || a <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Payment method ──
                    _buildSectionLabel('METHOD', index: 2),
                    const SizedBox(height: 10),
                    _AnimatedFieldWrap(
                      index: 2,
                      child: Row(children: _methodData.map((m) => Expanded(child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _MethodChip(
                          option: m,
                          selected: _method == m.value,
                          onTap: () => setState(() => _method = m.value),
                        ),
                      ))).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Month paid for ──
                    _buildSectionLabel('MONTH PAID FOR', index: 3),
                    const SizedBox(height: 8),
                    _AnimatedFieldWrap(
                      index: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1F2937))),
                        child: Row(children: [
                          Expanded(child: _DarkDropdown<int>(
                            value: _selectedMonth,
                            items: List.generate(12, (i) => DropdownMenuItem(
                                value: i + 1, child: Text(_months[i]))),
                            onChanged: (v) { if (v != null) setState(() => _selectedMonth = v); },
                          )),
                          Container(width: 1, height: 28, color: const Color(0xFF1F2937)),
                          Expanded(child: _DarkDropdown<int>(
                            value: _selectedYear,
                            items: List.generate(5, (i) {
                              final y = DateTime.now().year - 2 + i;
                              return DropdownMenuItem(value: y, child: Text(y.toString()));
                            }),
                            onChanged: (v) { if (v != null) setState(() => _selectedYear = v); },
                          )),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Payment date ──
                    _buildSectionLabel('PAYMENT DATE', index: 4),
                    const SizedBox(height: 8),
                    _AnimatedFieldWrap(
                      index: 4,
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF10B981),
                                      surface: Color(0xFF111827))),
                              child: child!),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1F2937))),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 12),
                            Text(_formattedDate,
                                style: const TextStyle(color: Colors.white, fontSize: 14)),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down_rounded,
                                color: Color(0xFF4B5563), size: 20),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Notes ──
                    _buildSectionLabel('NOTES (optional)', index: 5),
                    const SizedBox(height: 8),
                    _AnimatedFieldWrap(
                      index: 5,
                      child: _GlowTextField(
                        controller: _notesCtrl,
                        hint: 'Anything worth noting about this payment...',
                        icon: Icons.notes_rounded,
                        accentColor: const Color(0xFF7C3AED),
                        focused: _focusedIndex == 5,
                        maxLines: 3,
                        onFocus: () => setState(() => _focusedIndex = 5),
                        onUnfocus: () => setState(() { if (_focusedIndex == 5) _focusedIndex = -1; }),
                      ),
                    ),
                  ]),
                ),
              );
            },
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
              decoration: const BoxDecoration(
                  color: Color(0xFF0A0F1E),
                  border: Border(top: BorderSide(color: Color(0xFF111827)))),
              child: _SaveButton(loading: _loading, onSave: _save),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionLabel(String text, {required int index}) {
    return _AnimatedFieldWrap(
      index: index,
      child: Text(text, style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2,
        color: Color(0xFF4B5563))),
    );
  }

  Widget _buildLoadError(String e) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36)),
      const SizedBox(height: 16),
      const Text('Failed to load assignments', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: () => ref.refresh(assignmentProvider),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
              borderRadius: BorderRadius.circular(12)),
          child: const Text('Retry', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700))),
      ),
    ]));
  }
}

// ─── Student Dropdown ─────────────────────────────────────────────────────────

class _StudentDropdown extends StatelessWidget {
  final List assignments;
  final int? value;
  final void Function(int id, String name) onChanged;
  const _StudentDropdown({required this.assignments, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937))),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          value: value,
          dropdownColor: const Color(0xFF1F2937),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4B5563)),
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.person_outline_rounded, color: Color(0xFF10B981), size: 18)),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
          hint: const Text('Select active student',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
          items: assignments.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
            value: a.id as int,
            child: Text(a.studentName as String,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.white)),
          )).toList(),
          onChanged: (v) {
            if (v == null) return;
            final a = assignments.firstWhere((a) => a.id == v);
            onChanged(v, a.studentName as String);
          },
          validator: (v) => v == null ? 'Please select a student assignment' : null,
        ),
      ),
    );
  }
}

// ─── Method Chip ──────────────────────────────────────────────────────────────

class _MethodOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _MethodOption(this.value, this.label, this.icon, this.color);
}

class _MethodChip extends StatefulWidget {
  final _MethodOption option;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip({required this.option, required this.selected, required this.onTap});

  @override
  State<_MethodChip> createState() => _MethodChipState();
}

class _MethodChipState extends State<_MethodChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120), lowerBound: 0.92, upperBound: 1.0)
      ..value = 1.0;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.option.color;
    final sel = widget.selected;
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? c.withOpacity(0.15) : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? c : const Color(0xFF1F2937),
              width: sel ? 1.5 : 1),
            boxShadow: sel ? [BoxShadow(
              color: c.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.option.icon, color: sel ? c : const Color(0xFF4B5563), size: 20),
            const SizedBox(height: 6),
            Text(widget.option.label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: sel ? c : const Color(0xFF4B5563)),
              textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ─── Glow TextField ───────────────────────────────────────────────────────────

class _GlowTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final bool focused;
  final VoidCallback onFocus;
  final VoidCallback onUnfocus;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _GlowTextField({
    required this.controller, required this.hint, required this.icon,
    required this.accentColor, required this.focused,
    required this.onFocus, required this.onUnfocus,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? accentColor.withOpacity(0.7) : const Color(0xFF1F2937),
          width: focused ? 1.5 : 1),
        boxShadow: focused ? [BoxShadow(
          color: accentColor.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onTap: onFocus,
        onEditingComplete: onUnfocus,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF374151), fontSize: 14),
          prefixIcon: maxLines == 1 ? Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, key: ValueKey(focused), size: 18,
                  color: focused ? accentColor : const Color(0xFF374151))),
          ) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              vertical: 14, horizontal: maxLines > 1 ? 14 : 4),
        ),
      ),
    );
  }
}

// ─── Dark Dropdown ────────────────────────────────────────────────────────────

class _DarkDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  const _DarkDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1F2937),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4B5563), size: 18),
        items: items,
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onSave;
  const _SaveButton({required this.loading, required this.onSave});

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
              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
            color: widget.loading ? const Color(0xFF1F2937) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.loading ? [] : [
              BoxShadow(color: const Color(0xFF10B981).withOpacity(0.45),
                  blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Color(0xFF10B981)))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Record Payment', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 15, letterSpacing: 0.2)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Field Wrap ──────────────────────────────────────────────────────

class _AnimatedFieldWrap extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedFieldWrap({required this.index, required this.child});

  @override
  State<_AnimatedFieldWrap> createState() => _AnimatedFieldWrapState();
}

class _AnimatedFieldWrapState extends State<_AnimatedFieldWrap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: 80 * widget.index + 150), () {
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
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: widget.child,
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
    return Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color,
              blurRadius: size * 0.8, spreadRadius: size * 0.2)]));
  }
}