import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/landlord_service.dart';
import '../models/landlord_model.dart';

final landlordServiceProvider = Provider((_) => LandlordService());

class LandlordNotifier extends AsyncNotifier<List<LandlordModel>> {
  @override
  Future<List<LandlordModel>> build() => ref.read(landlordServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(landlordServiceProvider).getAll());
  }

  Future<void> add(LandlordModel l) async {
    await ref.read(landlordServiceProvider).add(l);
    await refresh();
  }

  Future<void> updateLandlord(LandlordModel l) async {
    await ref.read(landlordServiceProvider).update(l);
    await refresh();
  }

  Future<void> delete(LandlordModel l) async {
    await ref.read(landlordServiceProvider).delete(l);
    await refresh();
  }
}

final landlordProvider = AsyncNotifierProvider<LandlordNotifier, List<LandlordModel>>(LandlordNotifier.new);