import 'package:flutter/foundation.dart';

class AppConstants {
  // Fixed compile-time production string constant. This guarantees Dio reads the path correctly on devices!
  static const String baseUrl = 'https://pondai-api.onrender.com/api';
  
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // Sync queue actions
  static const String actionCreate = 'CREATE';
  static const String actionUpdate = 'UPDATE';
  static const String actionDelete = 'DELETE';

  // Tables
  static const String tableUsers = 'users';
  static const String tableLandlords = 'landlords';
  static const String tableHouses = 'houses';
  static const String tableStudents = 'students';
  static const String tableAssignments = 'assignments';
  static const String tablePayments = 'payments';
  static const String tableSyncQueue = 'sync_queue';
  
  // API Endpoints
  static const String endpointLogin = '/auth/login';
  static const String endpointProfile = '/auth/profile';
  static const String endpointChangePassword = '/auth/change-password';
  static const String endpointLandlords = '/landlords';
  static const String endpointHouses = '/houses';
  static const String endpointStudents = '/students';
  static const String endpointAssignments = '/assignments';
  static const String endpointPayments = '/payments';
}