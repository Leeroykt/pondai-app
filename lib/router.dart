import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/landlords/landlords_screen.dart';
import 'screens/landlords/add_landlord_screen.dart';
import 'screens/houses/houses_screen.dart';
import 'screens/houses/add_house_screen.dart';
import 'screens/students/students_screen.dart';
import 'screens/students/add_student_screen.dart';
import 'screens/assignments/assignments_screen.dart';
import 'screens/assignments/add_assignment_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/payments/add_payment_screen.dart';
import 'screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final loggedIn = auth.valueOrNull != null;
      final onLogin  = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn  &&  onLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/dashboard',   builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/landlords',   builder: (_, __) => const LandlordsScreen()),
      GoRoute(path: '/landlords/add', builder: (_, __) => const AddLandlordScreen()),
      GoRoute(path: '/landlords/edit/:id', builder: (_, state) =>
        AddLandlordScreen(landlordId: state.pathParameters['id'])),
      GoRoute(path: '/houses',      builder: (_, __) => const HousesScreen()),
      GoRoute(path: '/houses/add',  builder: (_, __) => const AddHouseScreen()),
      GoRoute(path: '/houses/edit/:id', builder: (_, state) =>
        AddHouseScreen(houseId: state.pathParameters['id'])),
      GoRoute(path: '/students',    builder: (_, __) => const StudentsScreen()),
      GoRoute(path: '/students/add',builder: (_, __) => const AddStudentScreen()),
      GoRoute(path: '/students/edit/:id', builder: (_, state) =>
        AddStudentScreen(studentId: state.pathParameters['id'])),
      GoRoute(path: '/assignments', builder: (_, __) => const AssignmentsScreen()),
      GoRoute(path: '/assignments/add', builder: (_, __) => const AddAssignmentScreen()),
      GoRoute(path: '/payments',    builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: '/payments/add',builder: (_, __) => const AddPaymentScreen()),
      GoRoute(path: '/settings',    builder: (_, __) => const SettingsScreen()),
    ],
  );
});