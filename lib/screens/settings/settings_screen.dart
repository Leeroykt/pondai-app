import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/offline_banner.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _currCtrl    = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool  _loadingProfile  = false;
  bool  _loadingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text  = user.fullName;
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _currCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _loadingProfile = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
        _nameCtrl.text.trim(), _emailCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'), backgroundColor: AppColors.danger));
      return;
    }
    setState(() => _loadingPassword = true);
    try {
      await ref.read(authServiceProvider).changePassword(
        _currCtrl.text, _newCtrl.text, _confirmCtrl.text);
      _currCtrl.clear(); _newCtrl.clear(); _confirmCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _loadingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF162032) : Colors.white;
    final border = isDark ? const Color(0xFF1E3048) : const Color(0xFFE2E8F0);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: CustomScrollView(slivers: [
          const SliverAppBar(
            floating: true,
            title: Text('Settings',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Profile Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Profile Information', style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 20),
                  _label('FULL NAME'),
                  const SizedBox(height: 8),
                  TextField(controller: _nameCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, size: 18))),
                  const SizedBox(height: 16),
                  _label('EMAIL ADDRESS'),
                  const SizedBox(height: 8),
                  TextField(controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, size: 18))),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loadingProfile ? null : _saveProfile,
                      child: _loadingProfile
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Update Profile'),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Password Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.lock_rounded, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Text('Change Password', style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 20),
                  _label('CURRENT PASSWORD'),
                  const SizedBox(height: 8),
                  TextField(controller: _currCtrl, obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, size: 18))),
                  const SizedBox(height: 16),
                  _label('NEW PASSWORD'),
                  const SizedBox(height: 8),
                  TextField(controller: _newCtrl, obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, size: 18))),
                  const SizedBox(height: 16),
                  _label('CONFIRM NEW PASSWORD'),
                  const SizedBox(height: 8),
                  TextField(controller: _confirmCtrl, obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, size: 18))),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loadingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                      child: _loadingPassword
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Change Password'),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Sign Out
              Container(
                decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: const Text('Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
              const SizedBox(height: 30),
            ])),
          ),
        ])),
      ]),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: Color(0xFF64748B), letterSpacing: 0.8));
}