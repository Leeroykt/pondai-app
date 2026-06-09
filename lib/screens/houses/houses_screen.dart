import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/house_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_drawer.dart';

class HousesScreen extends ConsumerWidget {
  const HousesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(houseProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Houses',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.go('/houses/add'),
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
                  icon: Icons.house_rounded, title: 'No houses yet',
                  actionLabel: 'Add House',
                  onAction: () => context.go('/houses/add'),
                ))
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final h = items[i];
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final isAvailable = h.status == 'available';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162032) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E3048) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.house_rounded,
                                color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(h.address,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                    overflow: TextOverflow.ellipsis)),
                                  if (!h.isSynced)
                                    const Icon(Icons.cloud_off_rounded,
                                      size: 12, color: Color(0xFFF59E0B)),
                                ]),
                                Text(h.landlord,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            )),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _chip(Icons.door_back_door_rounded,
                              '${h.totalRooms} rooms', AppColors.primary),
                            const SizedBox(width: 8),
                            _chip(Icons.attach_money_rounded,
                              '\$${h.rentPerRoom.toStringAsFixed(0)}/room', AppColors.success),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAvailable
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isAvailable ? 'Available' : 'Full',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isAvailable ? AppColors.success : AppColors.danger)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            _actionBtn('Edit', Icons.edit_rounded, AppColors.primary,
                              () => context.go('/houses/edit/${h.id}')),
                            const SizedBox(width: 8),
                            _actionBtn('Delete', Icons.delete_rounded, AppColors.danger,
                              () => _confirmDelete(context, ref, h)),
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
        onPressed: () => context.go('/houses/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic h) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete House'),
      content: Text('Remove "${h.address}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            ref.read(houseProvider.notifier).delete(h);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ));
  }
}