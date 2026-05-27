import 'user.dart';

class Tweet {
  final int id;
  final String description;
  final String? imageUrl;
  final User? postedBy;

  Tweet({
    required this.id,
    required this.description,
    this.imageUrl,
    this.postedBy,
  });

  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      postedBy: json['postedBy'] != null
          ? User.fromJson(Map<String, dynamic>.from(json['postedBy'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() => 'Tweet(id: $id, description: $description)';
}