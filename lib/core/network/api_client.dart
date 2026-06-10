import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        developer.log('${options.method} ${options.uri}', name: 'API_CLIENT');
        handler.next(options);
      },
      onResponse: (response, handler) {
        developer.log('Response ${response.statusCode}', name: 'API_CLIENT');
        handler.next(response);
      },
      onError: (error, handler) {
        developer.log('API Error: ${error.message}', name: 'API_CLIENT', error: error);
        handler.next(error);
      },
    ));
  }

  void init() {}

  Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } catch (e) {
      developer.log('GET $path failed: $e', name: 'API_CLIENT', error: e);
      rethrow;
    }
  }
  
  Future<Response> post(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      developer.log('POST $path failed: $e', name: 'API_CLIENT', error: e);
      rethrow;
    }
  }
  
  Future<Response> put(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      developer.log('PUT $path failed: $e', name: 'API_CLIENT', error: e);
      rethrow;
    }
  }
  
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      developer.log('DELETE $path failed: $e', name: 'API_CLIENT', error: e);
      rethrow;
    }
  }

  bool isNetworkError(dynamic e) =>
      e is DioException &&
      (e.type == DioExceptionType.connectionTimeout ||
       e.type == DioExceptionType.connectionError ||
       e.type == DioExceptionType.receiveTimeout);
}