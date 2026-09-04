import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/profile/domain/models/lifestyle_profile.dart';
import 'package:mobile/features/profile/domain/models/public_user_profile.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:mobile/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:mobile/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class _FakeProfileRepository implements IProfileRepository {
  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  @override
  Future<bool> checkUsernameAvailable(String username) async => true;

  @override
  Future<String> sendEmailUpdateCode(String newEmail) async => 'token';

  @override
  Future<String> updateAvatar(File image) async =>
      'https://example.com/avatar.png';

  @override
  Future<void> updateName(String name) async {}

  @override
  Future<void> updateTagline(String? tagline) async {}

  @override
  Future<void> updateUsername(String? username) async {}

  @override
  Future<void> updateReceiveMessages(bool receiveMessages) async {}

  @override
  Future<void> updateLocationAndAddress({
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? homeLatitude,
    double? homeLongitude,
  }) async {}

  @override
  Future<PublicUserProfile> getPublicProfile(int userId) async =>
      PublicUserProfile(
        id: userId,
        fullName: 'Test User',
        reputationPoints: 10,
        roles: [],
        createdAt: DateTime.now(),
        posts: [],
      );

  @override
  Future<void> verifyEmailUpdateCode(String token, String otpCode) async {}

  @override
  Future<LifestyleProfile> getLifestyleProfile() async =>
      const LifestyleProfile();

  @override
  Future<LifestyleProfile> updateLifestyleProfile(
    LifestyleProfile profile,
  ) async => profile;

  @override
  Future<void> toggleRoleVisibility(String roleName, bool isVisible) async {}
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required UserProfile user,
    bool openAddressOnMount = false,
  }) {
    final profileRepo = _FakeProfileRepository();
    final authRepo = _FakeAuthRepository(currentUser: user);
    final profileController = ProfileController(authRepo);
    final editProfileController = EditProfileController(profileRepo, authRepo);

    return MultiProvider(
      providers: [
        Provider<IProfileRepository>.value(value: profileRepo),
        Provider<IAuthRepository>.value(value: authRepo),
        ChangeNotifierProvider<ProfileController>.value(
          value: profileController,
        ),
        ChangeNotifierProvider<EditProfileController>.value(
          value: editProfileController,
        ),
      ],
      child: MaterialApp(
        home: EditProfileScreen(openAddressOnMount: openAddressOnMount),
      ),
    );
  }

  group('EditProfileScreen avatar picker tests', () {
    const testUser = UserProfile(
      id: 1,
      name: 'Adopter User',
      email: 'adopter@example.com',
      username: 'adopter123',
      roles: [UserRole(name: 'Adopter', isVerified: false)],
    );

    testWidgets(
      'tapping avatar camera button opens image source picker bottom sheet',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(user: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Adopter User'), findsNWidgets(2));

        final cameraButton = find.byIcon(Icons.camera_alt_rounded);
        expect(cameraButton, findsOneWidget);

        await tester.tap(cameraButton);
        await tester.pumpAndSettle();

        expect(find.text('Change profile picture'), findsOneWidget);
        expect(find.text('Take photo'), findsOneWidget);
        expect(find.text('Choose from gallery'), findsOneWidget);
      },
    );

    testWidgets(
      'auto-opens Edit Address dialog on mount when openAddressOnMount is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(user: testUser, openAddressOnMount: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Address'), findsOneWidget);
        expect(find.text('Country'), findsOneWidget);
        expect(find.text('Sri Lanka'), findsOneWidget);
        expect(find.text('Province *'), findsOneWidget);
        expect(find.text('City *'), findsOneWidget);
      },
    );

    testWidgets('tapping Home Address row opens Edit Address dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(user: testUser, openAddressOnMount: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Address'), findsNothing);

      await tester.ensureVisible(find.text('Home Address'));
      await tester.tap(find.text('Home Address'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Address'), findsOneWidget);
      expect(find.text('Sri Lanka'), findsOneWidget);
    });
  });
}
