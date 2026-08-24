import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool isLoading = true;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      try {
        final res = await ApiClient(token: _token).get('/users/me');
        _user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      } catch (_) {
        await _clearSession();
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await ApiClient().post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    await _applySession(res);
  }

  Future<void> login({required String email, required String password}) async {
    final res = await ApiClient().post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _applySession(res);
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<String> forgotPassword(String email) async {
    final res = await ApiClient().post('/auth/forgot-password', {'email': email});
    return res['message'] as String;
  }

  Future<String> resetPassword({required String token, required String password}) async {
    final res = await ApiClient().post('/auth/reset-password', {
      'token': token,
      'password': password,
    });
    return res['message'] as String;
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final res = await ApiClient(token: _token).put('/users/me', {
      'name': ?name,
      'phone': ?phone,
    });
    _user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> uploadPhoto(File file) async {
    final res = await UserService(token: _token!).uploadPhoto(file);
    _user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await ApiClient(token: _token).put('/users/me/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount(String password) async {
    await ApiClient(token: _token).delete('/users/me', body: {'password': password});
    await _clearSession();
    notifyListeners();
  }

  Future<void> _applySession(Map<String, dynamic> res) async {
    _token = res['token'] as String;
    _user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _user = null;
  }
}
