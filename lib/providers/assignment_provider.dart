// providers/assignment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';
import 'base_provider.dart';

final assignmentServiceProvider = Provider((ref) => AssignmentService());

class AssignmentNotifier extends AsyncNotifier<List<AssignmentModel>> with BaseAsyncNotifier<List<AssignmentModel>> {
  late AssignmentService _assignmentService;

  @override
  Future<List<AssignmentModel>> build() async {
    _assignmentService = ref.read(assignmentServiceProvider);
    return fetchData();
  }

  @override
  Future<List<AssignmentModel>> fetchData() async {
    try {
      final assignments = await _assignmentService.getAll();
      developer.log('Fetched ${assignments.length} assignments', name: 'ASSIGNMENT');
      return assignments;
    } catch (e) {
      developer.log('Error fetching assignments: $e', name: 'ASSIGNMENT', error: e);
      return [];
    }
  }

  Future<bool> add(AssignmentModel assignment) async {
    return safeOperation(() async {
      await _assignmentService.add(assignment);
    }, 'Add assignment for: ${assignment.studentName}');
  }

  Future<bool> endAssignment(AssignmentModel assignment) async {
    return safeOperation(() async {
      await _assignmentService.end(assignment);
    }, 'End assignment for: ${assignment.studentName}');
  }

  Future<List<AssignmentModel>> getActiveAssignments() async {
    final allAssignments = state.valueOrNull ?? [];
    return allAssignments.where((a) => a.status == 'active').toList();
  }

  Future<List<AssignmentModel>> getAssignmentsByHouse(int houseId) async {
    final allAssignments = state.valueOrNull ?? [];
    return allAssignments.where((a) => a.houseId == houseId).toList();
  }

  Future<List<AssignmentModel>> getAssignmentsByStudent(int studentId) async {
    final allAssignments = state.valueOrNull ?? [];
    return allAssignments.where((a) => a.studentId == studentId).toList();
  }

  Future<AssignmentModel?> getAssignment(int id) async {
    final allAssignments = state.valueOrNull ?? [];
    try {
      return allAssignments.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}

final assignmentProvider = AsyncNotifierProvider<AssignmentNotifier, List<AssignmentModel>>(
  AssignmentNotifier.new,
);