import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/student_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_drawer.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Students',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.go('/students/add'),
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
                  icon: Icons.school_rounded, title: 'No students yet',
                  actionLabel: 'Add Student',
                  onAction: () => context.go('/students/add'),
                ))
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final s = items[i];
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
                              s.fullName.substring(0,1).toUpperCase(),
                              style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16),
                            )),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(s.fullName, style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                                if (!s.isSynced) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.cloud_off_rounded,
                                    size: 12, color: Color(0xFFF59E0B)),
                                ],
                              ]),
                              if (s.university.isNotEmpty)
                                Text(s.university, style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                              Text(s.phone, style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          )),
                          Row(children: [
                            GestureDetector(
                              onTap: () => context.go('/students/edit/${s.id}'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(7)),
                                child: const Icon(Icons.edit_rounded,
                                  size: 14, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _confirmDelete(context, ref, s),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(7)),
                                child: const Icon(Icons.delete_rounded,
                                  size: 14, color: AppColors.danger),
                              ),
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
        onPressed: () => context.go('/students/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Student'),
      content: Text('Remove ${s.fullName}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            ref.read(studentProvider.notifier).delete(s);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ));
  }
}