import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_service.dart';
import '../models/student_model.dart';

final studentServiceProvider = Provider((_) => StudentService());

class StudentNotifier extends AsyncNotifier<List<StudentModel>> {
  @override
  Future<List<StudentModel>> build() => ref.read(studentServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(studentServiceProvider).getAll());
  }

  Future<void> add(StudentModel s) async {
    await ref.read(studentServiceProvider).add(s);
    await refresh();
  }

  Future<void> updateStudent(StudentModel s) async {
    await ref.read(studentServiceProvider).update(s);
    await refresh();
  }

  Future<void> delete(StudentModel s) async {
    await ref.read(studentServiceProvider).delete(s);
    await refresh();
  }
}

final studentProvider = AsyncNotifierProvider<StudentNotifier, List<StudentModel>>(StudentNotifier.new);