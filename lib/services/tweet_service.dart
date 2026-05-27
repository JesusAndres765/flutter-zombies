import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tweet.dart';
import '../models/tweet_response.dart';
import '../models/reaction_count.dart';
import '../repositories/tweet_repository.dart';
import 'auth_service.dart';

class TweetService implements ITweetRepository {
  static final TweetService _instance = TweetService._internal();

  // Para APK en dispositivo real: cambia a tu IP local, ej: http://192.168.1.X:8080/api
  final String baseUrl = 'http://localhost:8080/api';

  late http.Client _httpClient;
  late AuthService _authService;

  TweetService._internal() {
    _httpClient = http.Client();
    _authService = AuthService();
  }

  factory TweetService() => _instance;

  static TweetService getInstance() => _instance;

  Map<String, String> _getHeaders() {
    final token = _authService.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<Tweet>> fetchTweets() async {
    try {
      await _authService.init();
      final response = await _httpClient.get(
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
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Future<Tweet> createTweet(String description, String? imageUrl) async {
    try {
      await _authService.init();
      final response = await _httpClient.post(
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
      } else {
        throw Exception('Error al crear post: ${response.statusCode}. ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> deleteTweet(int id) async {
    try {
      await _authService.init();
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl/posts/$id'),
        headers: _getHeaders(),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar: ${response.statusCode}. ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Future<List<ReactionCount>> fetchReactions(int postId) async {
    try {
      await _authService.init();
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/posts/$postId/reactions'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => ReactionCount.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        throw Exception('Error al cargar reacciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> reactToPost(int postId, int reactionId) async {
    try {
      await _authService.init();
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/posts/$postId/reactions'),
        headers: _getHeaders(),
        body: jsonEncode({'reactionId': reactionId}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al reaccionar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}