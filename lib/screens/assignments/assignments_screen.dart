import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/assignment_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_drawer.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Assignments',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.go('/assignments/add'),
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
                  icon: Icons.link_rounded, title: 'No assignments yet',
                  actionLabel: 'Assign Student',
                  onAction: () => context.go('/assignments/add'),
                ))
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final a = items[i];
                      final isDark   = Theme.of(context).brightness == Brightness.dark;
                      final isActive = a.status == 'active';
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
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.purple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.link_rounded,
                                color: AppColors.purple, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.studentName, style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(a.houseAddress, style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis),
                              ],
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.muted.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isActive ? 'Active' : 'Ended',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.success : AppColors.muted)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                              size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text('From ${a.startDate}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            if (a.roomNumber.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.door_back_door_rounded,
                                size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Text('Room ${a.roomNumber}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ]),
                          if (isActive) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _confirmEnd(context, ref, a),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.stop_circle_rounded,
                                      size: 13, color: AppColors.warning),
                                    SizedBox(width: 5),
                                    Text('End Assignment', style: TextStyle(
                                      fontSize: 12, color: AppColors.warning,
                                      fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                            ),
                          ],
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
        onPressed: () => context.go('/assignments/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _confirmEnd(BuildContext context, WidgetRef ref, dynamic a) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('End Assignment'),
      content: Text('End assignment for ${a.studentName}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            // Fixed: Use endAssignment instead of end
            final success = await ref.read(assignmentProvider.notifier).endAssignment(a);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Assignment ended successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('End', style: TextStyle(color: AppColors.warning)),
        ),
      ],
    ));
  }
}