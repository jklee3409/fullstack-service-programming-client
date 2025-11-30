import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl =
      'https://fullstack-service-programming-backend.onrender.com';

  static const String githubClientId = 'Ov23licCt1jHbBr5kyur';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36... (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
    },
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '$baseUrl/api/auth/refresh',
                options: Options(headers: {
                  'Authorization-Refresh': 'Bearer $refreshToken',
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 10; K) AppleW... (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
                }),
              );
              final newAccess = response.data['data']['accessToken'];
              final newRefresh = response.data['data']['refreshToken'];
              await _storage.write(key: 'accessToken', value: newAccess);
              await _storage.write(key: 'refreshToken', value: newRefresh);

              e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';

              final cloneReq = await _dio.request(
                e.requestOptions.path,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                ),
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (refreshError) {
              await logout();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> loginWithGithub(String code) async {
    try {
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');

      final response = await _dio.post(
        '/api/auth/github/login',
        data: {'code': code},
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        print("Login Success");
        return true;
      }
    } catch (e) {
      if (e is DioException) {
        print('=== Login Error Details ===');
        print('Status Code: ${e.response?.statusCode}');
        print('Error Data: ${e.response?.data}');
        print('Message: ${e.message}');
      } else {
        print('Login Error: $e');
      }
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<List<dynamic>> getRepositories() async {
    final response = await _dio.get('/api/repositories');
    return response.data['data'];
  }

  Future<void> registerRepository(String fullName) async {
    await _dio.post('/api/repositories', data: {'repoFullName': fullName});
  }

  Future<Map<String, dynamic>> getCommits(int repoId, int page) async {
    final response = await _dio.get(
      '/api/repositories/$repoId/commits',
      queryParameters: {'page': page, 'size': 20},
    );
    return response.data['data'];
  }

  Future<dynamic> getCommitDetail(int commitId) async {
    final response = await _dio.get('/api/commits/$commitId');
    return response.data['data'];
  }

  Future<void> registerFcmToken(String token) async {
    await _dio.post('/api/fcm/token', data: {'fcmToken': token});
  }

  Future<List<dynamic>> getNotifications(String fcmToken) async {
    final response = await _dio.get(
      '/api/notifications',
      queryParameters: {'fcmToken': fcmToken},
    );
    return response.data;
  }
}
