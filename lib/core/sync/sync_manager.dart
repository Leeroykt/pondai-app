import 'dart:convert';
import '../constants/app_constants.dart';
import '../database/local_db.dart';
import '../network/api_client.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final _db  = LocalDb();
  final _api = ApiClient();

  Future<void> syncAll() async {
    await _processSyncQueue();
    await _pullFromServer();
  }

  // Push all pending offline actions to server
  Future<void> _processSyncQueue() async {
    final pending = await _db.getPendingSyncItems();
    for (final item in pending) {
      try {
        final payload  = jsonDecode(item['payload']) as Map<String, dynamic>;
        final entity   = item['entity'] as String;
        final action   = item['action'] as String;
        final serverId = item['server_id'];
        final id       = item['id'] as int;

        switch (action) {
          case AppConstants.actionCreate:
            await _api.post('/$entity', payload);
            break;
          case AppConstants.actionUpdate:
            await _api.put('/$entity/$serverId', payload);
            break;
          case AppConstants.actionDelete:
            await _api.delete('/$entity/$serverId');
            break;
        }
        await _db.removeSyncItem(id);
      } catch (_) {
        // Keep in queue, will retry next sync
      }
    }
  }

  // Pull fresh data from server into local DB
  Future<void> _pullFromServer() async {
    await _pullEntity('landlords', AppConstants.tableLandlords, (j) {
      return {
        'local_id':   'server_${j['id']}',
        'server_id': j['id'],
        'full_name': j['full_name'],
        'phone':     j['phone'],
        'email':     j['email'],
        'address':   j['address'] ?? '',
        'is_synced': 1,
      };
    });

    await _pullEntity('houses', AppConstants.tableHouses, (j) {
      return {
        'local_id':     'server_${j['id']}',
        'server_id':    j['id'],
        'landlord_id':  j['landlord_id'],
        'landlord':     j['landlord'] ?? '',
        'address':      j['address'],
        'total_rooms':  j['total_rooms'],
        'rent_per_room':j['rent_per_room'],
        'status':       j['status'],
        'latitude':     j['latitude'],
        'longitude':    j['longitude'],
        'is_synced':    1,
      };
    });

    await _pullEntity('students', AppConstants.tableStudents, (j) {
      return {
        'local_id':    'server_${j['id']}',
        'server_id':   j['id'],
        'full_name':   j['full_name'],
        'phone':       j['phone'],
        'email':       j['email'],
        'university':  j['university'] ?? '',
        'course':      j['course'] ?? '',
        'national_id': j['national_id'] ?? '',
        'is_synced':   1,
      };
    });

    await _pullEntity('assignments', AppConstants.tableAssignments, (j) {
      return {
        'local_id':     'server_${j['id']}',
        'server_id':    j['id'],
        'student_id':   j['student_id'],
        'house_id':     j['house_id'],
        'student_name': j['student']?['full_name'] ?? '',
        'house_address':j['house']?['address'] ?? '',
        'room_number':  j['room_number'] ?? '',
        'start_date':   j['start_date'],
        'end_date':     j['end_date'],
        'status':       j['status'],
        'is_synced':    1,
      };
    });

    await _pullEntity('payments', AppConstants.tablePayments, (j) {
      return {
        'local_id':      'server_${j['id']}',
        'server_id':     j['id'],
        'assignment_id': j['assignment_id'],
        'student_name':  j['assignment']?['student']?['full_name'] ?? '',
        'amount':        j['amount'],
        'payment_date':  j['payment_date'],
        'month_paid_for':j['month_paid_for'],
        'method':        j['method'],
        'notes':         j['notes'] ?? '',
        'is_synced':     1,
      };
    });
  }

  Future<void> _pullEntity(
    String endpoint, String table,
    Map<String, dynamic> Function(Map<String, dynamic>) mapper
  ) async {
    try {
      final res  = await _api.get('/$endpoint');
      final List list = res.data['data'];
      final rows = list.map((j) => mapper(j as Map<String, dynamic>)).toList();
      await _db.clearAndInsertAll(table, rows);
    } catch (_) {}
  }
}