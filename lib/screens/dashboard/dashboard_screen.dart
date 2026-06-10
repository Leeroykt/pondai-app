import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
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
    final userAsync = ref.watch(authProvider);
    final landlordsAsync = ref.watch(landlordProvider);
    final housesAsync = ref.watch(houseProvider);
    final studentsAsync = ref.watch(studentProvider);
    final assignmentsAsync = ref.watch(assignmentProvider);
    final paymentsAsync = ref.watch(paymentProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshAllData(ref),
              child: CustomScrollView(
                slivers: [
                  // AppBar
                  SliverAppBar(
                    floating: true,
                    title: const Text(
                      'Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.sync_rounded),
                        onPressed: () => _refreshAllData(ref),
                        tooltip: 'Refresh all data',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Handle loading states
                  if (housesAsync.isLoading || studentsAsync.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (housesAsync.hasError)
                    SliverFillRemaining(
                      child: _buildErrorWidget(context, ref, housesAsync.error), // Pass ref here
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Greeting Banner
                          _buildGreetingBanner(
                            context,
                            greeting,
                            userAsync.valueOrNull,
                            housesAsync.valueOrNull?.length ?? 0,
                            assignmentsAsync.valueOrNull
                                ?.where((a) => a.status == 'active')
                                .length ?? 0,
                          ),
                          const SizedBox(height: 20),

                          // Stat Cards
                          _buildStatCards(
                            context,
                            housesAsync.valueOrNull ?? [],
                            studentsAsync.valueOrNull ?? [],
                            assignmentsAsync.valueOrNull ?? [],
                            paymentsAsync.valueOrNull ?? [],
                          ),
                          const SizedBox(height: 20),

                          // Quick Actions
                          _sectionHeader('Quick Actions'),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 20),

                          // Recent Houses Section
                          _buildRecentHousesSection(
                            context,
                            housesAsync.valueOrNull ?? [],
                            ref,
                          ),
                          const SizedBox(height: 20),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAllData(WidgetRef ref) async {
    developer.log('Refreshing dashboard data', name: 'DASHBOARD');
    
    try {
      // Refresh all providers concurrently
      await Future.wait([
        ref.refresh(houseProvider.future),
        ref.refresh(studentProvider.future),
        ref.refresh(landlordProvider.future),
        ref.refresh(assignmentProvider.future),
        ref.refresh(paymentProvider.future),
      ]);
      
      developer.log('Dashboard data refreshed successfully', name: 'DASHBOARD');
    } catch (e) {
      developer.log('Error refreshing dashboard: $e', name: 'DASHBOARD', error: e);
      rethrow;
    }
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object? error) { // Add ref parameter
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _refreshAllData(ref), // Now ref is available
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner(
    BuildContext context,
    String greeting,
    user,
    int houseCount,
    int activeTenants,
  ) {
    final userName = user?.fullName.split(' ').first ?? 'Agent';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$houseCount ${houseCount == 1 ? 'house' : 'houses'}  ·  $activeTenants active ${activeTenants == 1 ? 'tenant' : 'tenants'}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    List houses,
    List students,
    List assignments,
    List payments,
  ) {
    final totalRevenue = payments.fold(0.0, (sum, p) => sum + p.amount);
    final activeAssignments = assignments.where((a) => a.status == 'active').length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        StatCard(
          key: const ValueKey('stat_houses'),
          label: 'Houses',
          value: '${houses.length}',
          icon: Icons.house_rounded,
          iconColor: AppColors.primary,
          borderColor: AppColors.primary,
          subtitle: 'All time',
        ),
        StatCard(
          key: const ValueKey('stat_tenants'),
          label: 'Active Tenants',
          value: '$activeAssignments',
          icon: Icons.people_rounded,
          iconColor: AppColors.success,
          borderColor: AppColors.success,
          subtitle: 'Currently housed',
        ),
        StatCard(
          key: const ValueKey('stat_students'),
          label: 'Students',
          value: '${students.length}',
          icon: Icons.school_rounded,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning,
          subtitle: 'In system',
        ),
        StatCard(
          key: const ValueKey('stat_revenue'),
          label: 'Revenue',
          value: '\$${totalRevenue.toStringAsFixed(0)}',
          icon: Icons.attach_money_rounded,
          iconColor: AppColors.purple,
          borderColor: AppColors.purple,
          subtitle: 'Total collected',
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('Add House', Icons.house_rounded, '/houses/add', AppColors.primary),
      ('Add Student', Icons.school_rounded, '/students/add', AppColors.warning),
      ('Assign Room', Icons.link_rounded, '/assignments/add', AppColors.purple),
      ('Record Payment', Icons.payments_rounded, '/payments/add', AppColors.success),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                actions[0].$2,
                actions[0].$1,
                actions[0].$3,
                actions[0].$4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                actions[1].$2,
                actions[1].$1,
                actions[1].$3,
                actions[1].$4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                actions[2].$2,
                actions[2].$1,
                actions[2].$3,
                actions[2].$4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                actions[3].$2,
                actions[3].$1,
                actions[3].$3,
                actions[3].$4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentHousesSection(
    BuildContext context,
    List houses,
    WidgetRef ref,
  ) {
    final recentHouses = houses.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('Recent Properties'),
            TextButton(
              onPressed: () => context.go('/houses'),
              child: const Text(
                'View all →',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentHouses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.house_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No properties yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/houses/add'),
                  child: const Text('Add your first property'),
                ),
              ],
            ),
          )
        else
          ...recentHouses.asMap().entries.map(
                (entry) => _buildHouseItem(
                  context,
                  entry.value,
                  key: ValueKey('house_${entry.value.id}_${entry.key}'),
                ),
              ),
      ],
    );
  }

  Widget _buildHouseItem(
    BuildContext context,
    house, {
    Key? key,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = house.status == 'available';
    
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/houses/${house.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.house_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.address,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      house.landlord,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${house.rentPerRoom.toStringAsFixed(0)}/room',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isAvailable ? AppColors.success : AppColors.danger)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Full',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}