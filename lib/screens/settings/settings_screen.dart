import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
// Remove this line - it doesn't exist: import '../../providers/user_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/offline_banner.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  bool _loadingProfile = false;
  bool _loadingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _newCtrl.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loadingProfile = true);
    
    try {
      final userNotifier = ref.read(authProvider.notifier);
      final success = await userNotifier.updateProfile(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
      );
      
      if (success && mounted) {
        _showSuccessSnackbar('Profile updated successfully');
        developer.log('Profile updated for ${_emailCtrl.text}', name: 'SETTINGS');
      } else if (mounted) {
        _showErrorSnackbar('Failed to update profile');
      }
    } catch (e) {
      developer.log('Profile update error: $e', name: 'SETTINGS', error: e);
      if (mounted) _showErrorSnackbar('Error: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    
    setState(() => _loadingPassword = true);
    
    try {
      final userNotifier = ref.read(authProvider.notifier);
      // Fixed: Pass all 3 required parameters
      final success = await userNotifier.changePassword(
        _currCtrl.text,
        _newCtrl.text,
        _confirmCtrl.text,  // Added missing confirm password parameter
      );
      
      if (success && mounted) {
        _currCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        _showSuccessSnackbar('Password changed successfully');
        developer.log('Password changed for user', name: 'SETTINGS');
      } else if (mounted) {
        _showErrorSnackbar('Current password is incorrect');
      }
    } catch (e) {
      developer.log('Password change error: $e', name: 'SETTINGS', error: e);
      if (mounted) _showErrorSnackbar('Error: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _loadingPassword = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  floating: true,
                  title: Text(
                    'Settings',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Profile Section
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: borderColor),
                        ),
                        color: cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Profile Information',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('FULL NAME'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameCtrl,
                                  validator: _validateName,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your full name',
                                    prefixIcon: Icon(Icons.person_outline, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel('EMAIL ADDRESS'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your email',
                                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _loadingProfile ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _loadingProfile
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Update Profile'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Section
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: borderColor),
                        ),
                        color: cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _passwordFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lock_rounded, color: AppColors.warning, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Change Password',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('CURRENT PASSWORD'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _currCtrl,
                                  obscureText: _obscureCurrent,
                                  validator: _validateCurrentPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter current password',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel('NEW PASSWORD'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _newCtrl,
                                  obscureText: _obscureNew,
                                  validator: _validateNewPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter new password (min 6 characters)',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel('CONFIRM NEW PASSWORD'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscureConfirm,
                                  validator: _validateConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm new password',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _loadingPassword ? null : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warning,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _loadingPassword
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Change Password'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign Out
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: borderColor),
                        ),
                        color: cardColor,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                          ),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                              fontSize: 15,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _confirmSignOut(),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}