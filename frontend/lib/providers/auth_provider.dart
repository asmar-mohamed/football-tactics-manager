import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? token;

  final ApiService api = ApiService();

  bool get isAuth => token != null;

  Future login(String email, String password) async {
    final data = await api.login(email, password);

    token = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token!);

    notifyListeners();
  }

  Future register(String name, String email, String password) async {
    final data = await api.register(name, email, password);

    token = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token!);

    notifyListeners();
  }

  Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      await api.logout(token);
    }

    await prefs.remove("token");

    this.token = null;

    notifyListeners();
  }

  Future autoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("token");

    notifyListeners();
  }
}