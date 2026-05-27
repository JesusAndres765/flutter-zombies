import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Singleton service for authentication
/// Manages login, token storage and retrieval
class AuthService {
  static final AuthService _instance = AuthService._internal();

  final String baseUrl = 'http://localhost:8080/api';
  late http.Client _httpClient;
  SharedPreferences? _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Private constructor
  AuthService._internal() {
    _httpClient = http.Client();
  }

  /// Factory constructor that always returns the same instance
  factory AuthService() {
    return _instance;
  }

  /// Get the singleton instance
  static AuthService getInstance() {
    return _instance;
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Initialize SharedPreferences
  Future<void> init() async {
    await _ensureInit();
  }

Future<void> register(String username, String email, String password) async {
  try {
    await _ensureInit();
    final response = await _httpClient.post(
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
  } catch (e) {
    throw Exception('$e');
  }
}

  /// Login with username and password
  /// Returns the user if successful
  Future<User> login(String username, String password) async {
    try {
      await _ensureInit();
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('DEBUG LOGIN: Status code = ${response.statusCode}');
      print('DEBUG LOGIN: Response body = ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        print('DEBUG LOGIN: Parsed JSON = $jsonData');
        print('DEBUG LOGIN: JSON keys = ${jsonData.keys.toList()}');
        
        // Extract accessToken from response (API returns 'accessToken', not 'token')
        final token = jsonData['accessToken']?.toString() ?? '';
        print('DEBUG LOGIN: AccessToken value = "$token"');
        print('DEBUG LOGIN: AccessToken is null? ${jsonData['accessToken'] == null}');
        
        // Extract user data from root level (not nested in 'user' object)
        final userData = {
          'id': jsonData['id'],
          'username': jsonData['username'],
          'email': jsonData['email'],
        };
        
        print('DEBUG LOGIN: User data = $userData');
        
        if (token.isEmpty) {
          throw Exception('No access token received from server');
        }
        
        // Save token to SharedPreferences
        await _prefs!.setString(_tokenKey, token);
        
        // Create and save user
        final user = User.fromJson(userData);
        await _prefs!.setString(_userKey, jsonEncode(user.toJson()));
        
        print('✅ DEBUG: Token saved successfully - "$token"');
        print('✅ DEBUG: User saved - ${user.username}');
        
        return user;
      } else {
        throw Exception(
          'Failed to login. Status code: ${response.statusCode}. ${response.body}',
        );
      }
    } catch (e) {
      print('❌ DEBUG LOGIN ERROR: $e');
      throw Exception('Error during login: $e');
    }
  }

  /// Get the stored token (synchronously - ensures prefs is initialized)
  String? getToken() {
    // Attempt to get token synchronously
    // This assumes _prefs was already initialized
    if (_prefs == null) {
      return null;
    }
    final token = _prefs!.getString(_tokenKey);
    return token;
  }

  /// Get the stored user
  User? getUser() {
    if (_prefs == null) {
      return null;
    }
    final userJson = _prefs!.getString(_userKey);
    if (userJson != null) {
      final jsonData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(jsonData);
    }
    return null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getToken() != null && getToken()!.isNotEmpty;
  }

  /// Logout - clear token and user
  Future<void> logout() async {
    await _ensureInit();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
  }

  /// Close the HTTP client (cleanup)
  void dispose() {
    _httpClient.close();
  }
}
