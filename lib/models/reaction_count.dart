class ReactionCount {
  final int reactionId;
  final String reactionType;
  final int count;

  ReactionCount({
    required this.reactionId,
    required this.reactionType,
    required this.count,
  });

  factory ReactionCount.fromJson(Map<String, dynamic> json) {
    return ReactionCount(
      reactionId: json['reactionId'] is int
          ? json['reactionId']
          : int.tryParse(json['reactionId'].toString()) ?? 0,
      reactionType: json['reactionType']?.toString() ?? '',
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}