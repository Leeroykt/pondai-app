// providers/base_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

mixin BaseAsyncNotifier<T> on AsyncNotifier<T> {
  // This method must be implemented by the child class
  Future<T> fetchData();
  
  Future<void> refresh() async {
    developer.log('Refreshing ${T.toString()}', name: 'PROVIDER');
    state = const AsyncLoading();
    
    try {
      final data = await fetchData();
      state = AsyncData(data);
      developer.log('Refresh successful', name: 'PROVIDER');
    } catch (err, stack) {
      developer.log('Refresh failed: $err', name: 'PROVIDER', error: err, stackTrace: stack);
      
      // Preserve previous data if available
      final previousData = state.valueOrNull;
      if (previousData != null) {
        state = AsyncData(previousData);
      } else {
        state = AsyncError(err.toString(), stack);
      }
    }
  }

  Future<bool> safeOperation<R>(
    Future<R> Function() operation,
    String operationName,
  ) async {
    developer.log('Starting operation: $operationName', name: 'PROVIDER');
    
    try {
      await operation();
      await refresh();
      developer.log('Operation successful: $operationName', name: 'PROVIDER');
      return true;
    } catch (err, stack) {
      developer.log('Operation failed: $err', name: 'PROVIDER', error: err, stackTrace: stack);
      return false;
    }
  }
}