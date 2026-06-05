import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tweet.dart';
import '../models/tweet_response.dart';
import '../models/reaction_count.dart';
import '../models/comment.dart';
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

  // ── Tweets ────────────────────────────────────────────────────────────────

  @override
  Future<List<Tweet>> fetchTweets() async {
    // NOTA: un 401 aquí puede ser un error transitorio del servidor (cold start
    // de Render, DB no lista aún). NO se borra la sesión — solo se muestra
    // el error con opción de reintentar. La sesión solo se invalida si el
    // usuario intenta una acción que explícitamente requiere auth (POST/DELETE).
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
      } else if (response.statusCode == 401) {
        // Servidor no aceptó el token (puede ser transitorio en Render).
        // NO se limpia la sesión — el usuario puede reintentar.
        throw Exception(
          'Error al cargar posts: 401 — el servidor rechazó la petición.\n'
          'Si el servidor acaba de despertar, espera unos segundos y reintenta.',
        );
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
        // POST requiere auth real — aquí sí es una sesión inválida.
        await _authService.clearSession();
        throw const SessionExpiredException();
      } else {
        throw Exception(
            'Error al crear post: ${response.statusCode}. ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
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
        await _authService.clearSession();
        throw const SessionExpiredException();
      } else if (response.statusCode == 403) {
        throw Exception('No puedes eliminar un post que no es tuyo.');
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Error al eliminar: ${response.statusCode}. ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
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
      } else if (response.statusCode == 401) {
        // Igual que fetchTweets: puede ser transitorio, no invalida sesión.
        return []; // regresa vacío silenciosamente para no romper la UI
      } else {
        throw Exception('Error al cargar reacciones: ${response.statusCode}');
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
      if (response.statusCode == 401) {
        await _authService.clearSession();
        throw const SessionExpiredException();
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al reaccionar: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  // ── Comentarios ────────────────────────────────────────────────────────────

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    try {
      await _authService.init();
      final response = await http.get(
        Uri.parse('$baseUrl/tweets/$postId/comments'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else if (response.statusCode == 401) {
        return []; // transitorio, no invalida sesión
      } else {
        throw Exception(
            'Error al cargar transmisiones: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  Future<Comment> createComment(int postId, String content) async {
    try {
      await _authService.init();
      final response = await http.post(
        Uri.parse('$baseUrl/tweets/$postId/comments'),
        headers: _getHeaders(),
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Comment.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
      } else if (response.statusCode == 401) {
        await _authService.clearSession();
        throw const SessionExpiredException();
      } else {
        throw Exception('Error al transmitir: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> deleteComment(int postId, int commentId) async {
    try {
      await _authService.init();
      final response = await http.delete(
        Uri.parse('$baseUrl/tweets/$postId/comments/$commentId'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 401) {
        await _authService.clearSession();
        throw const SessionExpiredException();
      } else if (response.statusCode == 403) {
        throw Exception('Solo el autor puede eliminar esta transmisión.');
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Error al eliminar transmisión: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      throw Exception('No se pudo conectar al servidor: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: $e');
    }
  }

  @override
  void dispose() {}
}