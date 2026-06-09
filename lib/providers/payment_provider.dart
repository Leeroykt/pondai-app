import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import '../models/payment_model.dart';

final paymentServiceProvider = Provider((_) => PaymentService());

class PaymentNotifier extends AsyncNotifier<List<PaymentModel>> {
  @override
  Future<List<PaymentModel>> build() => ref.read(paymentServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(paymentServiceProvider).getAll());
  }

  Future<void> add(PaymentModel p) async {
    await ref.read(paymentServiceProvider).add(p);
    await refresh();
  }

  Future<void> delete(PaymentModel p) async {
    await ref.read(paymentServiceProvider).delete(p);
    await refresh();
  }
}

final paymentProvider = AsyncNotifierProvider<PaymentNotifier, List<PaymentModel>>(PaymentNotifier.new);