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
import 'package:mobile/features/profile/presentation/controllers/lifestyle_profile_controller.dart';
import 'package:mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mobile/features/profile/presentation/screens/lifestyle_profile_screen.dart';
import 'package:provider/provider.dart';

class _FakeProfileRepository implements IProfileRepository {
  LifestyleProfile currentProfile = const LifestyleProfile(
    homeSize: 'Apartment',
    hasEnclosedYard: false,
    hasChildren: false,
    activityTempo: 'ModeratelyActive',
    existingPets: [],
  );

  bool updateLifestyleCalled = false;

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
  Future<LifestyleProfile> getLifestyleProfile() async => currentProfile;

  @override
  Future<void> toggleRoleVisibility(String roleName, bool isVisible) async {}

  @override
  Future<LifestyleProfile> updateLifestyleProfile(
    LifestyleProfile profile,
  ) async {
    updateLifestyleCalled = true;
    currentProfile = profile;
    return currentProfile;
  }
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
    required _FakeProfileRepository profileRepo,
  }) {
    final authRepo = _FakeAuthRepository(currentUser: user);
    final profileController = ProfileController(authRepo);
    final editProfileController = EditProfileController(profileRepo, authRepo);
    final lifestyleProfileController = LifestyleProfileController(profileRepo);

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
        ChangeNotifierProvider<LifestyleProfileController>.value(
          value: lifestyleProfileController,
        ),
      ],
      child: const MaterialApp(home: LifestyleProfileScreen()),
    );
  }

  final testUser = const UserProfile(
    id: 1,
    name: 'Adopter User',
    email: 'adopter@example.com',
    roles: [],
    username: 'adopter_hero',
  );

  testWidgets(
    'renders patterned header, user name, lifestyle badge, and new sections',
    (tester) async {
      final profileRepo = _FakeProfileRepository();

      await tester.pumpWidget(
        createTestWidget(user: testUser, profileRepo: profileRepo),
      );
      await tester.pumpAndSettle();

      // Header content
      expect(find.text('Adopter User'), findsOneWidget);
      expect(find.text('@adopter_hero'), findsOneWidget);
      expect(find.text('Lifestyle profile'), findsOneWidget);

      // New section headings
      expect(find.text('Home size & space'), findsOneWidget);
      expect(find.text('Outdoor environment'), findsOneWidget);
      expect(find.text('Household members'), findsOneWidget);
      expect(find.text('Household activity tempo'), findsOneWidget);
      expect(find.text('Existing pets in household'), findsOneWidget);

      // Save button
      expect(find.text('Save lifestyle profile'), findsOneWidget);
    },
  );

  testWidgets('loading profile and saving calls the repository', (
    tester,
  ) async {
    final profileRepo = _FakeProfileRepository();

    await tester.pumpWidget(
      createTestWidget(user: testUser, profileRepo: profileRepo),
    );
    await tester.pumpAndSettle();

    // Scroll to and tap the save button without making changes.
    // This verifies the save pathway works end-to-end.
    final saveButton = find.text('Save lifestyle profile');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(profileRepo.updateLifestyleCalled, isTrue);
    // The loaded profile has homeSize 'Apartment', verify it is preserved.
    expect(profileRepo.currentProfile.homeSize, equals('Apartment'));
    expect(find.text('Lifestyle profile updated'), findsOneWidget);
  });

  testWidgets(
    'tapping add animal opens modal and selecting an animal adds it instantly',
    (tester) async {
      final profileRepo = _FakeProfileRepository();
      profileRepo.currentProfile = const LifestyleProfile(
        homeSize: 'Apartment',
        hasEnclosedYard: false,
        hasChildren: false,
        activityTempo: 'ModeratelyActive',
        existingPets: ['Cat'],
      );

      await tester.pumpWidget(
        createTestWidget(user: testUser, profileRepo: profileRepo),
      );
      await tester.pumpAndSettle();

      // Verify existing pet Cat and Add animal button with paw icon are visible
      expect(find.text('Cat'), findsOneWidget);
      final addAnimalButton = find.text('Add animal');
      expect(addAnimalButton, findsOneWidget);
      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);

      // Tap Add animal button to open modal bottom sheet
      await tester.ensureVisible(addAnimalButton);
      await tester.tap(addAnimalButton);
      await tester.pumpAndSettle();

      // Verify modal is open with title and animal suggestions
      expect(find.text('Popular animal types'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Bird'), findsOneWidget);

      // Tap Bird to select it
      await tester.tap(find.text('Bird'));
      await tester.pumpAndSettle();

      // Verify modal is closed and both Cat and Bird are in the lifestyle profile screen
      expect(find.text('Popular animal types'), findsNothing);
      expect(find.text('Cat'), findsOneWidget);
      expect(find.text('Bird'), findsOneWidget);
    },
  );

  testWidgets(
    'adding a custom unlisted animal adds it instantly and closes modal',
    (tester) async {
      final profileRepo = _FakeProfileRepository();
      profileRepo.currentProfile = const LifestyleProfile(
        homeSize: 'Apartment',
        hasEnclosedYard: false,
        hasChildren: false,
        activityTempo: 'ModeratelyActive',
        existingPets: [],
      );

      await tester.pumpWidget(
        createTestWidget(user: testUser, profileRepo: profileRepo),
      );
      await tester.pumpAndSettle();

      // Tap Add animal button
      final addAnimalButton = find.text('Add animal');
      await tester.ensureVisible(addAnimalButton);
      await tester.tap(addAnimalButton);
      await tester.pumpAndSettle();

      // Enter custom unlisted animal
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Ferret');
      await tester.pumpAndSettle();

      // Tap Add button
      final addButton = find.text('Add');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify modal is closed and Ferret is added to the screen
      expect(find.text('Popular animal types'), findsNothing);
      expect(find.text('Ferret'), findsOneWidget);
    },
  );

  testWidgets('deleting a pet chip removes it from the list', (tester) async {
    final profileRepo = _FakeProfileRepository();
    profileRepo.currentProfile = const LifestyleProfile(
      homeSize: 'Apartment',
      hasEnclosedYard: false,
      hasChildren: false,
      activityTempo: 'ModeratelyActive',
      existingPets: ['Cat', 'Dog'],
    );

    await tester.pumpWidget(
      createTestWidget(user: testUser, profileRepo: profileRepo),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);

    // Tap delete icon on Cat chip
    final deleteIcons = find.byIcon(Icons.close);
    expect(deleteIcons, findsNWidgets(2));
    await tester.ensureVisible(deleteIcons.first);
    await tester.tap(deleteIcons.first);
    await tester.pumpAndSettle();

    expect(find.text('Cat'), findsNothing);
    expect(find.text('Dog'), findsOneWidget);
  });
}
