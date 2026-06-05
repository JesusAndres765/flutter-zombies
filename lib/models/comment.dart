class Comment {
  final int id;
  final String content;
  final int? userId;
  final String username;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.content,
    this.userId,
    required this.username,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id:        json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      content:   json['content']?.toString() ?? '',
      userId:    json['userId'] is int ? json['userId'] : int.tryParse(json['userId'].toString()),
      username:  json['username']?.toString() ?? 'Desconocido',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool isOwner(int? currentUserId) =>
      currentUserId != null && userId != null && userId == currentUserId;
}
