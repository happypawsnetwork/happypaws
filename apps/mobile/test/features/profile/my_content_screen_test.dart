import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/domain/repositories/i_post_repository.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mobile/features/profile/presentation/screens/my_content_screen.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository implements IAuthRepository {
  UserProfile? currentUser;

  _FakeAuthRepository({this.currentUser});

  @override
  Future<bool> checkSessionStatus() async => true;

  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async =>
      currentUser;

  @override
  void invalidateProfileCache() {}

  @override
  Future<MobileLoginResponse> login(String email, String password) async =>
      const MobileLoginResponse(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 3600,
      );

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async =>
      const VerificationTokenResponse(verificationToken: 'token');

  @override
  Future<void> verifyRegistrationCode({
    required String verificationToken,
    required String otpCode,
  }) async {}

  @override
  Future<MobileLoginResponse> completeRegistration({
    required String verificationToken,
    required String fullName,
    required String password,
  }) async => const MobileLoginResponse(
    accessToken: 'a',
    refreshToken: 'r',
    expiresIn: 3600,
  );

  @override
  Future<void> logout() async {}

  @override
  Future<VerificationTokenResponse> sendForgotPasswordCode(
    String email,
  ) async => const VerificationTokenResponse(verificationToken: 'token');

  @override
  Future<void> verifyForgotPasswordCode({
    required String verificationToken,
    required String otpCode,
  }) async {}

  @override
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {}
}

class _FakePostRepository implements IPostRepository {
  List<Post> posts = [];
  bool deletePostCalled = false;
  String? deletedPostId;

  _FakePostRepository({List<Post>? initialPosts}) {
    if (initialPosts != null) {
      posts = List.from(initialPosts);
    }
  }

  @override
  Future<List<Post>> getMyPosts({
    String? cursorId,
    DateTime? cursorDate,
  }) async {
    return posts;
  }

  @override
  Future<void> deletePost(String id) async {
    deletePostCalled = true;
    deletedPostId = id;
    posts.removeWhere((p) => p.id == id);
  }

  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async => (urgencyLevel: 'Low', reason: null);

  @override
  Future<Post> createPost(Map<String, dynamic> data) async => posts.first;

  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  }) async => posts;

  @override
  Future<List<Map<String, dynamic>>> getMyRescues() async => [];

  @override
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
    String? cursorId,
    DateTime? cursorDate,
  }) async => posts;

  @override
  Future<Post?> getPostById(String id) async =>
      posts.where((p) => p.id == id).firstOrNull;

  @override
  Future<List<Post>> getMapBoundsFeed({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    String? type,
  }) async => posts;

  @override
  Future<List<Post>> searchPosts(String query) async => posts;

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async =>
      (isLiked: false, likeCount: 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required UserProfile user,
    required _FakePostRepository postRepo,
  }) {
    final authRepo = _FakeAuthRepository(currentUser: user);
    final profileController = ProfileController(authRepo);

    return MultiProvider(
      providers: [
        Provider<IAuthRepository>.value(value: authRepo),
        Provider<IPostRepository>.value(value: postRepo),
        ChangeNotifierProvider<ProfileController>.value(
          value: profileController,
        ),
      ],
      child: const MaterialApp(home: MyContentScreen()),
    );
  }

  const testUser = UserProfile(
    id: 1,
    name: 'Kasun Perera',
    email: 'kasun@example.com',
    roles: [],
    username: 'kasun_rescuer',
  );

  final pendingPost = Post(
    id: 'post-1',
    type: PostType.rescueAlert,
    status: PostStatus.pendingApproval,
    title: 'Injured puppy near Kandy Road',
    body: 'Found a small puppy needing immediate medical attention.',
    likeCount: 3,
    isLikedByCurrentUser: false,
    authorId: 1,
    authorDisplayName: 'Kasun Perera',
    photoCount: 0,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    urgencyLevel: 'Critical',
    media: [],
  );

  final activePost = Post(
    id: 'post-2',
    type: PostType.adoptionListing,
    status: PostStatus.active,
    title: 'Playful Golden Retriever Pup',
    body: 'Healthy and vaccinated, looking for a loving home.',
    likeCount: 12,
    isLikedByCurrentUser: true,
    authorId: 1,
    authorDisplayName: 'Kasun Perera',
    photoCount: 0,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    animalName: 'Max',
    animalSpecies: 'Dog',
    locationLabel: 'Colombo 07',
    media: [],
  );

  group('MyContentScreen tests', () {
    testWidgets(
      'renders patterned header, user name, username, and category badge',
      (tester) async {
        final postRepo = _FakePostRepository(
          initialPosts: [pendingPost, activePost],
        );

        await tester.pumpWidget(
          createTestWidget(user: testUser, postRepo: postRepo),
        );
        await tester.pumpAndSettle();

        // Header paw pattern
        final imageFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image ==
                  const AssetImage('assets/images/pattern_pet_paws.jpg'),
        );
        expect(imageFinder, findsOneWidget);

        // User details
        expect(find.text('Kasun Perera'), findsOneWidget);
        expect(find.text('@kasun_rescuer'), findsOneWidget);

        // Screen badge
        expect(find.text('My content'), findsOneWidget);
        expect(find.byIcon(Icons.folder_shared_rounded), findsOneWidget);
      },
    );

    testWidgets('renders stat cards with correct post counts', (tester) async {
      final postRepo = _FakePostRepository(
        initialPosts: [pendingPost, activePost],
      );

      await tester.pumpWidget(
        createTestWidget(user: testUser, postRepo: postRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total posts'), findsOneWidget);
      expect(find.text('Active & live'), findsOneWidget);
      expect(find.text('Pending review'), findsWidgets);

      // Total count = 2, Active = 1, Pending = 1
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('renders filter tabs with counts and switches tabs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final postRepo = _FakePostRepository(
        initialPosts: [pendingPost, activePost],
      );

      await tester.pumpWidget(
        createTestWidget(user: testUser, postRepo: postRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Pending'), findsOneWidget);

      // All tab shows both posts
      expect(find.text('Injured puppy near Kandy Road'), findsOneWidget);
      expect(find.text('Playful Golden Retriever Pup'), findsOneWidget);

      // Switch to Active tab
      await tester.tap(find.text('Active').first);
      await tester.pumpAndSettle();

      expect(find.text('Playful Golden Retriever Pup'), findsOneWidget);
      expect(find.text('Injured puppy near Kandy Road'), findsNothing);

      // Switch to Pending tab
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      expect(find.text('Injured puppy near Kandy Road'), findsOneWidget);
      expect(find.text('Playful Golden Retriever Pup'), findsNothing);
      expect(
        find.text('Awaiting review before appearing in public feeds.'),
        findsOneWidget,
      );
    });

    testWidgets('renders empty states when no posts exist', (tester) async {
      final postRepo = _FakePostRepository(initialPosts: []);

      await tester.pumpWidget(
        createTestWidget(user: testUser, postRepo: postRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('No content yet'), findsOneWidget);
      expect(find.text('Create a post'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog and deletes post', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final postRepo = _FakePostRepository(initialPosts: [activePost]);

      await tester.pumpWidget(
        createTestWidget(user: testUser, postRepo: postRepo),
      );
      await tester.pumpAndSettle();

      // Tap delete icon button
      final deleteBtnFinder = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteBtnFinder, findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Delete post'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Playful Golden Retriever Pup"? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(postRepo.deletePostCalled, isTrue);
      expect(postRepo.deletedPostId, equals('post-2'));
      expect(find.text('Post deleted successfully'), findsOneWidget);
    });
  });
}
