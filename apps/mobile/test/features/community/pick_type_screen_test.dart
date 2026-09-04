import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/domain/repositories/i_post_repository.dart';
import 'package:mobile/features/community/presentation/controllers/create_post_controller.dart';
import 'package:mobile/features/community/presentation/screens/create/pick_type_screen.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:provider/provider.dart';

class _FakePostRepository implements IPostRepository {
  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async {
    return (urgencyLevel: 'High', reason: 'Visible injury');
  }

  @override
  Future<Post> createPost(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePost(String id) async {}

  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

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
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<Post?> getPostById(String id) async => null;

  @override
  Future<List<Post>> searchPosts(String query) async => [];

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async {
    return (isLiked: true, likeCount: 1);
  }
}

class _FakeAuthRepository implements IAuthRepository {
  @override
  Future<bool> checkSessionStatus() async => true;

  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async =>
      null;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePostRepository postRepository;
  late _FakeAuthRepository authRepository;
  late CreatePostController controller;

  setUp(() {
    postRepository = _FakePostRepository();
    authRepository = _FakeAuthRepository();
    controller = CreatePostController(postRepository);
  });

  Widget buildTestWidget({GoRouter? router}) {
    final effectiveRouter =
        router ??
        GoRouter(
          initialLocation: '/community/create/pick-type',
          routes: [
            GoRoute(
              path: '/community/create/pick-type',
              builder: (context, state) => const PickTypeScreen(),
            ),
            GoRoute(
              path: '/community/create/rescue/photos',
              builder: (context, state) =>
                  const Scaffold(body: Text('Rescue Photos')),
            ),
          ],
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CreatePostController>.value(value: controller),
      ],
      child: MaterialApp.router(routerConfig: effectiveRouter),
    );
  }

  testWidgets('renders category header and all seven post types', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Create post'), findsOneWidget);
    expect(find.text('What would you like to share?'), findsOneWidget);
    expect(find.text('Rescue alert'), findsOneWidget);
    expect(find.text('Foster update'), findsOneWidget);
    expect(find.text('Find home'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);
    expect(find.text('Transport request'), findsOneWidget);
    expect(find.text('Treatment request'), findsOneWidget);
    expect(find.text('Sponsorship request'), findsOneWidget);
  });

  testWidgets('resets draft and updates selected type on tap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Populate dummy state into controller before selecting an option
    controller.title = 'Old title';
    controller.species = 'Dog';

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap the Rescue alert card
    await tester.tap(find.text('Rescue alert'));
    await tester.pumpAndSettle();

    // Verify controller reset state and set the new post type
    expect(controller.title, '');
    expect(controller.species, '');
    expect(controller.selectedType, PostType.rescueAlert);
    expect(find.text('Rescue Photos'), findsOneWidget);
  });

  testWidgets(
    'verifies router resolves /community/create/pick-type without exception',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<IAuthRepository>.value(value: authRepository),
            Provider<IPostRepository>.value(value: postRepository),
            ChangeNotifierProvider<CreatePostController>.value(
              value: controller,
            ),
          ],
          child: MaterialApp.router(routerConfig: appRouter),
        ),
      );

      appRouter.go('/community/create/pick-type');
      await tester.pumpAndSettle();

      expect(find.text('Create post'), findsOneWidget);
      expect(find.text('What would you like to share?'), findsOneWidget);
    },
  );

  testWidgets(
    'renders back button with arrow_back_rounded and pops route on press',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/community/create/pick-type'),
                child: const Text('Go to Pick Type'),
              ),
            ),
          ),
          GoRoute(
            path: '/community/create/pick-type',
            builder: (context, state) => const PickTypeScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pumpAndSettle();

      // Navigate to pick type screen
      await tester.tap(find.text('Go to Pick Type'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Should be back at home screen
      expect(find.text('Go to Pick Type'), findsOneWidget);
    },
  );
}
