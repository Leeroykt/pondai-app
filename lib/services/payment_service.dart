import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../core/database/local_db.dart';
import '../core/constants/app_constants.dart';
import '../models/payment_model.dart';

class PaymentService {
  final _api  = ApiClient();
  final _db   = LocalDb();
  final _uuid = const Uuid();

  Future<List<PaymentModel>> getAll() async {
    try {
      final res   = await _api.get('/payments');
      final List list = res.data['data'];
      final items = list.map((j) => PaymentModel.fromJson(j)).toList();
      await _db.clearAndInsertAll(
        AppConstants.tablePayments,
        items.map((p) => p.toLocal('server_${p.id}')).toList(),
      );
      return items;
    } catch (_) {
      return _getLocal();
    }
  }

  Future<List<PaymentModel>> _getLocal() async {
    final rows = await _db.getAll(AppConstants.tablePayments);
    return rows.map((r) => PaymentModel.fromLocal(r)).toList();
  }

  Future<PaymentModel> add(PaymentModel payment) async {
    final localId = _uuid.v4();
    final offline = PaymentModel(
      localId: localId, assignmentId: payment.assignmentId,
      studentName: payment.studentName, amount: payment.amount,
      paymentDate: payment.paymentDate, monthPaidFor: payment.monthPaidFor,
      method: payment.method, notes: payment.notes, isSynced: false,
    );
    await _db.insert(AppConstants.tablePayments, offline.toLocal(localId));

    try {
      final res      = await _api.post('/payments', payment.toJson());
      final serverId = res.data['data']['id'];
      await _db.update(AppConstants.tablePayments,
        {'server_id': serverId, 'is_synced': 1}, localId);
      return PaymentModel(
        id: serverId, localId: localId,
        assignmentId: payment.assignmentId, amount: payment.amount,
        paymentDate: payment.paymentDate, monthPaidFor: payment.monthPaidFor,
        method: payment.method,
      );
    } catch (_) {
      await _db.addToSyncQueue(
        entity: 'payments', action: AppConstants.actionCreate,
        localId: localId, payload: payment.toJson(),
      );
      return offline;
    }
  }

  Future<void> delete(PaymentModel payment) async {
    if (payment.localId != null) {
      await _db.delete(AppConstants.tablePayments, payment.localId!);
    }
    try {
      await _api.delete('/payments/${payment.id}');
    } catch (_) {
      if (payment.id != null && payment.localId != null) {
        await _db.addToSyncQueue(
          entity: 'payments', action: AppConstants.actionDelete,
          localId: payment.localId!, serverId: payment.id,
          payload: {},
        );
      }
    }
  }
}