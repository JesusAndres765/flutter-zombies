import '../models/tweet.dart';
import '../models/reaction_count.dart';
import '../models/comment.dart';

abstract class ITweetRepository {
  // ── Tweets (existentes) ───────────────────────────────────────────────
  Future<List<Tweet>> fetchTweets();
  Future<Tweet> createTweet(String description, String? imageUrl);
  Future<void> deleteTweet(int id);
  Future<List<ReactionCount>> fetchReactions(int postId);
  Future<void> reactToPost(int postId, int reactionId);

  // ── Comentarios (nuevos) ──────────────────────────────────────────────
  Future<List<Comment>> fetchComments(int postId);
  Future<Comment> createComment(int postId, String content);
  Future<void> deleteComment(int postId, int commentId);

  void dispose();
}
