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

class _AddHouseScreenState extends ConsumerState<AddHouseScreen> {
  final _addressCtrl = TextEditingController();
  final _roomsCtrl   = TextEditingController(text: '1');
  final _rentCtrl    = TextEditingController();
  String _status     = 'available';
  int?   _landlordId;
  bool   _loading    = false;
  HouseModel? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.houseId != null) _loadExisting();
  }

  void _loadExisting() {
    final id   = int.tryParse(widget.houseId!);
    final list = ref.read(houseProvider).valueOrNull ?? [];
    _existing  = list.firstWhere((h) => h.id == id, orElse: () => list.first);
    if (_existing != null) {
      _addressCtrl.text = _existing!.address;
      _roomsCtrl.text   = _existing!.totalRooms.toString();
      _rentCtrl.text    = _existing!.rentPerRoom.toString();
      _status           = _existing!.status;
      _landlordId       = _existing!.landlordId;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose(); _roomsCtrl.dispose(); _rentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_addressCtrl.text.isEmpty || _landlordId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Address and landlord are required'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final h = HouseModel(
        id: _existing?.id, localId: _existing?.localId,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_existing != null ? 'House updated' : 'House added'),
          backgroundColor: AppColors.success,
        ));
        context.go('/houses');
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
    final isEdit    = _existing != null;
    final landlords = ref.watch(landlordProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit House' : 'Add House',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/houses'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('LANDLORD'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _landlordId,
            hint: const Text('Select landlord'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, size: 18)),
            items: landlords.map((l) => DropdownMenuItem(
              value: l.id, child: Text(l.fullName))).toList(),
            onChanged: (v) => setState(() => _landlordId = v),
          ),
          const SizedBox(height: 16),
          _label('ADDRESS'),
          const SizedBox(height: 8),
          TextField(controller: _addressCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. 12 Borrowdale Road, Harare',
              prefixIcon: Icon(Icons.location_on_outlined, size: 18))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('TOTAL ROOMS'),
              const SizedBox(height: 8),
              TextField(controller: _roomsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.door_back_door_rounded, size: 18))),
            ])),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('RENT PER ROOM (\$)'),
              const SizedBox(height: 8),
              TextField(controller: _rentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money_rounded, size: 18))),
            ])),
          ]),
          const SizedBox(height: 16),
          _label('STATUS'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.info_outline, size: 18)),
            items: const [
              DropdownMenuItem(value: 'available', child: Text('Available')),
              DropdownMenuItem(value: 'full',      child: Text('Full')),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Update House' : 'Add House'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: Color(0xFF64748B), letterSpacing: 0.8,
  ));
}