import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_drawer.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Payments',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.go('/payments/add'),
              ),
            ],
          ),
          state.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e'))),
            data: (items) => items.isEmpty
              ? SliverFillRemaining(child: EmptyState(
                  icon: Icons.payments_rounded, title: 'No payments yet',
                  actionLabel: 'Record Payment',
                  onAction: () => context.go('/payments/add'),
                ))
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = items[i];
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162032) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E3048) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.payments_rounded,
                              color: AppColors.success, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(p.studentName, style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                                if (!p.isSynced) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.cloud_off_rounded,
                                    size: 12, color: Color(0xFFF59E0B)),
                                ],
                              ]),
                              Text(p.monthPaidFor, style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                              Text(p.paymentDate, style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          )),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\$${p.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w800, color: AppColors.success)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(p.method, style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                            ),
                          ]),
                        ]),
                      );
                    },
                    childCount: items.length,
                  )),
                ),
          ),
        ])),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/payments/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}