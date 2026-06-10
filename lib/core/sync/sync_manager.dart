import 'dart:convert';
import 'dart:developer' as developer;
import '../constants/app_constants.dart';
import '../database/local_db.dart';
import '../network/api_client.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final _db = LocalDb();
  final _api = ApiClient();
  bool _isSyncing = false;

  Future<void> syncAll() async {
    if (_isSyncing) {
      developer.log('Sync already in progress, skipping', name: 'SYNC_MANAGER');
      return;
    }
    
    _isSyncing = true;
    developer.log('Starting full sync', name: 'SYNC_MANAGER');
    
    try {
      // Push local changes first
      await _processSyncQueue();
      
      // Then pull latest from server
      await _pullFromServer();
      
      developer.log('Full sync completed successfully', name: 'SYNC_MANAGER');
    } catch (e) {
      developer.log('Sync failed: $e', name: 'SYNC_MANAGER', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  // Push all pending offline actions to server
  Future<void> _processSyncQueue() async {
    final pending = await _db.getPendingSyncItems();
    
    if (pending.isEmpty) {
      developer.log('No pending items to sync', name: 'SYNC_MANAGER');
      return;
    }
    
    developer.log('Processing ${pending.length} pending sync items', name: 'SYNC_MANAGER');
    
    for (final item in pending) {
      try {
        final payload = jsonDecode(item['payload']) as Map<String, dynamic>;
        final entity = item['entity'] as String;
        final action = item['action'] as String;
        final serverId = item['server_id'];
        final id = item['id'] as int;

        switch (action) {
          case AppConstants.actionCreate:
            final response = await _api.post('/$entity', payload);
            // Update local record with server ID
            if (response.data['data']?['id'] != null) {
              final newServerId = response.data['data']['id'];
              await _db.update(entity, {'server_id': newServerId, 'is_synced': 1}, item['local_id']);
            }
            break;
            
          case AppConstants.actionUpdate:
            await _api.put('/$entity/$serverId', payload);
            await _db.markAsSynced(entity, item['local_id']);
            break;
            
          case AppConstants.actionDelete:
            await _api.delete('/$entity/$serverId');
            // Already deleted locally, just remove from queue
            break;
        }
        
        await _db.removeSyncItem(id);
        developer.log('Synced $action for $entity', name: 'SYNC_MANAGER');
        
      } catch (e) {
        developer.log('Failed to sync item ${item['id']}: $e', name: 'SYNC_MANAGER', error: e);
        // Keep in queue, will retry next sync
        // Optionally update retry count
      }
    }
  }

  // Pull fresh data from server into local DB
  Future<void> _pullFromServer() async {
    developer.log('Pulling latest data from server', name: 'SYNC_MANAGER');
    
    await Future.wait([
      _pullEntity('landlords', AppConstants.tableLandlords, _mapLandlord),
      _pullEntity('houses', AppConstants.tableHouses, _mapHouse),
      _pullEntity('students', AppConstants.tableStudents, _mapStudent),
      _pullEntity('assignments', AppConstants.tableAssignments, _mapAssignment),
      _pullEntity('payments', AppConstants.tablePayments, _mapPayment),
    ]);
    
    developer.log('Pull from server completed', name: 'SYNC_MANAGER');
  }

  Future<void> _pullEntity(
    String endpoint, 
    String table,
    Map<String, dynamic> Function(Map<String, dynamic>) mapper
  ) async {
    try {
      final res = await _api.get('/$endpoint');
      final List list = res.data['data'];
      final rows = list.map((j) => mapper(j as Map<String, dynamic>)).toList();
      
      if (rows.isNotEmpty) {
        await _db.clearAndInsertAll(table, rows);
        developer.log('Pulled ${rows.length} $endpoint records', name: 'SYNC_MANAGER');
      }
    } catch (e) {
      developer.log('Failed to pull $endpoint: $e', name: 'SYNC_MANAGER', error: e);
    }
  }

  // Mappers for each entity type
  Map<String, dynamic> _mapLandlord(Map<String, dynamic> j) => {
    'local_id': 'server_${j['id']}',
    'server_id': j['id'],
    'full_name': j['full_name'],
    'phone': j['phone'],
    'email': j['email'],
    'address': j['address'] ?? '',
    'is_synced': 1,
  };

  Map<String, dynamic> _mapHouse(Map<String, dynamic> j) => {
    'local_id': 'server_${j['id']}',
    'server_id': j['id'],
    'landlord_id': j['landlord_id'],
    'landlord': j['landlord'] ?? '',
    'address': j['address'],
    'total_rooms': j['total_rooms'],
    'rent_per_room': j['rent_per_room'],
    'status': j['status'],
    'latitude': j['latitude'],
    'longitude': j['longitude'],
    'is_synced': 1,
  };

  Map<String, dynamic> _mapStudent(Map<String, dynamic> j) => {
    'local_id': 'server_${j['id']}',
    'server_id': j['id'],
    'full_name': j['full_name'],
    'phone': j['phone'],
    'email': j['email'],
    'university': j['university'] ?? '',
    'course': j['course'] ?? '',
    'national_id': j['national_id'] ?? '',
    'is_synced': 1,
  };

  Map<String, dynamic> _mapAssignment(Map<String, dynamic> j) => {
    'local_id': 'server_${j['id']}',
    'server_id': j['id'],
    'student_id': j['student_id'],
    'house_id': j['house_id'],
    'student_name': j['student']?['full_name'] ?? '',
    'house_address': j['house']?['address'] ?? '',
    'room_number': j['room_number'] ?? '',
    'start_date': j['start_date'],
    'end_date': j['end_date'],
    'status': j['status'],
    'is_synced': 1,
  };

  Map<String, dynamic> _mapPayment(Map<String, dynamic> j) => {
    'local_id': 'server_${j['id']}',
    'server_id': j['id'],
    'assignment_id': j['assignment_id'],
    'student_name': j['assignment']?['student']?['full_name'] ?? '',
    'amount': j['amount'],
    'payment_date': j['payment_date'],
    'month_paid_for': j['month_paid_for'],
    'method': j['method'],
    'notes': j['notes'] ?? '',
    'is_synced': 1,
  };

  // Single entity sync (useful after create/update)
  Future<void> syncEntity(String entity, String localId) async {
    developer.log('Syncing single entity: $entity', name: 'SYNC_MANAGER');
    // Implement if needed for real-time sync
  }
}