// providers/connectivity_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer' as developer;

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    developer.log('Connectivity changed: ${isOnline ? "Online" : "Offline"}', name: 'CONNECTIVITY');
    return isOnline;
  });
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
    data: (isOnline) => isOnline,
    orElse: () => true, // Assume online by default
  );
});

// Provider to check connectivity once
final connectivityCheckProvider = FutureProvider<bool>((ref) async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  return result.any((r) => r != ConnectivityResult.none);
});