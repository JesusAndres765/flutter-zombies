import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tweet.dart';
import '../models/tweet_response.dart';
import '../models/reaction_count.dart';
import '../repositories/tweet_repository.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class TweetService implements ITweetRepository {
  static final TweetService _instance = TweetService._internal();

  String get baseUrl => AppConfig.baseUrl;

  late AuthService _authService;

  TweetService._internal() {
    _authService = AuthService();
  }

  factory TweetService() => _instance;

  static TweetService getInstance() => _instance;

  Map<String, String> _getHeaders() {
    final token = _authService.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<Tweet>> fetchTweets() async {
    try {
      await _authService.init();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/all'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final tweetResponse = TweetResponse.fromJson(
            Map<String, dynamic>.from(jsonData as Map));
        return tweetResponse.content;
      } else {
        throw Exception('Error al cargar posts: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  Future<Tweet> createTweet(String description, String? imageUrl) async {
    try {
      await _authService.init();
      final response = await http.post(
        Uri.parse('$baseUrl/posts/create'),
        headers: _getHeaders(),
        body: jsonEncode({
          'description': description,
          'imageUrl': imageUrl ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Tweet.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      } else {
        throw Exception(
            'Error al crear post: ${response.statusCode}. ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> deleteTweet(int id) async {
    try {
      await _authService.init();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$id'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      } else if (response.statusCode == 403) {
        throw Exception('No puedes eliminar un post que no es tuyo.');
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Error al eliminar: ${response.statusCode}. ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  Future<List<ReactionCount>> fetchReactions(int postId) async {
    try {
      await _authService.init();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/reactions'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) =>
                ReactionCount.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        throw Exception(
            'Error al cargar reacciones: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> reactToPost(int postId, int reactionId) async {
    try {
      await _authService.init();
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/reactions'),
        headers: _getHeaders(),
        body: jsonEncode({'reactionId': reactionId}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al reaccionar: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  void dispose() {
    // Singleton — no cerrar recursos compartidos
  }
}