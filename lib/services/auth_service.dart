import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException();
  @override
  String toString() => 'Sesión expirada. Inicia sesión nuevamente.';
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  String get baseUrl => AppConfig.baseUrl;

  SharedPreferences? _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'auth_user';

  AuthService._internal();
  factory AuthService() => _instance;
  static AuthService getInstance() => _instance;

  Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    await _ensureInit();
  }

  Future<void> register(String username, String email, String password) async {
    try {
      await _ensureInit();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return;
      } else {
        String errorMsg = 'Error al registrar (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errorMsg = body['message']?.toString() ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$e');
    }
  }

  Future<User> login(String username, String password) async {
    try {
      await _ensureInit();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final token = jsonData['accessToken']?.toString() ?? '';
        final userData = {
          'id':       jsonData['id'],
          'username': jsonData['username'],
          'email':    jsonData['email'],
        };

        if (token.isEmpty) {
          throw Exception('No se recibió token del servidor');
        }

        await _prefs!.setString(_tokenKey, token);
        final user = User.fromJson(userData);
        await _prefs!.setString(_userKey, jsonEncode(user.toJson()));
        return user;
      } else {
        String errorMsg = 'Error al iniciar sesión (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errorMsg = body['message']?.toString() ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$e');
    }
  }

  String? getToken() {
    if (_prefs == null) return null;
    return _prefs!.getString(_tokenKey);
  }

  User? getUser() {
    if (_prefs == null) return null;
    final userJson = _prefs!.getString(_userKey);
    if (userJson != null) {
      final jsonData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(jsonData);
    }
    return null;
  }

  bool isAuthenticated() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpia la sesión local (token expirado o inválido)
  Future<void> clearSession() async {
    await _ensureInit();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
  }

  Future<void> logout() async {
    await clearSession();
  }

  void dispose() {}
}