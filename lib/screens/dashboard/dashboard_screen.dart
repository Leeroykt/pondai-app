import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/landlord_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authProvider).valueOrNull;
    final landlords   = ref.watch(landlordProvider);
    final houses      = ref.watch(houseProvider);
    final students    = ref.watch(studentProvider);
    final assignments = ref.watch(assignmentProvider);
    final payments    = ref.watch(paymentProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    final houseList      = houses.valueOrNull      ?? [];
    final studentList    = students.valueOrNull    ?? [];
    final assignmentList = assignments.valueOrNull ?? [];
    final paymentList    = payments.valueOrNull    ?? [];
    final landlordList   = landlords.valueOrNull   ?? [];

    final totalRevenue    = paymentList.fold(0.0, (s, p) => s + p.amount);
    final activeAssignments = assignmentList.where((a) => a.status == 'active').length;
    final recentHouses    = houseList.take(5).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  floating: true,
                  title: const Text('Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.sync_rounded),
                      onPressed: () => ref.refresh(houseProvider),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildListDelegate([

                    // Greeting Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.bannerGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E3048)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$greeting, ${user?.fullName.split(' ').first ?? 'Agent'}!',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                                )),
                              const SizedBox(height: 4),
                              Text(
                                '${houseList.length} houses  ·  $activeAssignments active tenants',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stat Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        StatCard(
                          label: 'Houses', value: '${houseList.length}',
                          icon: Icons.house_rounded,
                          iconColor: AppColors.primary,
                          borderColor: AppColors.primary,
                          subtitle: 'All time',
                        ),
                        StatCard(
                          label: 'Active Tenants', value: '$activeAssignments',
                          icon: Icons.check_circle_rounded,
                          iconColor: AppColors.success,
                          borderColor: AppColors.success,
                          subtitle: 'Live now',
                        ),
                        StatCard(
                          label: 'Students', value: '${studentList.length}',
                          icon: Icons.school_rounded,
                          iconColor: AppColors.warning,
                          borderColor: AppColors.warning,
                          subtitle: 'Registered',
                        ),
                        StatCard(
                          label: 'Revenue', value: '\$${totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money_rounded,
                          iconColor: AppColors.purple,
                          borderColor: AppColors.purple,
                          subtitle: 'All time',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _sectionHeader('Quick Actions'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _quickAction(context, Icons.house_rounded,  'Add House',    '/houses/add',  AppColors.primary),
                      const SizedBox(width: 10),
                      _quickAction(context, Icons.school_rounded, 'Add Student',  '/students/add',AppColors.warning),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _quickAction(context, Icons.link_rounded,    'Assign',       '/assignments/add', AppColors.purple),
                      const SizedBox(width: 10),
                      _quickAction(context, Icons.payments_rounded,'Payment',      '/payments/add',    AppColors.success),
                    ]),
                    const SizedBox(height: 20),

                    // Recent Houses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionHeader('Recent Houses'),
                        TextButton(
                          onPressed: () => context.go('/houses'),
                          child: const Text('View all →',
                            style: TextStyle(color: AppColors.primary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (recentHouses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF162032) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E3048)),
                        ),
                        child: const Center(child: Text('No houses yet',
                          style: TextStyle(color: Color(0xFF64748B)))),
                      )
                    else
                      ...recentHouses.map((h) => _houseItem(context, h.address,
                        h.landlord, h.rentPerRoom, h.status)),
                    const SizedBox(height: 20),
                  ])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));

  Widget _quickAction(BuildContext context, IconData icon, String label,
      String route, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162032) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3048) : const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _houseItem(BuildContext context, String address, String landlord,
      double rent, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = status == 'available';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3048) : const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.house_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(address, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis),
          Text(landlord, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${rent.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700,
              color: AppColors.primary, fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isAvailable
                ? AppColors.success.withOpacity(0.12)
                : AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isAvailable ? 'Active' : 'Full',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: isAvailable ? AppColors.success : AppColors.danger)),
          ),
        ]),
      ]),
    );
  }
}