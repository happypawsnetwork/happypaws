import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/domain/repositories/i_post_repository.dart';
import 'package:mobile/features/community/presentation/controllers/community_controller.dart';
import 'package:mobile/features/community/presentation/screens/community_screen.dart';

class _FakePostRepo implements IPostRepository {
  final List<Post> feedResult;
  _FakePostRepo(this.feedResult);

  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  }) async {
    if (cursorId != null) {
      await Future.delayed(const Duration(seconds: 2));
      return [];
    }
    return feedResult;
  }

  @override
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
    String? cursorId,
    DateTime? cursorDate,
  }) async => feedResult;

  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async => (urgencyLevel: 'Low', reason: null);

  @override
  Future<Post> createPost(Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<void> deletePost(String id) async {}

  @override
  Future<List<Post>> getMapBoundsFeed({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    String? type,
  }) async => [];

  @override
  Future<List<Post>> getMyPosts({
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getMyRescues() async => [];

  @override
  Future<Post?> getPostById(String id) async => null;

  @override
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
  }) async => [];

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async =>
      (isLiked: false, likeCount: 0);
}

Post _createDummyPost(String id) {
  return Post(
    id: id,
    type: PostType.highlight,
    status: PostStatus.active,
    title: 'Post $id',
    body: 'Sample body for $id',
    likeCount: 5,
    isLikedByCurrentUser: false,
    authorId: 1,
    authorDisplayName: 'Jane Doe',
    photoCount: 0,
    createdAt: DateTime.now(),
    media: const [],
  );
}

void main() {
  testWidgets(
    'renders end-of-feed message when all posts are loaded and hasMore is false',
    (tester) async {
      // 3 posts returned, which is < 10, so hasMore will be false
      final posts = [
        _createDummyPost('1'),
        _createDummyPost('2'),
        _createDummyPost('3'),
      ];
      final repo = _FakePostRepo(posts);
      final controller = CommunityController(repo);
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CommunityController>.value(
              value: controller,
              child: CommunityScreen(
                scrollController: scrollController,
                topPadding: 0,
              ),
            ),
          ),
        ),
      );

      // Initial load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text("You've seen all the furry friends for now! 🐾"),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('renders loading indicator at end when hasMore is true', (
    tester,
  ) async {
    // 10 posts returned, which is >= 10, so hasMore will be true
    final posts = List.generate(10, (i) => _createDummyPost('$i'));
    final repo = _FakePostRepo(posts);
    final controller = CommunityController(repo);
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<CommunityController>.value(
            value: controller,
            child: CommunityScreen(
              scrollController: scrollController,
              topPadding: 0,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text("You've seen all the furry friends for now! 🐾"),
      findsNothing,
    );

    // Scroll down to the bottom
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pump();

    // While loading more, CircularProgressIndicator is visible at the end
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Fast-forward delay so load completes with empty list (no more posts)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Now hasMore is false and end-of-feed message is displayed
    expect(
      find.text("You've seen all the furry friends for now! 🐾"),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
