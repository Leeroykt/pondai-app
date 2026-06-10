import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'core/sync/sync_manager.dart';
import 'router.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database based on platform
  await _initializeDatabase();
  
  // Initialize API client
  ApiClient().init();
  
  // Initialize sync manager
  await _initializeSync();
  
  // Log app start
  developer.log('App starting...', name: 'MAIN');
  
  // Run the app with error handling
  runApp(
    ProviderScope(
      observers: [RiverpodObserver()],
      child: const PondaiApp(),
    ),
  );
}

Future<void> _initializeDatabase() async {
  try {
    if (kIsWeb) {
      // Web platform
      databaseFactory = databaseFactoryFfiWeb;
      developer.log('✅ Web database factory initialized', name: 'MAIN');
    } else {
      // Mobile platforms (Android, iOS, Windows, macOS, Linux)
      databaseFactory = databaseFactoryFfi;
      developer.log('✅ Mobile database factory initialized', name: 'MAIN');
    }
  } catch (e, stack) {
    developer.log('❌ Database initialization failed: $e', 
      name: 'MAIN', error: e, stackTrace: stack);
    // Don't rethrow - app can still work with API only
  }
}

Future<void> _initializeSync() async {
  try {
    // Initial sync when app starts
    await SyncManager().syncAll();
    developer.log('✅ Initial sync completed', name: 'MAIN');
  } catch (e) {
    developer.log('⚠️ Initial sync failed (will retry later): $e', 
      name: 'MAIN', error: e);
  }
}

// Riverpod observer for debugging
class RiverpodObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      developer.log('Provider updated: $provider', 
        name: 'RIVERPOD', 
        error: newValue?.toString());
    }
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }
  
  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    if (kDebugMode) {
      developer.log('Provider added: $provider', name: 'RIVERPOD');
    }
    super.didAddProvider(provider, value, container);
  }
  
  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    if (kDebugMode) {
      developer.log('Provider disposed: $provider', name: 'RIVERPOD');
    }
    super.didDisposeProvider(provider, container);
  }
}

class PondaiApp extends ConsumerStatefulWidget {
  const PondaiApp({super.key});

  @override
  ConsumerState<PondaiApp> createState() => _PondaiAppState();
}

class _PondaiAppState extends ConsumerState<PondaiApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');
      
      if (mounted) {
        setState(() {
          _themeMode = _getThemeModeFromString(savedTheme);
          _isLoading = false;
        });
      }
      
      developer.log('✅ Preferences loaded - Theme: $_themeMode', name: 'MAIN');
    } catch (e) {
      developer.log('⚠️ Failed to load preferences: $e', name: 'MAIN', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  ThemeMode _getThemeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? themeString;
      
      if (mode == ThemeMode.light) {
        themeString = 'light';
      } else if (mode == ThemeMode.dark) {
        themeString = 'dark';
      } else {
        themeString = 'system';
      }
      
      await prefs.setString('theme_mode', themeString);
      developer.log('✅ Theme saved: $themeString', name: 'MAIN');
    } catch (e) {
      developer.log('⚠️ Failed to save theme: $e', name: 'MAIN', error: e);
    }
  }

  void changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveThemeMode(mode);
  }

  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    changeTheme(newMode);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading Pondai Housing...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load application',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadPreferences();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Pondai Housing',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            overscroll: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      useMaterial3: true,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLight,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: AppColors.bgLight,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
      ),
      
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textLight),
      ),
      
      // FIXED: Changed DialogTheme to DialogThemeData
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 4,
      ),
      
      // FIXED: Changed BottomSheetTheme to BottomSheetThemeData
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      useMaterial3: true,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDark,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: AppColors.bgDark,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(color: AppColors.textDark),
      ),
      
      // FIXED: Changed DialogTheme to DialogThemeData
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 4,
      ),
      
      // FIXED: Changed BottomSheetTheme to BottomSheetThemeData
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}

// Extension for easy theme toggling from anywhere in the app
extension ThemeExtension on BuildContext {
  void toggleTheme() {
    final state = findAncestorStateOfType<_PondaiAppState>();
    state?.toggleTheme();
  }
  
  void setTheme(ThemeMode mode) {
    final state = findAncestorStateOfType<_PondaiAppState>();
    state?.changeTheme(mode);
  }
  
  ThemeMode get currentThemeMode {
    final state = findAncestorStateOfType<_PondaiAppState>();
    return state?._themeMode ?? ThemeMode.system;
  }
}