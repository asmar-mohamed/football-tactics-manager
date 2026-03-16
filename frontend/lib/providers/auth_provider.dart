import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  User? user;
  String? token;
  bool _initialised = false;

  bool get isReady => _initialised;
  bool get isAuth => token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      ApiClient.instance.setToken(token);
    }
    _initialised = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final (tok, usr) = await _service.login(email, password);
    token = tok;
    user = usr;
    ApiClient.instance.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token!);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final (tok, usr) = await _service.register(name, email, password);
    token = tok;
    user = usr;
    ApiClient.instance.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token!);
    notifyListeners();
  }

  Future<void> logout() async {
    if (token != null) {
      try {
        await _service.logout();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    token = null;
    user = null;
    ApiClient.instance.setToken(null);
    notifyListeners();
  }
}
