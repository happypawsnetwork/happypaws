import '../models/post.dart';

abstract interface class IPostRepository {
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  });
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
    String? cursorId,
    DateTime? cursorDate,
  });
  Future<List<Post>> getMapBoundsFeed({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    String? type,
  });
  Future<Post?> getPostById(String id);
  Future<List<Post>> searchPosts({
    String? query,
    String? species,
    String? location,
    String? urgency,
    String? type,
    double? lat,
    double? lon,
    double? radiusKm,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
    int pageSize = 20,
  });
  Future<List<Post>> getMyPosts({String? cursorId, DateTime? cursorDate});
  Future<List<Map<String, dynamic>>> getMyRescues();
  Future<Post> createPost(Map<String, dynamic> data);
  Future<void> deletePost(String id);
  Future<({bool isLiked, int likeCount})> toggleLike(String postId);
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  );
}
