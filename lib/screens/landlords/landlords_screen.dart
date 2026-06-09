import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/landlord_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_drawer.dart';

class LandlordsScreen extends ConsumerWidget {
  const LandlordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(landlordProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Landlords',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.go('/landlords/add'),
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
                  icon: Icons.person_rounded, title: 'No landlords yet',
                  subtitle: 'Add your first landlord to get started',
                  actionLabel: 'Add Landlord',
                  onAction: () => context.go('/landlords/add'),
                ))
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final l = items[i];
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
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(
                              l.fullName.substring(0,1).toUpperCase(),
                              style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16),
                            )),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(l.fullName, style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                                if (!l.isSynced) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.cloud_off_rounded,
                                    size: 12, color: Color(0xFFF59E0B)),
                                ],
                              ]),
                              const SizedBox(height: 3),
                              Text(l.email, style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                              Text(l.phone, style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          )),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${l.houseCount} houses',
                                style: const TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              GestureDetector(
                                onTap: () => context.go('/landlords/edit/${l.id}'),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                    size: 14, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _confirmDelete(context, ref, l),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                    size: 14, color: AppColors.danger),
                                ),
                              ),
                            ]),
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
        onPressed: () => context.go('/landlords/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic l) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Landlord'),
      content: Text('Remove ${l.fullName}? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            ref.read(landlordProvider.notifier).delete(l);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ));
  }
}