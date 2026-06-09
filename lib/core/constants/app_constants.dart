import 'package:flutter/foundation.dart'; // Required for kIsWeb

class AppConstants {
  // Use localhost for Web/Chrome, and 10.0.2.2 for Android emulators
  static const String baseUrl = kIsWeb 
      ? 'http://localhost:3000/api' 
      : 'http://10.0.2.2:3000/api';
      
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // Sync queue actions
  static const String actionCreate = 'CREATE';
  static const String actionUpdate = 'UPDATE';
  static const String actionDelete = 'DELETE';

  // Tables
  static const String tableUsers       = 'users';
  static const String tableLandlords   = 'landlords';
  static const String tableHouses      = 'houses';
  static const String tableStudents    = 'students';
  static const String tableAssignments = 'assignments';
  static const String tablePayments    = 'payments';
  static const String tableSyncQueue   = 'sync_queue';
}