import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/landlord_provider.dart';
import '../../models/landlord_model.dart';

class AddLandlordScreen extends ConsumerStatefulWidget {
  final String? landlordId;
  const AddLandlordScreen({super.key, this.landlordId});

  @override
  ConsumerState<AddLandlordScreen> createState() => _AddLandlordScreenState();
}

class _AddLandlordScreenState extends ConsumerState<AddLandlordScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;
  LandlordModel? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.landlordId != null) _loadExisting();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_existing != null ? 'Landlord updated' : 'Landlord added'),
          backgroundColor: AppColors.success,
        ));
        context.go('/landlords');
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
        title: Text(isEdit ? 'Edit Landlord' : 'Add Landlord',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/landlords'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _field('FULL NAME', _nameCtrl, 'e.g. John Moyo', Icons.person_outline),
          const SizedBox(height: 16),
          _field('PHONE NUMBER', _phoneCtrl, 'e.g. 0771234567', Icons.phone_outlined,
            type: TextInputType.phone),
          const SizedBox(height: 16),
          _field('EMAIL ADDRESS', _emailCtrl, 'e.g. john@email.com', Icons.email_outlined,
            type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field('ADDRESS (Optional)', _addressCtrl, 'e.g. 123 Main St, Harare',
            Icons.location_on_outlined),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Update Landlord' : 'Add Landlord'),
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
        color: Color(0xFF64748B), letterSpacing: 0.8,
      )),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: type,
        decoration: InputDecoration(hintText: hint,
          prefixIcon: Icon(icon, size: 18))),
    ]);
  }
}