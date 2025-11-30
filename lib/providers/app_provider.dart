import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  List<Repository> _repositories = [];
  List<Repository> get repositories => _repositories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 앱 시작 시 로그인 상태 확인
  Future<void> checkLoginStatus() async {
    String? token = await _storage.read(key: 'accessToken');
    if (token != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String code) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _api.loginWithGithub(code);
    _isAuthenticated = success;
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _api.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> fetchRepositories() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _api.getRepositories();
      _repositories = list.map((e) => Repository.fromJson(e)).toList();
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRepository(String fullName) async {
    await _api.registerRepository(fullName);
    await fetchRepositories();
  }

  ApiService get api => _api;
}
