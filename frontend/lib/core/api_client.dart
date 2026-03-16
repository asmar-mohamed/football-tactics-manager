import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers({bool jsonBody = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('${Env.apiBaseUrl}$path'), headers: _headers(jsonBody: false));
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${Env.apiBaseUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('${Env.apiBaseUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('${Env.apiBaseUrl}$path'), headers: _headers(jsonBody: false));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final data = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(res.statusCode, data);
  }
}

class ApiException implements Exception {
  final int status;
  final dynamic data;
  ApiException(this.status, this.data);

  @override
  String toString() => 'ApiException($status): $data';
}
