import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  late AnimationController _auroraCtrl;
  final List<Animation<double>> _itemFades = [];
  final List<Animation<Offset>> _itemSlides = [];
  static const int _itemCount = 6;

  @override
  void initState() {
    super.initState();

    _staggerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _auroraCtrl = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    for (int i = 0; i < _itemCount; i++) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);

      _itemFades.add(
        Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerCtrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _itemSlides.add(
        Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _auroraCtrl.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    return FadeTransition(
      opacity: _itemFades[index.clamp(0, _itemCount - 1)],
      child: SlideTransition(
        position: _itemSlides[index.clamp(0, _itemCount - 1)],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final landlordsAsync = ref.watch(landlordProvider);
    final housesAsync = ref.watch(houseProvider);
    final studentsAsync = ref.watch(studentProvider);
    final assignmentsAsync = ref.watch(assignmentProvider);
    final paymentsAsync = ref.watch(paymentProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final greetingEmoji = hour < 12 ? '☀️' : hour < 17 ? '⚡' : '🌙';

    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Aurora background (subtle, top only)
          AnimatedBuilder(
            animation: _auroraCtrl,
            builder: (context, _) {
              return Positioned(
                top: -150 + math.sin(_auroraCtrl.value * 2 * math.pi) * 40,
                left: -100,
                child: Container(
                  width: 500,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF818CF8).withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _auroraCtrl,
            builder: (context, _) => Positioned(
              top: -80 + math.cos(_auroraCtrl.value * 2 * math.pi * 0.7) * 30,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF818CF8),
                  backgroundColor: const Color(0xFF0F172A),
                  onRefresh: () => _refreshAllData(ref),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── AppBar ─────────────────────────────────
                      SliverAppBar(
                        floating: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: Builder(
                          builder: (ctx) => IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 18),
                            ),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        title: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFF38BDF8)],
                          ).createShader(bounds),
                          child: const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        actions: [
                          _IconBtn(
                            icon: Icons.sync_rounded,
                            onTap: () => _refreshAllData(ref),
                            tooltip: 'Sync',
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),

                      if (housesAsync.isLoading || studentsAsync.isLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        )
                      else if (housesAsync.hasError)
                        SliverFillRemaining(
                          child: _buildErrorWidget(context, ref, housesAsync.error),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // ── Greeting banner ────────────────
                              _staggered(
                                0,
                                _buildGreetingBanner(
                                  context,
                                  greeting,
                                  greetingEmoji,
                                  userAsync.valueOrNull,
                                  housesAsync.valueOrNull?.length ?? 0,
                                  assignmentsAsync.valueOrNull
                                          ?.where((a) => a.status == 'active')
                                          .length ?? 0,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Stat cards ─────────────────────
                              _staggered(
                                1,
                                _buildStatCards(
                                  context,
                                  housesAsync.valueOrNull ?? [],
                                  studentsAsync.valueOrNull ?? [],
                                  assignmentsAsync.valueOrNull ?? [],
                                  paymentsAsync.valueOrNull ?? [],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Quick actions ──────────────────
                              _staggered(2, _sectionLabel('Quick Actions')),
                              const SizedBox(height: 12),
                              _staggered(3, _buildQuickActions(context)),
                              const SizedBox(height: 24),

                              // ── Recent houses ──────────────────
                              _staggered(
                                4,
                                _buildRecentHousesSection(
                                  context,
                                  housesAsync.valueOrNull ?? [],
                                  ref,
                                ),
                              ),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAllData(WidgetRef ref) async {
    developer.log('Refreshing dashboard data', name: 'DASHBOARD');
    try {
      await Future.wait([
        ref.refresh(houseProvider.future),
        ref.refresh(studentProvider.future),
        ref.refresh(landlordProvider.future),
        ref.refresh(assignmentProvider.future),
        ref.refresh(paymentProvider.future),
      ]);
      _staggerCtrl.forward(from: 0);
    } catch (e) {
      developer.log('Error refreshing: $e', name: 'DASHBOARD', error: e);
      rethrow;
    }
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load data',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown error',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _GlowButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onTap: () => _refreshAllData(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner(
    BuildContext context,
    String greeting,
    String emoji,
    user,
    int houseCount,
    int activeTenants,
  ) {
    final userName = user?.fullName.split(' ').first ?? 'Agent';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF818CF8).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '$greeting,',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFF94A3B8)],
                  ).createShader(bounds),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniPill(
                        label: '$houseCount ${houseCount == 1 ? 'house' : 'houses'}',
                        color: const Color(0xFF818CF8)),
                    const SizedBox(width: 8),
                    _MiniPill(
                        label: '$activeTenants active',
                        color: const Color(0xFF34D399)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF818CF8).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 26),
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

    final cards = [
      _StatData('Houses', '${houses.length}', Icons.house_rounded,
          const Color(0xFF818CF8), 'All time'),
      _StatData('Active Tenants', '$activeAssignments', Icons.people_rounded,
          const Color(0xFF34D399), 'Currently housed'),
      _StatData('Students', '${students.length}', Icons.school_rounded,
          const Color(0xFFFBBF24), 'In system'),
      _StatData('Revenue', '\$${totalRevenue.toStringAsFixed(0)}',
          Icons.attach_money_rounded, const Color(0xFFF472B6), 'Total collected'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: cards.asMap().entries.map((e) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + e.key * 100),
          curve: Curves.easeOutBack,
          builder: (_, val, child) => Transform.scale(scale: val, child: child),
          child: _EliteStatCard(data: e.value),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('Add House', Icons.house_rounded, '/houses/add', const Color(0xFF818CF8)),
      ('Add Student', Icons.school_rounded, '/students/add', const Color(0xFFFBBF24)),
      ('Assign Room', Icons.link_rounded, '/assignments/add', const Color(0xFFF472B6)),
      ('Record Payment', Icons.payments_rounded, '/payments/add', const Color(0xFF34D399)),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: _QuickActionCard(data: actions[0])),
          const SizedBox(width: 10),
          Expanded(child: _QuickActionCard(data: actions[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _QuickActionCard(data: actions[2])),
          const SizedBox(width: 10),
          Expanded(child: _QuickActionCard(data: actions[3])),
        ]),
      ],
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
            _sectionLabel('Recent Properties'),
            GestureDetector(
              onTap: () => context.go('/houses'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
                ),
                child: const Text(
                  'View all →',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (recentHouses.isEmpty)
          _buildEmptyHouses(context)
        else
          ...recentHouses.asMap().entries.map(
                (entry) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + entry.key * 80),
                  curve: Curves.easeOut,
                  builder: (_, val, child) =>
                      Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                  child: _HouseCard(house: entry.value),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyHouses(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.house_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('No properties yet',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _GlowButton(
            label: 'Add first property',
            icon: Icons.add_rounded,
            onTap: () => context.go('/houses/add'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _StatData(this.label, this.value, this.icon, this.color, this.subtitle);
}

class _EliteStatCard extends StatefulWidget {
  final _StatData data;
  const _EliteStatCard({required this.data});

  @override
  State<_EliteStatCard> createState() => _EliteStatCardState();
}

class _EliteStatCardState extends State<_EliteStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: d.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: d.color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: d.color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: d.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(d.icon, color: d.color, size: 18),
              ),
              const Spacer(),
              Text(
                d.value,
                style: TextStyle(
                  color: d.color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                d.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                d.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final (String, IconData, String, Color) data;
  const _QuickActionCard({required this.data});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (label, icon, route, color) = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.go(route);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.25), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseCard extends StatefulWidget {
  final house;
  const _HouseCard({required this.house});

  @override
  State<_HouseCard> createState() => _HouseCardState();
}

class _HouseCardState extends State<_HouseCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final house = widget.house;
    final isAvailable = house.status == 'available';
    final statusColor = isAvailable ? const Color(0xFF34D399) : const Color(0xFFEF4444);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.go('/houses/${house.id}');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.2)),
                ),
                child: const Icon(Icons.house_rounded, color: Color(0xFF818CF8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      house.landlord ?? 'Unknown landlord',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
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
                    '\$${house.rentPerRoom.toStringAsFixed(0)}/rm',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      isAvailable ? 'Open' : 'Full',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.3,
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
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlowButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF818CF8).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}