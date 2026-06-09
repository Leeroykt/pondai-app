import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/house_provider.dart';
import '../../models/assignment_model.dart';

class AddAssignmentScreen extends ConsumerStatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  ConsumerState<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends ConsumerState<AddAssignmentScreen> {
  int?   _studentId;
  int?   _houseId;
  String _studentName  = '';
  String _houseAddress = '';
  final  _roomCtrl     = TextEditingController();
  final  _startCtrl    = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10));
  bool   _loading      = false;

  @override
  void dispose() { _roomCtrl.dispose(); _startCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_studentId == null || _houseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Student and house are required'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(assignmentProvider.notifier).add(AssignmentModel(
        studentId: _studentId, houseId: _houseId,
        studentName: _studentName, houseAddress: _houseAddress,
        roomNumber: _roomCtrl.text.trim(),
        startDate: _startCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Assignment created'),
          backgroundColor: AppColors.success,
        ));
        context.go('/assignments');
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
    final students = ref.watch(studentProvider).valueOrNull ?? [];
    final houses   = ref.watch(houseProvider).valueOrNull  ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Student',
          style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/assignments'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('STUDENT'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _studentId,
            hint: const Text('Select student'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.school_outlined, size: 18)),
            items: students.map((s) => DropdownMenuItem(
              value: s.id, child: Text(s.fullName))).toList(),
            onChanged: (v) {
              final s = students.firstWhere((s) => s.id == v);
              setState(() { _studentId = v; _studentName = s.fullName; });
            },
          ),
          const SizedBox(height: 16),
          _label('HOUSE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _houseId,
            hint: const Text('Select house'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.house_outlined, size: 18)),
            items: houses.map((h) => DropdownMenuItem(
              value: h.id, child: Text(h.address,
                overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              final h = houses.firstWhere((h) => h.id == v);
              setState(() { _houseId = v; _houseAddress = h.address; });
            },
          ),
          const SizedBox(height: 16),
          _label('ROOM NUMBER (Optional)'),
          const SizedBox(height: 8),
          TextField(controller: _roomCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Room 3',
              prefixIcon: Icon(Icons.door_back_door_outlined, size: 18))),
          const SizedBox(height: 16),
          _label('START DATE'),
          const SizedBox(height: 8),
          TextField(
            controller: _startCtrl,
            readOnly: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                _startCtrl.text = picked.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Assignment'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: Color(0xFF64748B), letterSpacing: 0.8));
}