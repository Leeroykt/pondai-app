import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/student_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/app_drawer.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _fabCtrl;
  final _searchCtrl = TextEditingController();
  bool _searchExpanded = false;
  String _query = '';
  String _filterUni = '';

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _fabCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _fabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      drawer: const AppDrawer(),
      body: Stack(children: [
        Positioned(top: -60, left: -80,
          child: _GlowBlob(color: const Color(0xFF06B6D4).withOpacity(0.2), size: 240)),
        Positioned(bottom: 80, right: -60,
          child: _GlowBlob(color: const Color(0xFF7C3AED).withOpacity(0.15), size: 200)),

        Column(children: [
          const OfflineBanner(),
          Expanded(child: CustomScrollView(slivers: [
            _buildHeader(),
            _buildSearchAndFilter(state),
            state.when(
              loading: () => _buildShimmer(),
              error: (e, _) => SliverFillRemaining(child: _buildError(e.toString())),
              data: (items) {
                var filtered = items.where((s) {
                  final q = _query.toLowerCase();
                  final matchQ = q.isEmpty ||
                    s.fullName.toLowerCase().contains(q) ||
                    s.phone.contains(q);
                  final matchU = _filterUni.isEmpty ||
                    s.university.toLowerCase().contains(_filterUni.toLowerCase());
                  return matchQ && matchU;
                }).toList();

                return filtered.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _AnimatedCard(
                            index: i,
                            child: _StudentCard(
                              student: filtered[i],
                              onEdit: () => context.go('/students/edit/${filtered[i].id}'),
                              onDelete: () => _confirmDelete(context, ref, filtered[i]),
                              onTap: () => context.go('/students/${filtered[i].id}'),
                            ),
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
              colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: const Color(0xFF06B6D4).withOpacity(0.5),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go('/students/add'),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
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
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                ),
              )),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Students', style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)]).createShader(b),
                  child: const Text('manage your tenants',
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

  Widget _buildSearchAndFilter(AsyncValue items) {
  return SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _searchExpanded
                  ? const Color(0xFF06B6D4).withOpacity(0.6)
                  : const Color(0xFF1F2937),
                width: _searchExpanded ? 1.5 : 1),
              boxShadow: _searchExpanded ? [
                BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.12),
                  blurRadius: 16, offset: const Offset(0, 4)),
              ] : [],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (v) => setState(() => _query = v),
              onTap: () => setState(() => _searchExpanded = true),
              onSubmitted: (_) => setState(() => _searchExpanded = false),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.search_rounded,
                    color: _searchExpanded ? const Color(0xFF06B6D4) : const Color(0xFF4B5563),
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
        // University filter chips - FIXED VERSION
        items.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            final unis = data.map((s) => s.university as String)
              .where((u) => u.isNotEmpty).toSet().toList()..sort();
            if (unis.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  _FilterChip(
                    label: 'All', 
                    selected: _filterUni.isEmpty,
                    onTap: () => setState(() => _filterUni = ''),
                  ),
                  ...unis.map((u) => _FilterChip(
                    label: u, 
                    selected: _filterUni == u,
                    onTap: () => setState(() => _filterUni = _filterUni == u ? '' : u),
                  )),
                ],
              ),
            );
          },
        ),
      ],
    ),
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
        child: const Icon(Icons.error_outline_rounded,
          color: Color(0xFFEF4444), size: 36)),
      const SizedBox(height: 16),
      const Text('Something broke', style: TextStyle(
        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      Text(e, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _PulsingIcon(icon: Icons.school_outlined),
      const SizedBox(height: 20),
      const Text('No students yet', style: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Add your first student to get started',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      const SizedBox(height: 28),
      GestureDetector(
        onTap: () => context.go('/students/add'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('Add Student', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    ]));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteSheet(
        name: s.fullName,
        onConfirm: () {
          ref.read(studentProvider.notifier).delete(s);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Student Card ─────────────────────────────────────────────────────────────

class _StudentCard extends StatefulWidget {
  final dynamic student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _StudentCard({required this.student, required this.onEdit,
    required this.onDelete, required this.onTap});

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard>
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
    final s = widget.student;
    // Reliability color
    final reliability = (s.reliabilityScore ?? 100.0) as double;
    final relColor = reliability >= 80 ? const Color(0xFF10B981)
      : reliability >= 50 ? const Color(0xFFF59E0B)
      : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: widget.onTap,
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              Positioned(left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [relColor, relColor.withOpacity(0.4)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(children: [
                  Stack(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF06B6D4),
                            const Color(0xFF7C3AED)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(
                        s.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 18),
                      )),
                    ),
                    if (!s.isSynced)
                      Positioned(right: -2, top: -2,
                        child: Container(width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B), shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF111827), width: 2)),
                        ),
                      ),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fullName, style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      if (s.university.isNotEmpty)
                        Text(s.university, style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(s.phone, style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  )),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    // Reliability pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: relColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: relColor.withOpacity(0.3)),
                      ),
                      child: Text('${reliability.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: relColor)),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _ActionBtn(icon: Icons.edit_rounded,
                        color: const Color(0xFF06B6D4), onTap: widget.onEdit),
                      const SizedBox(width: 6),
                      _ActionBtn(icon: Icons.delete_rounded,
                        color: const Color(0xFFEF4444), onTap: widget.onDelete),
                    ]),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)]) : null,
          color: selected ? null : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFF1F2937)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }
}

// ─── Shared Helpers (duplicated from landlords for file independence) ──────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 150), lowerBound: 0.8, upperBound: 1.0)
      ..value = 1.0;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: widget.color.withOpacity(0.2)),
          ),
          child: Icon(widget.icon, size: 14, color: widget.color),
        ),
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
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child));
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
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.5 + _ctrl.value * 3, 0),
            colors: const [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF111827)],
          ),
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
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.8, spreadRadius: size * 0.2)]),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  const _PulsingIcon({required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            const Color(0xFF06B6D4).withOpacity(0.1 + _ctrl.value * 0.1),
            Colors.transparent]),
        ),
        child: Icon(widget.icon, color: const Color(0xFF06B6D4), size: 52),
      ),
    );
  }
}

class _DeleteSheet extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;
  const _DeleteSheet({required this.name, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFEF4444), size: 32)),
        const SizedBox(height: 16),
        const Text('Remove Student?', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text('$name will be permanently removed.\nThis cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('Cancel', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)))),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 8))]),
              child: const Center(child: Text('Remove', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)))),
          )),
        ]),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }
}