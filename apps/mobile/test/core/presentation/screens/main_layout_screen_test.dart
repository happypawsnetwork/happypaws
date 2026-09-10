import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/core/presentation/screens/main_layout_screen.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:mobile/features/profile/presentation/controllers/profile_controller.dart';

import 'package:mobile/features/community/domain/models/post.dart';
import 'package:mobile/features/community/domain/repositories/i_post_repository.dart';
import 'package:mobile/features/community/presentation/controllers/community_controller.dart';
import 'package:mobile/features/community/presentation/screens/nearby_rescue_map_screen.dart';
import 'package:mobile/features/messaging/presentation/controllers/chat_controller.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import '../../../helpers/mock_geolocator_platform.dart';

class MockAuthRepository implements IAuthRepository {
  UserProfile? mockProfile;

  MockAuthRepository({this.mockProfile});

  @override
  Future<bool> checkSessionStatus() async => true;

  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async {
    return mockProfile;
  }

  @override
  void invalidateProfileCache() {}

  @override
  Future<MobileLoginResponse> login(String email, String password) async {
    return const MobileLoginResponse(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      expiresIn: 3600,
    );
  }

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async {
    return const VerificationTokenResponse(verificationToken: 'token');
  }

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
  }) async {
    return const MobileLoginResponse(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      expiresIn: 3600,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<VerificationTokenResponse> sendForgotPasswordCode(String email) async {
    return const VerificationTokenResponse(verificationToken: 'token');
  }

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

class MockPostRepository implements IPostRepository {
  @override
  Future<List<Post>> getCommunityFeed({
    String? type,
    String sort = 'newest',
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Post>> getNearbyFeed({
    required double lat,
    required double lon,
    double radiusKm = 10,
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
  Future<List<Post>> getMyPosts({
    String? cursorId,
    DateTime? cursorDate,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getMyRescues() async => [];

  @override
  Future<Post> createPost(Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<void> deletePost(String id) async {}

  @override
  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async =>
      (isLiked: false, likeCount: 0);

  @override
  Future<({String urgencyLevel, String? reason})> assessRescueUrgency(
    List<String> photoPaths,
  ) async => (urgencyLevel: 'Low', reason: null);
}

class MockChatController extends ChatController {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> fetchThreads() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({UserProfile? profile}) {
    final authRepo = MockAuthRepository(mockProfile: profile);
    final postRepo = MockPostRepository();
    final profileController = ProfileController(authRepo);
    final communityController = CommunityController(postRepo);
    final chatController = MockChatController();

    return MultiProvider(
      providers: [
        Provider<IAuthRepository>.value(value: authRepo),
        Provider<IPostRepository>.value(value: postRepo),
        ChangeNotifierProvider<ProfileController>.value(
          value: profileController,
        ),
        ChangeNotifierProvider<CommunityController>.value(
          value: communityController,
        ),
        ChangeNotifierProvider<ChatController>.value(value: chatController),
      ],
      child: const MaterialApp(home: MainLayoutScreen()),
    );
  }

  group('MainLayoutScreen navigation bar', () {
    setUp(() {
      GeolocatorPlatform.instance = MockGeolocatorPlatform();
    });

    testWidgets('renders all navigation icons and add button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
    });

    testWidgets('displays fallback letter initial when avatarUrl is null', (
      WidgetTester tester,
    ) async {
      const testProfile = UserProfile(
        id: 1,
        email: 'nethmina@example.com',
        name: 'Nethmina Gunasekara',
        avatarUrl: null,
        roles: [UserRole(name: 'Adopter', isVerified: false)],
      );

      await tester.pumpWidget(createTestWidget(profile: testProfile));
      await tester.pumpAndSettle();

      expect(find.text('N'), findsOneWidget);
    });

    testWidgets('displays image avatar when avatarUrl is provided', (
      WidgetTester tester,
    ) async {
      const testProfile = UserProfile(
        id: 1,
        email: 'nethmina@example.com',
        name: 'Nethmina Gunasekara',
        avatarUrl: 'https://example.com/avatar.png',
        roles: [UserRole(name: 'Adopter', isVerified: false)],
      );

      await tester.pumpWidget(createTestWidget(profile: testProfile));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('switches active tab when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.location_on_outlined));
      await tester.pumpAndSettle();

      // Nearby content should be visible
      expect(find.byType(NearbyRescueMapScreen), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets(
      'navigates to notifications screen from header button with no active main menu item',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially on Community tab (active icon is Icons.group)
        expect(find.byIcon(Icons.group), findsOneWidget);

        // Find header notifications button
        final notificationButton = find.byTooltip('Notifications');
        expect(notificationButton, findsOneWidget);

        await tester.tap(notificationButton);
        await tester.pumpAndSettle();

        // Notifications screen should be displayed
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('No notifications yet'), findsOneWidget);

        // Verify no main menu item is active (all active icons should be absent, outlines present with unselected color)
        expect(find.byIcon(Icons.group), findsNothing);
        expect(find.byIcon(Icons.location_on), findsNothing);
        expect(find.byIcon(Icons.forum), findsNothing);

        final communityIcon = tester.widget<Icon>(
          find.byIcon(Icons.group_outlined),
        );
        final nearbyIcon = tester.widget<Icon>(
          find.byIcon(Icons.location_on_outlined),
        );
        final chatsIcon = tester.widget<Icon>(
          find.byIcon(Icons.forum_outlined),
        );

        expect(communityIcon.color, const Color(0xFF94A3B8));
        expect(nearbyIcon.color, const Color(0xFF94A3B8));
        expect(chatsIcon.color, const Color(0xFF94A3B8));

        // Tapping back button on NotificationsScreen returns to Community tab
        final backButton = find.byTooltip('Back');
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.group), findsOneWidget);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.group)).color,
          const Color(0xFF008585),
        );
      },
    );

    testWidgets(
      'navigates to notifications screen from profile tab menu item with no active main menu item',
      (WidgetTester tester) async {
        const testProfile = UserProfile(
          id: 1,
          email: 'nethmina@example.com',
          name: 'Nethmina Gunasekara',
          avatarUrl: null,
          roles: [UserRole(name: 'Adopter', isVerified: false)],
        );

        await tester.pumpWidget(createTestWidget(profile: testProfile));
        await tester.pumpAndSettle();

        // Switch to Profile tab
        await tester.tap(find.byTooltip('Profile'));
        await tester.pumpAndSettle();

        // Scroll until Notifications list tile is visible in profile list
        final notificationsItem = find.text('Notifications');
        await tester.scrollUntilVisible(
          notificationsItem,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        final profileNotificationsTile = find.widgetWithText(
          ListTile,
          'Notifications',
        );
        expect(profileNotificationsTile, findsOneWidget);

        await tester.tap(profileNotificationsTile);
        await tester.pumpAndSettle();

        // Notifications screen should be displayed
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('No notifications yet'), findsOneWidget);

        // Verify no main menu item is active
        expect(find.byIcon(Icons.group), findsNothing);
        expect(find.byIcon(Icons.location_on), findsNothing);
        expect(find.byIcon(Icons.forum), findsNothing);

        final communityIcon = tester.widget<Icon>(
          find.byIcon(Icons.group_outlined),
        );
        final nearbyIcon = tester.widget<Icon>(
          find.byIcon(Icons.location_on_outlined),
        );
        final chatsIcon = tester.widget<Icon>(
          find.byIcon(Icons.forum_outlined),
        );

        expect(communityIcon.color, const Color(0xFF94A3B8));
        expect(nearbyIcon.color, const Color(0xFF94A3B8));
        expect(chatsIcon.color, const Color(0xFF94A3B8));

        // Tapping back button returns to Profile tab
        final backButton = find.byTooltip('Back');
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Profile tab should be active again
        expect(find.text('Nethmina Gunasekara'), findsOneWidget);
      },
    );
  });
}
