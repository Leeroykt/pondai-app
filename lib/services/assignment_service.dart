import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../core/database/local_db.dart';
import '../core/constants/app_constants.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final _api  = ApiClient();
  final _db   = LocalDb();
  final _uuid = const Uuid();

  Future<List<AssignmentModel>> getAll() async {
    try {
      final res   = await _api.get('/assignments');
      final List list = res.data['data'];
      final items = list.map((j) => AssignmentModel.fromJson(j)).toList();
      await _db.clearAndInsertAll(
        AppConstants.tableAssignments,
        items.map((a) => a.toLocal('server_${a.id}')).toList(),
      );
      return items;
    } catch (_) {
      return _getLocal();
    }
  }

  Future<List<AssignmentModel>> _getLocal() async {
    final rows = await _db.getAll(AppConstants.tableAssignments);
    return rows.map((r) => AssignmentModel.fromLocal(r)).toList();
  }

  Future<AssignmentModel> add(AssignmentModel assignment) async {
    final localId = _uuid.v4();
    final offline = AssignmentModel(
      localId: localId, studentId: assignment.studentId,
      houseId: assignment.houseId, roomNumber: assignment.roomNumber,
      startDate: assignment.startDate, endDate: assignment.endDate,
      studentName: assignment.studentName,
      houseAddress: assignment.houseAddress,
      isSynced: false,
    );
    await _db.insert(AppConstants.tableAssignments, offline.toLocal(localId));

    try {
      final res      = await _api.post('/assignments', assignment.toJson());
      final serverId = res.data['data']['id'];
      await _db.update(AppConstants.tableAssignments,
        {'server_id': serverId, 'is_synced': 1}, localId);
      return AssignmentModel(
        id: serverId, localId: localId,
        studentId: assignment.studentId, houseId: assignment.houseId,
        startDate: assignment.startDate,
      );
    } catch (_) {
      await _db.addToSyncQueue(
        entity: 'assignments', action: AppConstants.actionCreate,
        localId: localId, payload: assignment.toJson(),
      );
      return offline;
    }
  }

  Future<void> end(AssignmentModel assignment) async {
    if (assignment.localId != null) {
      await _db.update(AppConstants.tableAssignments,
        {'status': 'ended'}, assignment.localId!);
    }
    try {
      await _api.put('/assignments/${assignment.id}/end', {});
    } catch (_) {
      if (assignment.id != null && assignment.localId != null) {
        await _db.addToSyncQueue(
          entity: 'assignments', action: AppConstants.actionUpdate,
          localId: assignment.localId!, serverId: assignment.id,
          payload: {'status': 'ended'},
        );
      }
    }
  }
}