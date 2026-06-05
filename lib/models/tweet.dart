class Tweet {
  final int id;
  final String tweet;
  final int? userId;       // ID del autor (del servidor)
  final String? username;  // nombre del autor (del servidor)
  final int commentCount;
  final String? imageUrl;  // Agregado para soportar las imágenes de Zombie Network

  const Tweet({
    required this.id,
    required this.tweet,
    this.userId,
    this.username,
    this.commentCount = 0,
    this.imageUrl, // Opcional por si no todos los posts llevan imagen
  });

  factory Tweet.fromJson(Map<String, dynamic> json) => Tweet(
        id: json['id'] as int,
        tweet: json['tweet'] as String,
        userId: json['userId'] as int?,
        username: json['username'] as String?,
        commentCount: json['commentCount'] as int? ?? 0,
        imageUrl: json['imageUrl'] as String?, // Mapea la imagen si viene del backend
      );

  // ─── GETTERS COMPATIBLES CON TU MAIN.DART ─────────────────────────

  /// Traduce 'description' hacia tu variable real 'tweet'
  String get description => tweet;

  /// Simula la estructura 'postedBy.id' y 'postedBy.username' creando un objeto virtual
  _VirtualUser? get postedBy => userId != null || username != null
      ? _VirtualUser(id: userId, username: username)
      : null;

  /// Devuelve true si este tweet pertenece al usuario con [currentUserId]
  bool isOwner(int currentUserId) => userId != null && userId == currentUserId;
}

// Clase auxiliar oculta para que 'widget.post.postedBy?.username' no falle
class _VirtualUser {
  final int? id;
  final String? username;
  const _VirtualUser({this.id, this.username});
}