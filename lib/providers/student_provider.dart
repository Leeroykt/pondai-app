// providers/student_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/student_service.dart';
import '../models/student_model.dart';
import 'base_provider.dart';

final studentServiceProvider = Provider((ref) => StudentService());

class StudentNotifier extends AsyncNotifier<List<StudentModel>> with BaseAsyncNotifier<List<StudentModel>> {
  late StudentService _studentService;

  @override
  Future<List<StudentModel>> build() async {
    _studentService = ref.read(studentServiceProvider);
    return fetchData();
  }

  @override
  Future<List<StudentModel>> fetchData() async {
    try {
      final students = await _studentService.getAll();
      developer.log('Fetched ${students.length} students', name: 'STUDENT');
      return students;
    } catch (e) {
      developer.log('Error fetching students: $e', name: 'STUDENT', error: e);
      return [];
    }
  }

  Future<bool> add(StudentModel student) async {
    return safeOperation(() async {
      await _studentService.add(student);
    }, 'Add student: ${student.fullName}');
  }

  Future<bool> updateStudent(StudentModel student) async {
    return safeOperation(() async {
      await _studentService.update(student);
    }, 'Update student: ${student.fullName}');
  }

  Future<bool> delete(StudentModel student) async {
    return safeOperation(() async {
      await _studentService.delete(student); // FIXED: Pass entire object, not just ID
    }, 'Delete student: ${student.fullName}');
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    final allStudents = state.valueOrNull ?? [];
    if (query.isEmpty) return allStudents;
    
    return allStudents.where((s) =>
      s.fullName.toLowerCase().contains(query.toLowerCase()) ||
      s.email.toLowerCase().contains(query.toLowerCase()) ||
      s.phone.contains(query)
    ).toList();
  }

  Future<StudentModel?> getStudent(int id) async {
    final allStudents = state.valueOrNull ?? [];
    try {
      return allStudents.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}

final studentProvider = AsyncNotifierProvider<StudentNotifier, List<StudentModel>>(
  StudentNotifier.new,
);