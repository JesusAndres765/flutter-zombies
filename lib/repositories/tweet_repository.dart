import '../models/tweet.dart';
import '../models/reaction_count.dart';

abstract class ITweetRepository {
  Future<List<Tweet>> fetchTweets();
  Future<Tweet> createTweet(String description, String? imageUrl);
  Future<void> deleteTweet(int id);
  Future<List<ReactionCount>> fetchReactions(int postId);
  Future<void> reactToPost(int postId, int reactionId);
  void dispose();
}