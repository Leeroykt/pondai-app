import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/house_service.dart';
import '../models/house_model.dart';

final houseServiceProvider = Provider((_) => HouseService());

class HouseNotifier extends AsyncNotifier<List<HouseModel>> {
  @override
  Future<List<HouseModel>> build() => ref.read(houseServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(houseServiceProvider).getAll());
  }

  Future<void> add(HouseModel h) async {
    await ref.read(houseServiceProvider).add(h);
    await refresh();
  }

  Future<void> updateHouse(HouseModel h) async {
    await ref.read(houseServiceProvider).update(h);
    await refresh();
  }

  Future<void> delete(HouseModel h) async {
    await ref.read(houseServiceProvider).delete(h);
    await refresh();
  }
}

final houseProvider = AsyncNotifierProvider<HouseNotifier, List<HouseModel>>(HouseNotifier.new);