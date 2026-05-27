import 'tweet.dart';

class TweetResponse {
  final List<Tweet> content;

  TweetResponse({required this.content});

  factory TweetResponse.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return TweetResponse(
      content: contentList
          .map((e) => Tweet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}