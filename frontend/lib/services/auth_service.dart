import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<(String token, User user)> login(String email, String password) async {
    final res = await _api.post('/login', {
      'email': email,
      'password': password,
    });
    return (
      res['token'] as String,
      User.fromMap(res['user'] as Map<String, dynamic>)
    );
  }

  Future<(String token, User user)> register(String name, String email, String password) async {
    final res = await _api.post('/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return (
      res['token'] as String,
      User.fromMap(res['user'] as Map<String, dynamic>)
    );
  }

  Future<void> logout() async {
    await _api.post('/logout', {});
  }
}
