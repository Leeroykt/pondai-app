import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../core/database/local_db.dart';
import '../core/sync/sync_manager.dart';
import '../core/constants/app_constants.dart';
import '../models/landlord_model.dart';

class LandlordService {
  final _api  = ApiClient();
  final _db   = LocalDb();
  final _sync = SyncManager();
  final _uuid = const Uuid();

  Future<List<LandlordModel>> getAll() async {
    try {
      final res  = await _api.get('/landlords');
      final List list = res.data['data'];
      final items = list.map((j) => LandlordModel.fromJson(j)).toList();
      await _db.clearAndInsertAll(
        AppConstants.tableLandlords,
        items.map((l) => l.toLocal('server_${l.id}')).toList(),
      );
      return items;
    } catch (_) {
      return _getLocal();
    }
  }

  Future<List<LandlordModel>> _getLocal() async {
    final rows = await _db.getAll(AppConstants.tableLandlords);
    return rows.map((r) => LandlordModel.fromLocal(r)).toList();
  }

  Future<LandlordModel> add(LandlordModel landlord) async {
    final localId = _uuid.v4();
    final offline = LandlordModel(
      localId: localId, fullName: landlord.fullName,
      phone: landlord.phone, email: landlord.email,
      address: landlord.address, isSynced: false,
    );
    await _db.insert(AppConstants.tableLandlords, offline.toLocal(localId));

    try {
      final res = await _api.post('/landlords', landlord.toJson());
      final serverId = res.data['data']['id'];
      await _db.update(AppConstants.tableLandlords,
        {'server_id': serverId, 'is_synced': 1}, localId);
      return LandlordModel(
        id: serverId, localId: localId,
        fullName: landlord.fullName, phone: landlord.phone,
        email: landlord.email, address: landlord.address,
      );
    } catch (_) {
      await _db.addToSyncQueue(
        entity: 'landlords', action: AppConstants.actionCreate,
        localId: localId, payload: landlord.toJson(),
      );
      return offline;
    }
  }

  Future<void> update(LandlordModel landlord) async {
    if (landlord.localId != null) {
      await _db.update(AppConstants.tableLandlords,
        landlord.toLocal(landlord.localId!), landlord.localId!);
    }
    try {
      await _api.put('/landlords/${landlord.id}', landlord.toJson());
    } catch (_) {
      if (landlord.id != null && landlord.localId != null) {
        await _db.addToSyncQueue(
          entity: 'landlords', action: AppConstants.actionUpdate,
          localId: landlord.localId!, serverId: landlord.id,
          payload: landlord.toJson(),
        );
      }
    }
  }

  Future<void> delete(LandlordModel landlord) async {
    if (landlord.localId != null) {
      await _db.delete(AppConstants.tableLandlords, landlord.localId!);
    }
    try {
      await _api.delete('/landlords/${landlord.id}');
    } catch (_) {
      if (landlord.id != null && landlord.localId != null) {
        await _db.addToSyncQueue(
          entity: 'landlords', action: AppConstants.actionDelete,
          localId: landlord.localId!, serverId: landlord.id,
          payload: {},
        );
      }
    }
  }

  Future<void> sync() => _sync.syncAll();
}