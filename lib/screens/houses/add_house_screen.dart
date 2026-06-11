import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/house_provider.dart';
import '../../providers/landlord_provider.dart';
import '../../models/house_model.dart';

class AddHouseScreen extends ConsumerStatefulWidget {
  final String? houseId;
  const AddHouseScreen({super.key, this.houseId});

  @override
  ConsumerState<AddHouseScreen> createState() => _AddHouseScreenState();
}

class _AddHouseScreenState extends ConsumerState<AddHouseScreen>
    with TickerProviderStateMixin {
  final _addressCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController(text: '1');
  final _rentCtrl = TextEditingController();

  String _status = 'available';
  int? _landlordId;
  bool _loading = false;
  HouseModel? _existing;

  late AnimationController _masterCtrl;
  late AnimationController _saveCtrl;
  final List<Animation<Offset>> _fieldSlides = [];
  final List<Animation<double>> _fieldFades = [];
  late Animation<double> _saveScale;

  // Focus tracking for neon glow
  final _addressFocus = FocusNode();
  final _roomsFocus = FocusNode();
  final _rentFocus = FocusNode();
  bool _addressFocused = false;
  bool _roomsFocused = false;
  bool _rentFocused = false;

  static const int _fieldCount = 5;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _saveCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    for (int i = 0; i < _fieldCount; i++) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      _fieldSlides.add(
        Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _masterCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)),
        ),
      );
      _fieldFades.add(
        Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _masterCtrl,
              curve: Interval(start, end, curve: Curves.easeOut)),
        ),
      );
    }

    _saveScale = Tween(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _saveCtrl, curve: Curves.easeOut),
    );

    _addressFocus.addListener(() => setState(() => _addressFocused = _addressFocus.hasFocus));
    _roomsFocus.addListener(() => setState(() => _roomsFocused = _roomsFocus.hasFocus));
    _rentFocus.addListener(() => setState(() => _rentFocused = _rentFocus.hasFocus));

    if (widget.houseId != null) _loadExisting();
    _masterCtrl.forward();
  }

  void _loadExisting() {
    final id = int.tryParse(widget.houseId!);
    final list = ref.read(houseProvider).valueOrNull ?? [];
    _existing = list.firstWhere((h) => h.id == id, orElse: () => list.first);
    if (_existing != null) {
      _addressCtrl.text = _existing!.address;
      _roomsCtrl.text = _existing!.totalRooms.toString();
      _rentCtrl.text = _existing!.rentPerRoom.toString();
      _status = _existing!.status;
      _landlordId = _existing!.landlordId;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _roomsCtrl.dispose();
    _rentCtrl.dispose();
    _masterCtrl.dispose();
    _saveCtrl.dispose();
    _addressFocus.dispose();
    _roomsFocus.dispose();
    _rentFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_addressCtrl.text.isEmpty || _landlordId == null) {
      _showSnack('Address and landlord are required', isError: true);
      return;
    }
    await _saveCtrl.forward();
    await _saveCtrl.reverse();
    setState(() => _loading = true);
    try {
      final h = HouseModel(
        id: _existing?.id,
        localId: _existing?.localId,
        landlordId: _landlordId,
        address: _addressCtrl.text.trim(),
        totalRooms: int.tryParse(_roomsCtrl.text) ?? 1,
        rentPerRoom: double.tryParse(_rentCtrl.text) ?? 0,
        status: _status,
      );
      if (_existing != null) {
        await ref.read(houseProvider.notifier).updateHouse(h);
      } else {
        await ref.read(houseProvider.notifier).add(h);
      }
      if (mounted) {
        _showSnack(_existing != null ? 'House updated 🏠' : 'House added 🔥', isError: false);
        context.go('/houses');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _staggered(int index, Widget child) {
    return FadeTransition(
      opacity: _fieldFades[index],
      child: SlideTransition(position: _fieldSlides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    final landlords = ref.watch(landlordProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/houses'),
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
                isEdit ? 'Edit House' : 'Add House',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Text(
              isEdit ? 'Update property details' : 'List a new property',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Landlord dropdown ────────────────────────────────
            _staggered(0, _SectionCard(
              children: [
                _FieldLabel('LANDLORD', Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _NeonDropdown<int>(
                  value: _landlordId,
                  hint: 'Select landlord',
                  icon: Icons.person_outline_rounded,
                  items: landlords.map((l) => DropdownMenuItem(
                    value: l.id,
                    child: Text(l.fullName,
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                  )).toList(),
                  onChanged: (v) => setState(() => _landlordId = v),
                ),
              ],
            )),
            const SizedBox(height: 14),

            // ── Address ───────────────────────────────────────────
            _staggered(1, _SectionCard(
              children: [
                _FieldLabel('ADDRESS', Icons.location_on_outlined),
                const SizedBox(height: 10),
                _NeonTextField(
                  controller: _addressCtrl,
                  focusNode: _addressFocus,
                  isFocused: _addressFocused,
                  hint: 'e.g. 12 Borrowdale Road, Harare',
                  icon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.next,
                ),
              ],
            )),
            const SizedBox(height: 14),

            // ── Rooms + Rent ──────────────────────────────────────
            _staggered(2, Row(
              children: [
                Expanded(
                  child: _SectionCard(
                    children: [
                      _FieldLabel('ROOMS', Icons.door_back_door_rounded),
                      const SizedBox(height: 10),
                      _NeonTextField(
                        controller: _roomsCtrl,
                        focusNode: _roomsFocus,
                        isFocused: _roomsFocused,
                        hint: '1',
                        icon: Icons.door_back_door_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SectionCard(
                    children: [
                      _FieldLabel('RENT / RM (\$)', Icons.attach_money_rounded),
                      const SizedBox(height: 10),
                      _NeonTextField(
                        controller: _rentCtrl,
                        focusNode: _rentFocus,
                        isFocused: _rentFocused,
                        hint: '0',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            )),
            const SizedBox(height: 14),

            // ── Status ────────────────────────────────────────────
            _staggered(3, _SectionCard(
              children: [
                _FieldLabel('STATUS', Icons.circle_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatusPill(
                      label: 'Available',
                      color: const Color(0xFF34D399),
                      selected: _status == 'available',
                      onTap: () => setState(() => _status = 'available'),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(
                      label: 'Full',
                      color: const Color(0xFFEF4444),
                      selected: _status == 'full',
                      onTap: () => setState(() => _status = 'full'),
                    ),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────
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

// ── Section card container ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FieldLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF818CF8)),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF818CF8),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Neon text field ───────────────────────────────────────────────────────────
class _NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const _NeonTextField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF818CF8).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: Icon(icon,
              size: 17,
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

// ── Neon dropdown ─────────────────────────────────────────────────────────────
class _NeonDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _NeonDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B), size: 20),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
        prefixIcon: Icon(icon, size: 17, color: const Color(0xFF475569)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
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
      items: items,
      onChanged: onChanged,
    );
  }
}

// ── Status pill toggle ────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white.withOpacity(0.4),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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

  const _SaveButton({
    required this.isEdit,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
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
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEdit ? Icons.save_rounded : Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEdit ? 'Update House' : 'Add House',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}