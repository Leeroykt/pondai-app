import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/app_drawer.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _fabCtrl;
  late AnimationController _statsCtrl;
  String _filterMethod = '';
  String _query = '';
  final _searchCtrl = TextEditingController();
  bool _searchExpanded = false;

  static const _methodColors = {
    'cash':    Color(0xFF10B981),
    'ecocash': Color(0xFFF59E0B),
    'bank':    Color(0xFF06B6D4),
  };

  static const _methodIcons = {
    'cash':    Icons.payments_rounded,
    'ecocash': Icons.phone_android_rounded,
    'bank':    Icons.account_balance_rounded,
  };

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fabCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _statsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _statsCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _fabCtrl.forward(); });
  }

  @override
  void dispose() {
    _headerCtrl.dispose(); _fabCtrl.dispose(); _statsCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _methodColor(String method) =>
    _methodColors[method.toLowerCase()] ?? const Color(0xFF7C3AED);
  IconData _methodIcon(String method) =>
    _methodIcons[method.toLowerCase()] ?? Icons.payment_rounded;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      drawer: const AppDrawer(),
      body: Stack(children: [
        Positioned(top: -60, right: -80,
          child: _GlowBlob(color: const Color(0xFF10B981).withOpacity(0.18), size: 260)),
        Positioned(bottom: 120, left: -60,
          child: _GlowBlob(color: const Color(0xFF7C3AED).withOpacity(0.14), size: 200)),

        Column(children: [
          const OfflineBanner(),
          Expanded(child: CustomScrollView(slivers: [
            _buildHeader(),
            // Stats strip
            state.maybeWhen(
              data: (items) => SliverToBoxAdapter(child: _buildStats(items)),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            _buildSearchAndFilter(state),
            state.when(
              loading: () => _buildShimmer(),
              error: (e, _) => SliverFillRemaining(child: _buildError(e.toString())),
              data: (items) {
                final filtered = items.where((p) {
                  final q = _query.toLowerCase();
                  final matchQ = q.isEmpty ||
                    p.studentName.toLowerCase().contains(q) ||
                    p.monthPaidFor.toLowerCase().contains(q);
                  final matchM = _filterMethod.isEmpty ||
                    p.method.toLowerCase() == _filterMethod;
                  return matchQ && matchM;
                }).toList();

                return filtered.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _AnimatedCard(
                            index: i,
                            child: _PaymentCard(payment: filtered[i],
                              methodColor: _methodColor(filtered[i].method),
                              methodIcon: _methodIcon(filtered[i].method)),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    );
              },
            ),
          ])),
        ]),
      ]),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.5),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Material(color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go('/payments/add'),
              child: const Padding(padding: EdgeInsets.all(16),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 26)),
            )),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
          .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _headerCtrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
            child: Row(children: [
              Builder(builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F2937))),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20)),
              )),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Payments', style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)]).createShader(b),
                  child: const Text('track every dollar',
                    style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w500)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(List items) {
    final total = items.fold<double>(0, (sum, p) => sum + (p.amount as double));
    final thisMonth = items.where((p) {
      final now = DateTime.now();
      return (p.monthPaidFor as String).contains('${now.year}') &&
        (p.monthPaidFor as String).contains(_monthName(now.month));
    }).fold<double>(0, (sum, p) => sum + (p.amount as double));

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _statsCtrl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(children: [
            Expanded(child: _StatCard(
              label: 'Total Collected',
              value: '\$${total.toStringAsFixed(0)}',
              icon: Icons.trending_up_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
              glowColor: const Color(0xFF10B981),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'This Month',
              value: '\$${thisMonth.toStringAsFixed(0)}',
              icon: Icons.calendar_month_rounded,
              gradient: const [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              glowColor: const Color(0xFF7C3AED),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Records',
              value: '${items.length}',
              icon: Icons.receipt_long_rounded,
              gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
              glowColor: const Color(0xFFF59E0B),
            )),
          ]),
        ),
      ),
    );
  }

  String _monthName(int m) => const [
    '', 'January','February','March','April','May','June',
    'July','August','September','October','November','December'][m];

  Widget _buildSearchAndFilter(AsyncValue state) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _searchExpanded
                  ? const Color(0xFF10B981).withOpacity(0.6)
                  : const Color(0xFF1F2937),
                width: _searchExpanded ? 1.5 : 1),
              boxShadow: _searchExpanded ? [BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.12),
                blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (v) => setState(() => _query = v),
              onTap: () => setState(() => _searchExpanded = true),
              onSubmitted: (_) => setState(() => _searchExpanded = false),
              decoration: InputDecoration(
                hintText: 'Search by student or month...',
                hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.search_rounded,
                    color: _searchExpanded ? const Color(0xFF10B981) : const Color(0xFF4B5563),
                    size: 20)),
                suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () => setState(() { _query = ''; _searchCtrl.clear(); }),
                      child: const Padding(padding: EdgeInsets.all(12),
                        child: Icon(Icons.close_rounded, color: Color(0xFF4B5563), size: 18)))
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        // Method filter chips
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: [
              _FilterChip(label: 'All', selected: _filterMethod.isEmpty,
                color: const Color(0xFF7C3AED),
                onTap: () => setState(() => _filterMethod = '')),
              _FilterChip(label: 'Cash', selected: _filterMethod == 'cash',
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _filterMethod = _filterMethod == 'cash' ? '' : 'cash')),
              _FilterChip(label: 'EcoCash', selected: _filterMethod == 'ecocash',
                color: const Color(0xFFF59E0B),
                onTap: () => setState(() => _filterMethod = _filterMethod == 'ecocash' ? '' : 'ecocash')),
              _FilterChip(label: 'Bank', selected: _filterMethod == 'bank',
                color: const Color(0xFF06B6D4),
                onTap: () => setState(() => _filterMethod = _filterMethod == 'bank' ? '' : 'bank')),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => const _ShimmerCard(), childCount: 5)),
    );
  }

  Widget _buildError(String e) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36)),
      const SizedBox(height: 16),
      const Text('Something broke', style: TextStyle(
        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      Text(e, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _PulsingIcon(icon: Icons.payments_outlined, color: const Color(0xFF10B981)),
      const SizedBox(height: 20),
      const Text('No payments yet', style: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Record your first payment to get started',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      const SizedBox(height: 28),
      GestureDetector(
        onTap: () => context.go('/payments/add'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
            borderRadius: BorderRadius.circular(14)),
          child: const Text('Record Payment', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    ]));
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatefulWidget {
  final dynamic payment;
  final Color methodColor;
  final IconData methodIcon;
  const _PaymentCard({required this.payment, required this.methodColor, required this.methodIcon});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 120), lowerBound: 0.96, upperBound: 1.0)
      ..value = 1.0;
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final c = widget.methodColor;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1F2937)),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              // Accent stripe — color-coded by method
              Positioned(left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c, c.withOpacity(0.3)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(children: [
                  // Method icon badge
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.withOpacity(0.25)),
                    ),
                    child: Stack(children: [
                      Center(child: Icon(widget.methodIcon, color: c, size: 22)),
                      if (!p.isSynced)
                        Positioned(right: -2, top: -2,
                          child: Container(width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B), shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF111827), width: 1.5)),
                          )),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.studentName, style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(p.monthPaidFor, style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                      Text(p.paymentDate, style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563))),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    // Amount
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [c, c.withOpacity(0.7)]).createShader(b),
                      child: Text('\$${p.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 6),
                    // Method pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.withOpacity(0.3)),
                      ),
                      child: Text(p.method.toLowerCase(),
                        style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: c)),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  const _StatCard({required this.label, required this.value, required this.icon,
    required this.gradient, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
        boxShadow: [BoxShadow(
          color: glowColor.withOpacity(0.12),
          blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (b) => LinearGradient(colors: gradient).createShader(b),
          child: Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontSize: 10, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFF1F2937)),
          boxShadow: selected ? [BoxShadow(
            color: color.withOpacity(0.3), blurRadius: 8)] : [],
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: widget.child),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12), height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.5 + _ctrl.value * 3, 0),
            colors: const [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF111827)]),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.8, spreadRadius: size * 0.2)]));
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            widget.color.withOpacity(0.1 + _ctrl.value * 0.1), Colors.transparent])),
        child: Icon(widget.icon, color: widget.color, size: 52),
      ),
    );
  }
}