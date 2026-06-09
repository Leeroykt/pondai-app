import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/sync/sync_manager.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online) {
      SyncManager().syncAll();
    }
    return online;
  });
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
    data: (v) => v,
    orElse: () => true,
  );
});