import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';

final assignmentServiceProvider = Provider((_) => AssignmentService());

class AssignmentNotifier extends AsyncNotifier<List<AssignmentModel>> {
  @override
  Future<List<AssignmentModel>> build() => ref.read(assignmentServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(assignmentServiceProvider).getAll());
  }

  Future<void> add(AssignmentModel a) async {
    await ref.read(assignmentServiceProvider).add(a);
    await refresh();
  }

  Future<void> end(AssignmentModel a) async {
    await ref.read(assignmentServiceProvider).end(a);
    await refresh();
  }
}

final assignmentProvider = AsyncNotifierProvider<AssignmentNotifier, List<AssignmentModel>>(AssignmentNotifier.new);