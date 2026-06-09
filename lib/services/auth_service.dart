import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../core/network/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _api     = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String password) async {
    final res = await _api.post('/auth/login', {
      'email': email, 'password': password
    });
    final token = res.data['data']['token'];
    final user  = UserModel.fromJson(res.data['data']['user']);
    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.userKey,  value: jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<UserModel?> getSavedUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  Future<void> updateProfile(String fullName, String email) async {
    await _api.put('/auth/profile', {'full_name': fullName, 'email': email});
    final user = await getSavedUser();
    if (user != null) {
      final updated = UserModel(id: user.id, fullName: fullName, email: email);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(updated.toJson()));
    }
  }

  Future<void> changePassword(String current, String newPass, String confirm) async {
    await _api.post('/auth/change-password', {
      'current_password':  current,
      'new_password':      newPass,
      'confirm_password':  confirm,
    });
  }
}