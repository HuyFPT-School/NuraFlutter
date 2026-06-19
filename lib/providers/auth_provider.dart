import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _user?.role == 'Admin';
  bool get isStaff => _user?.role == 'Staff';
  bool get isUser => _user?.role == 'User' || _user?.role == null;

  String get homeRouteForRole {
    switch (_user?.role) {
      case 'Admin': return '/admin-home';
      case 'Staff': return '/staff-home';
      default: return '/home';
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('accessToken');
    final userJson = prefs.getString('auth_user');

    if (_token != null && userJson != null) {
      try {
        _user = UserModel.fromJson(json.decode(userJson));
        final role = _getRoleFromToken(_token!);
        if (role != null && _user != null) {
          _user = UserModel(
            id: _user!.id, email: _user!.email, fullname: _user!.fullname,
            role: role, phone: _user!.phone, address: _user!.address,
            avatar: _user!.avatar, isVerified: true,
          );
        }
      } catch (_) {
        await _clearAuth();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      _token = data['accessToken'];
      _user = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _token!);
      await prefs.setString('auth_user', json.encode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(email, password, fullname);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.verifyEmail(email, otp);
      _token = data['accessToken'];
      _user = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _token!);
      await prefs.setString('auth_user', json.encode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try { await _authService.logout(); } catch (_) {}
    await _clearAuth();
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    _token = null;
    _user = null;
    await ApiClient.clearToken();
  }

  String? _getRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload['role'];
    } catch (_) {
      return null;
    }
  }
}
