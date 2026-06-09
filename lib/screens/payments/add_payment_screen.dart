import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../models/payment_model.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  int?   _assignmentId;
  String _studentName = '';
  final  _amountCtrl  = TextEditingController();
  final  _dateCtrl    = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10));
  final  _monthCtrl   = TextEditingController(
    text: '${_monthName(DateTime.now().month)} ${DateTime.now().year}');
  String _method      = 'cash';
  final  _notesCtrl   = TextEditingController();
  bool   _loading     = false;

  static String _monthName(int m) => const [
    '','January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m];

  @override
  void dispose() {
    _amountCtrl.dispose(); _dateCtrl.dispose();
    _monthCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_assignmentId == null || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Assignment and amount are required'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(paymentProvider.notifier).add(PaymentModel(
        assignmentId: _assignmentId,
        studentName:  _studentName,
        amount:       double.tryParse(_amountCtrl.text) ?? 0,
        paymentDate:  _dateCtrl.text,
        monthPaidFor: _monthCtrl.text,
        method:       _method,
        notes:        _notesCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment recorded'),
          backgroundColor: AppColors.success,
        ));
        context.go('/payments');
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
    final assignments = ref.watch(assignmentProvider).valueOrNull
      ?.where((a) => a.status == 'active').toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment',
          style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/payments'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('ASSIGNMENT'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _assignmentId,
            hint: const Text('Select active assignment'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.link_outlined, size: 18)),
            items: assignments.map((a) => DropdownMenuItem(
              value: a.id, child: Text(a.studentName,
                overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              final a = assignments.firstWhere((a) => a.id == v);
              setState(() { _assignmentId = v; _studentName = a.studentName; });
            },
          ),
          const SizedBox(height: 16),
          _label('AMOUNT (\$)'),
          const SizedBox(height: 8),
          TextField(controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 150',
              prefixIcon: Icon(Icons.attach_money_rounded, size: 18))),
          const SizedBox(height: 16),
          _label('MONTH PAID FOR'),
          const SizedBox(height: 8),
          TextField(controller: _monthCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. June 2025',
              prefixIcon: Icon(Icons.calendar_month_rounded, size: 18))),
          const SizedBox(height: 16),
          _label('PAYMENT DATE'),
          const SizedBox(height: 8),
          TextField(
            controller: _dateCtrl, readOnly: true,
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
                _dateCtrl.text = picked.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 16),
          _label('PAYMENT METHOD'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _method,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payment_rounded, size: 18)),
            items: const [
              DropdownMenuItem(value: 'cash',    child: Text('Cash')),
              DropdownMenuItem(value: 'ecocash', child: Text('EcoCash')),
              DropdownMenuItem(value: 'bank',    child: Text('Bank Transfer')),
            ],
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 16),
          _label('NOTES (Optional)'),
          const SizedBox(height: 8),
          TextField(controller: _notesCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Any additional notes...')),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Record Payment'),
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