// providers/payment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/payment_service.dart';
import '../models/payment_model.dart';
import 'base_provider.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

class PaymentNotifier extends AsyncNotifier<List<PaymentModel>> with BaseAsyncNotifier<List<PaymentModel>> {
  late PaymentService _paymentService;

  @override
  Future<List<PaymentModel>> build() async {
    _paymentService = ref.read(paymentServiceProvider);
    return fetchData();
  }

  @override
  Future<List<PaymentModel>> fetchData() async {
    try {
      final payments = await _paymentService.getAll();
      developer.log('Fetched ${payments.length} payments', name: 'PAYMENT');
      return payments;
    } catch (e) {
      developer.log('Error fetching payments: $e', name: 'PAYMENT', error: e);
      return [];
    }
  }

  Future<bool> add(PaymentModel payment) async {
    return safeOperation(() async {
      await _paymentService.add(payment);
      return true; // Return something to satisfy the operation
    }, 'Add payment: ${payment.studentName} - \$${payment.amount}');
  }

  Future<bool> delete(PaymentModel payment) async {
    return safeOperation(() async {
      await _paymentService.delete(payment);
      return true; // Return something to satisfy the operation
    }, 'Delete payment: ${payment.studentName}');
  }

  // These methods don't need safeOperation - they're just calculations
  double getTotalRevenue() {
    final payments = state.valueOrNull ?? [];
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double getRevenueByMonth(int year, int month) {
    final payments = state.valueOrNull ?? [];
    return payments.where((p) {
      final parts = p.monthPaidFor.split(' ');
      if (parts.length != 2) return false;
      final paymentYear = int.tryParse(parts[1]);
      final paymentMonth = _getMonthNumber(parts[0]);
      return paymentYear == year && paymentMonth == month;
    }).fold(0.0, (sum, p) => sum + p.amount);
  }

  int _getMonthNumber(String monthName) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };
    return months[monthName] ?? 0;
  }

  List<PaymentModel> getPaymentsByStudent(String studentName) {
    final payments = state.valueOrNull ?? [];
    return payments.where((p) => 
      p.studentName.toLowerCase().contains(studentName.toLowerCase())
    ).toList();
  }
}

final paymentProvider = AsyncNotifierProvider<PaymentNotifier, List<PaymentModel>>(
  PaymentNotifier.new,
);