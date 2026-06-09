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

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _uniCtrl     = TextEditingController();
  final _courseCtrl  = TextEditingController();
  final _idCtrl      = TextEditingController();
  bool _loading      = false;
  StudentModel? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) _loadExisting();
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
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _uniCtrl.dispose(); _courseCtrl.dispose(); _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name, phone and email are required'),
        backgroundColor: AppColors.danger,
      ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_existing != null ? 'Student updated' : 'Student added'),
          backgroundColor: AppColors.success,
        ));
        context.go('/students');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Student' : 'Add Student',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/students'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _field('FULL NAME',      _nameCtrl,   'e.g. Tatenda Moyo',       Icons.person_outline),
          const SizedBox(height: 16),
          _field('PHONE NUMBER',   _phoneCtrl,  'e.g. 0771234567',         Icons.phone_outlined,  type: TextInputType.phone),
          const SizedBox(height: 16),
          _field('EMAIL ADDRESS',  _emailCtrl,  'e.g. tatenda@email.com',  Icons.email_outlined,  type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field('UNIVERSITY',     _uniCtrl,    'e.g. University of Zimbabwe', Icons.school_outlined),
          const SizedBox(height: 16),
          _field('COURSE',         _courseCtrl, 'e.g. Computer Science',   Icons.book_outlined),
          const SizedBox(height: 16),
          _field('NATIONAL ID',    _idCtrl,     'e.g. 63-123456A78',       Icons.badge_outlined),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Update Student' : 'Add Student'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      IconData icon, {TextInputType type = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: Color(0xFF64748B), letterSpacing: 0.8)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: type,
        decoration: InputDecoration(hintText: hint,
          prefixIcon: Icon(icon, size: 18))),
    ]);
  }
}