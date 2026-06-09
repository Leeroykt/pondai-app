import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../core/database/local_db.dart';
import '../core/sync/sync_manager.dart';
import '../core/constants/app_constants.dart';
import '../models/house_model.dart';

class HouseService {
  final _api  = ApiClient();
  final _db   = LocalDb();
  final _sync = SyncManager();
  final _uuid = const Uuid();

  Future<List<HouseModel>> getAll() async {
    try {
      final res   = await _api.get('/houses');
      final List list = res.data['data'];
      final items = list.map((j) => HouseModel.fromJson(j)).toList();
      await _db.clearAndInsertAll(
        AppConstants.tableHouses,
        items.map((h) => h.toLocal('server_${h.id}')).toList(),
      );
      return items;
    } catch (_) {
      return _getLocal();
    }
  }

  Future<List<HouseModel>> _getLocal() async {
    final rows = await _db.getAll(AppConstants.tableHouses);
    return rows.map((r) => HouseModel.fromLocal(r)).toList();
  }

  Future<HouseModel> add(HouseModel house) async {
    final localId = _uuid.v4();
    final offline = HouseModel(
      localId: localId, landlordId: house.landlordId,
      landlord: house.landlord, address: house.address,
      totalRooms: house.totalRooms, rentPerRoom: house.rentPerRoom,
      latitude: house.latitude, longitude: house.longitude,
      isSynced: false,
    );
    await _db.insert(AppConstants.tableHouses, offline.toLocal(localId));

    try {
      final res      = await _api.post('/houses', house.toJson());
      final serverId = res.data['data']['id'];
      await _db.update(AppConstants.tableHouses,
        {'server_id': serverId, 'is_synced': 1}, localId);
      return HouseModel(
        id: serverId, localId: localId,
        landlordId: house.landlordId, address: house.address,
        totalRooms: house.totalRooms, rentPerRoom: house.rentPerRoom,
      );
    } catch (_) {
      await _db.addToSyncQueue(
        entity: 'houses', action: AppConstants.actionCreate,
        localId: localId, payload: house.toJson(),
      );
      return offline;
    }
  }

  Future<void> update(HouseModel house) async {
    if (house.localId != null) {
      await _db.update(AppConstants.tableHouses,
        house.toLocal(house.localId!), house.localId!);
    }
    try {
      await _api.put('/houses/${house.id}', house.toJson());
    } catch (_) {
      if (house.id != null && house.localId != null) {
        await _db.addToSyncQueue(
          entity: 'houses', action: AppConstants.actionUpdate,
          localId: house.localId!, serverId: house.id,
          payload: house.toJson(),
        );
      }
    }
  }

  Future<void> delete(HouseModel house) async {
    if (house.localId != null) {
      await _db.delete(AppConstants.tableHouses, house.localId!);
    }
    try {
      await _api.delete('/houses/${house.id}');
    } catch (_) {
      if (house.id != null && house.localId != null) {
        await _db.addToSyncQueue(
          entity: 'houses', action: AppConstants.actionDelete,
          localId: house.localId!, serverId: house.id,
          payload: {},
        );
      }
    }
  }
}