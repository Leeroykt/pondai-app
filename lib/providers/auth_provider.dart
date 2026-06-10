// providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late AuthService _authService;

  @override
  Future<UserModel?> build() async {
    _authService = ref.read(authServiceProvider);
    return _authService.getSavedUser();
  }

  Future<void> login(String email, String password) async {
    developer.log('Login attempt for: $email', name: 'AUTH');
    state = const AsyncLoading();
    
    try {
      final user = await _authService.login(email, password);
      state = AsyncData(user);
      developer.log('Login successful for: ${user.email}', name: 'AUTH');
    } catch (err, stack) {
      developer.log('Login failed: $err', name: 'AUTH', error: err);
      state = AsyncError(err.toString(), stack);
    }
  }

  Future<void> logout() async {
    developer.log('Logging out user', name: 'AUTH');
    await _authService.logout();
    state = const AsyncData(null);
  }

  Future<bool> updateProfile(String fullName, String email) async {
    developer.log('Updating profile for: $email', name: 'AUTH');
    
    try {
      await _authService.updateProfile(fullName, email);
      
      // Refresh user data after update
      final updatedUser = await _authService.getSavedUser();
      state = AsyncData(updatedUser);
      
      developer.log('Profile updated successfully', name: 'AUTH');
      return true;
    } catch (err, stack) {
      developer.log('Profile update failed: $err', name: 'AUTH', error: err);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    developer.log('Changing password for user', name: 'AUTH');
    
    try {
      await _authService.changePassword(currentPassword, newPassword, confirmPassword);
      developer.log('Password changed successfully', name: 'AUTH');
      return true;
    } catch (err, stack) {
      developer.log('Password change failed: $err', name: 'AUTH', error: err);
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  Future<void> refreshUser() async {
    developer.log('Refreshing user data', name: 'AUTH');
    final user = await _authService.getSavedUser();
    state = AsyncData(user);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);