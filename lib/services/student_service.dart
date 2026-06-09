import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../core/database/local_db.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';

class StudentService {
  final _api  = ApiClient();
  final _db   = LocalDb();
  final _uuid = const Uuid();

  Future<List<StudentModel>> getAll() async {
    try {
      final res   = await _api.get('/students');
      final List list = res.data['data'];
      final items = list.map((j) => StudentModel.fromJson(j)).toList();
      await _db.clearAndInsertAll(
        AppConstants.tableStudents,
        items.map((s) => s.toLocal('server_${s.id}')).toList(),
      );
      return items;
    } catch (_) {
      return _getLocal();
    }
  }

  Future<List<StudentModel>> _getLocal() async {
    final rows = await _db.getAll(AppConstants.tableStudents);
    return rows.map((r) => StudentModel.fromLocal(r)).toList();
  }

  Future<StudentModel> add(StudentModel student) async {
    final localId = _uuid.v4();
    final offline = StudentModel(
      localId: localId, fullName: student.fullName,
      phone: student.phone, email: student.email,
      university: student.university, course: student.course,
      nationalId: student.nationalId, isSynced: false,
    );
    await _db.insert(AppConstants.tableStudents, offline.toLocal(localId));

    try {
      final res      = await _api.post('/students', student.toJson());
      final serverId = res.data['data']['id'];
      await _db.update(AppConstants.tableStudents,
        {'server_id': serverId, 'is_synced': 1}, localId);
      return StudentModel(
        id: serverId, localId: localId,
        fullName: student.fullName, phone: student.phone,
        email: student.email, university: student.university,
        course: student.course, nationalId: student.nationalId,
      );
    } catch (_) {
      await _db.addToSyncQueue(
        entity: 'students', action: AppConstants.actionCreate,
        localId: localId, payload: student.toJson(),
      );
      return offline;
    }
  }

  Future<void> update(StudentModel student) async {
    if (student.localId != null) {
      await _db.update(AppConstants.tableStudents,
        student.toLocal(student.localId!), student.localId!);
    }
    try {
      await _api.put('/students/${student.id}', student.toJson());
    } catch (_) {
      if (student.id != null && student.localId != null) {
        await _db.addToSyncQueue(
          entity: 'students', action: AppConstants.actionUpdate,
          localId: student.localId!, serverId: student.id,
          payload: student.toJson(),
        );
      }
    }
  }

  Future<void> delete(StudentModel student) async {
    if (student.localId != null) {
      await _db.delete(AppConstants.tableStudents, student.localId!);
    }
    try {
      await _api.delete('/students/${student.id}');
    } catch (_) {
      if (student.id != null && student.localId != null) {
        await _db.addToSyncQueue(
          entity: 'students', action: AppConstants.actionDelete,
          localId: student.localId!, serverId: student.id,
          payload: {},
        );
      }
    }
  }
}