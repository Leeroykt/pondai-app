// providers/house_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/house_service.dart';
import '../models/house_model.dart';
import 'base_provider.dart';

final houseServiceProvider = Provider((ref) => HouseService());

class HouseNotifier extends AsyncNotifier<List<HouseModel>> with BaseAsyncNotifier<List<HouseModel>> {
  late HouseService _houseService;

  @override
  Future<List<HouseModel>> build() async {
    _houseService = ref.read(houseServiceProvider);
    return fetchData();
  }

  @override
  Future<List<HouseModel>> fetchData() async {
    try {
      final houses = await _houseService.getAll();
      developer.log('Fetched ${houses.length} houses', name: 'HOUSE');
      return houses;
    } catch (e) {
      developer.log('Error fetching houses: $e', name: 'HOUSE', error: e);
      return [];
    }
  }

  Future<bool> add(HouseModel house) async {
    return safeOperation(() async {
      await _houseService.add(house);
      return true;
    }, 'Add house: ${house.address}');
  }

  Future<bool> updateHouse(HouseModel house) async {
    return safeOperation(() async {
      await _houseService.update(house);
      return true;
    }, 'Update house: ${house.address}');
  }

  Future<bool> delete(HouseModel house) async {
    return safeOperation(() async {
      await _houseService.delete(house);
      return true;
    }, 'Delete house: ${house.address}');
  }

  // Synchronous methods - no Future needed
  List<HouseModel> getHousesByLandlord(int landlordId) {
    final allHouses = state.valueOrNull ?? [];
    return allHouses.where((h) => h.landlordId == landlordId).toList();
  }

  HouseModel? getHouse(int id) {
    final allHouses = state.valueOrNull ?? [];
    try {
      return allHouses.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }
}

final houseProvider = AsyncNotifierProvider<HouseNotifier, List<HouseModel>>(
  HouseNotifier.new,
);