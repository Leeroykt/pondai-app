import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(authProvider).valueOrNull;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0D1526) : const Color(0xFF0F172A);
    final surface = isDark ? const Color(0xFF1C2A3A) : const Color(0xFF1E293B);

    return Drawer(
      backgroundColor: bg,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          decoration: BoxDecoration(
            color: surface,
            border: Border(bottom: BorderSide(color: const Color(0xFF1E3048))),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pondai Housing',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const Text('Management Platform',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ]),
          ]),
        ),

        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            _section('Main'),
            _tile(context, Icons.dashboard_rounded,    'Dashboard',   '/dashboard'),
            _section('Properties'),
            _tile(context, Icons.person_rounded,       'Landlords',   '/landlords'),
            _tile(context, Icons.house_rounded,        'Houses',      '/houses'),
            _section('Students'),
            _tile(context, Icons.school_rounded,       'Students',    '/students'),
            _tile(context, Icons.link_rounded,         'Assignments', '/assignments'),
            _section('Finance'),
            _tile(context, Icons.payments_rounded,     'Payments',    '/payments'),
            _section('Account'),
            _tile(context, Icons.settings_rounded,     'Settings',    '/settings'),
          ]),
        ),

        // User + Logout
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: const Color(0xFF1E3048))),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(
                    user?.fullName.substring(0,1).toUpperCase() ?? 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? 'Agent',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(user?.email ?? '',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF444415),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
                  SizedBox(width: 8),
                  Text('Sign Out', style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13,
                  )),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
    child: Text(label.toUpperCase(), style: const TextStyle(
      fontSize: 9.5, fontWeight: FontWeight.w700,
      color: Color(0xFF334155), letterSpacing: 1.2,
    )),
  );

  Widget _tile(BuildContext context, IconData icon, String label, String route) {
    final active = GoRouterState.of(context).matchedLocation == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: ListTile(
        leading: Icon(icon, size: 18,
          color: active ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
        title: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
        )),
        tileColor: active ? const Color(0xFF3B82F620) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        dense: true,
        onTap: () { Navigator.pop(context); context.go(route); },
      ),
    );
  }
}