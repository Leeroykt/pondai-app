import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  // Initializing Dio inside the constructor ensures it is never called before setup
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // Keeping an empty function placeholder so you don't break main.dart if it gets called there
  void init() {}

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, Map<String, dynamic> data) => _dio.post(path, data: data);
  Future<Response> put(String path, Map<String, dynamic> data) => _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);

  bool isNetworkError(dynamic e) =>
      e is DioException &&
      (e.type == DioExceptionType.connectionTimeout ||
       e.type == DioExceptionType.connectionError ||
       e.type == DioExceptionType.receiveTimeout);
}