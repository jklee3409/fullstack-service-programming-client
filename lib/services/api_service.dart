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
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
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
        // 401 에러(토큰 만료) 시 리프레시 로직
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '$baseUrl/api/auth/refresh',
                options: Options(headers: {
                  'Authorization-Refresh': 'Bearer $refreshToken',
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
                }),
              );
              final newAccess = response.data['data']['accessToken'];
              final newRefresh = response.data['data']['refreshToken'];
              await _storage.write(key: 'accessToken', value: newAccess);
              await _storage.write(key: 'refreshToken', value: newRefresh);

              // 원래 요청 재시도
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';

              // 재요청 시에도 헤더 유지
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

  // 로그인 (GitHub Code 전송)
  Future<bool> loginWithGithub(String code) async {
    try {
      print("Logging in with code: $code");

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
      // [중요] 에러 상세 분석 로그
      if (e is DioException) {
        print('=== Login Error Details ===');
        print('Status Code: ${e.response?.statusCode}');
        print('Error Data: ${e.response?.data}'); // 서버가 보낸 거절 메시지 확인
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
    final response = await _dio.get('/api/repositories/$repoId/commits',
        queryParameters: {'page': page, 'size': 20});
    return response.data['data'];
  }

  Future<dynamic> getCommitDetail(int commitId) async {
    final response = await _dio.get('/api/commits/$commitId');
    return response.data['data'];
  }
}
