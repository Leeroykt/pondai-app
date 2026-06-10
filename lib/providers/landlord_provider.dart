// providers/landlord_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/landlord_service.dart';
import '../models/landlord_model.dart';
import 'base_provider.dart';

final landlordServiceProvider = Provider((ref) => LandlordService());

class LandlordNotifier extends AsyncNotifier<List<LandlordModel>> with BaseAsyncNotifier<List<LandlordModel>> {
  late LandlordService _landlordService;

  @override
  Future<List<LandlordModel>> build() async {
    _landlordService = ref.read(landlordServiceProvider);
    return fetchData();
  }

  @override
  Future<List<LandlordModel>> fetchData() async {
    try {
      final landlords = await _landlordService.getAll();
      developer.log('Fetched ${landlords.length} landlords', name: 'LANDLORD');
      return landlords;
    } catch (e) {
      developer.log('Error fetching landlords: $e', name: 'LANDLORD', error: e);
      return [];
    }
  }

  Future<bool> add(LandlordModel landlord) async {
    return safeOperation(() async {
      await _landlordService.add(landlord);
    }, 'Add landlord: ${landlord.fullName}');
  }

  Future<bool> updateLandlord(LandlordModel landlord) async {
    return safeOperation(() async {
      await _landlordService.update(landlord);
    }, 'Update landlord: ${landlord.fullName}');
  }

  Future<bool> delete(LandlordModel landlord) async {
    return safeOperation(() async {
      await _landlordService.delete(landlord); // Pass entire object
    }, 'Delete landlord: ${landlord.fullName}');
  }

  Future<LandlordModel?> getLandlord(int id) async {
    final allLandlords = state.valueOrNull ?? [];
    try {
      return allLandlords.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}

final landlordProvider = AsyncNotifierProvider<LandlordNotifier, List<LandlordModel>>(
  LandlordNotifier.new,
);