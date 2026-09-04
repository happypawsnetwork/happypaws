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
import 'package:mobile/features/profile/presentation/widgets/edit_address_dialog.dart';
import 'package:provider/provider.dart';

class _FakeProfileRepository implements IProfileRepository {
  String? lastAddressLine1;
  String? lastCity;
  String? lastState;
  String? lastCountry;

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  @override
  Future<bool> checkUsernameAvailable(String username) async => true;

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
  Future<LifestyleProfile> getLifestyleProfile() async =>
      const LifestyleProfile();

  @override
  Future<String> sendEmailUpdateCode(String newEmail) async => 'token';

  @override
  Future<void> toggleRoleVisibility(String roleName, bool isVisible) async {}

  @override
  Future<String> updateAvatar(File image) async => 'https://example.com/a.png';

  @override
  Future<LifestyleProfile> updateLifestyleProfile(
    LifestyleProfile profile,
  ) async => profile;

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
  }) async {
    lastAddressLine1 = addressLine1;
    lastCity = city;
    lastState = state;
    lastCountry = country;
  }

  @override
  Future<void> updateName(String name) async {}

  @override
  Future<void> updateReceiveMessages(bool receiveMessages) async {}

  @override
  Future<void> updateTagline(String? tagline) async {}

  @override
  Future<void> updateUsername(String? username) async {}

  @override
  Future<void> verifyEmailUpdateCode(String token, String otpCode) async {}
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
  Future<void> logout() async {}

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
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {}

  @override
  Future<VerificationTokenResponse> sendForgotPasswordCode(
    String email,
  ) async => const VerificationTokenResponse(verificationToken: 'token');

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async =>
      const VerificationTokenResponse(verificationToken: 'token');

  @override
  Future<void> verifyForgotPasswordCode({
    required String verificationToken,
    required String otpCode,
  }) async {}

  @override
  Future<void> verifyRegistrationCode({
    required String verificationToken,
    required String otpCode,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    UserProfile? user,
    required _FakeProfileRepository profileRepo,
  }) {
    final authRepo = _FakeAuthRepository(currentUser: user);
    final profileController = ProfileController(authRepo);
    final editController = EditProfileController(profileRepo, authRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profileController),
        ChangeNotifierProvider.value(value: editController),
      ],
      child: MaterialApp(
        home: Scaffold(body: EditAddressDialog(currentUser: user)),
      ),
    );
  }

  testWidgets('renders country uneditable as Sri Lanka', (
    WidgetTester tester,
  ) async {
    final repo = _FakeProfileRepository();
    await tester.pumpWidget(createTestWidget(profileRepo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Sri Lanka'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('city dropdown is disabled when no province is selected', (
    WidgetTester tester,
  ) async {
    final repo = _FakeProfileRepository();
    await tester.pumpWidget(createTestWidget(profileRepo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Select province first'), findsOneWidget);
  });

  testWidgets(
    'save button is disabled until address line 1, province, and city are filled',
    (WidgetTester tester) async {
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(createTestWidget(profileRepo: repo));
      await tester.pumpAndSettle();

      final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Save');
      expect(saveButtonFinder, findsOneWidget);

      // Initially disabled
      ElevatedButton saveBtn = tester.widget<ElevatedButton>(saveButtonFinder);
      expect(saveBtn.onPressed, isNull);

      // Enter address line 1
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address Line 1 *'),
        '42 Marine Drive',
      );
      await tester.pumpAndSettle();

      // Still disabled because province and city are missing
      saveBtn = tester.widget<ElevatedButton>(saveButtonFinder);
      expect(saveBtn.onPressed, isNull);

      // Select province
      await tester.tap(find.text('Select province'));
      await tester.pumpAndSettle();

      expect(find.text('Central'), findsOneWidget);
      await tester.tap(find.text('Central'));
      await tester.pumpAndSettle();

      // Still disabled because city is missing
      saveBtn = tester.widget<ElevatedButton>(saveButtonFinder);
      expect(saveBtn.onPressed, isNull);

      // Select city
      await tester.tap(find.text('Select city'));
      await tester.pumpAndSettle();

      expect(find.text('Kandy'), findsOneWidget);
      await tester.tap(find.text('Kandy'));
      await tester.pumpAndSettle();

      // Now all 3 required fields are set -> Save button is enabled!
      saveBtn = tester.widget<ElevatedButton>(saveButtonFinder);
      expect(saveBtn.onPressed, isNotNull);

      // Tap Save
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(repo.lastAddressLine1, equals('42 Marine Drive'));
      expect(repo.lastState, equals('Central'));
      expect(repo.lastCity, equals('Kandy'));
      expect(repo.lastCountry, equals('Sri Lanka'));
    },
  );

  testWidgets('changing province resets the selected city', (
    WidgetTester tester,
  ) async {
    final repo = _FakeProfileRepository();
    const initialUser = UserProfile(
      id: 1,
      email: 'a@b.com',
      name: 'User',
      roles: [],
      addressLine1: '42 Marine Drive',
      state: 'Western',
      city: 'Colombo',
      country: 'Sri Lanka',
    );

    await tester.pumpWidget(
      createTestWidget(user: initialUser, profileRepo: repo),
    );
    await tester.pumpAndSettle();

    // Check pre-populated values
    expect(find.text('Western'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);

    // Change province to Central
    await tester.tap(find.text('Western'));
    await tester.pumpAndSettle();

    expect(find.text('Central'), findsOneWidget);
    await tester.tap(find.text('Central'));
    await tester.pumpAndSettle();

    // Province changed -> city must have reset to "Select city"!
    expect(find.text('Central'), findsOneWidget);
    expect(find.text('Select city'), findsOneWidget);
    expect(find.text('Colombo'), findsNothing);

    // Save button must now be disabled because city is reset
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('search box in dropdown sheet filters items', (
    WidgetTester tester,
  ) async {
    final repo = _FakeProfileRepository();
    await tester.pumpWidget(createTestWidget(profileRepo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select province'));
    await tester.pumpAndSettle();

    // Type 'west' in the search field
    await tester.enterText(find.widgetWithText(TextField, 'Search...'), 'west');
    await tester.pumpAndSettle();

    expect(find.text('Western'), findsOneWidget);
    expect(find.text('Central'), findsNothing);

    await tester.tap(find.text('Western'));
    await tester.pumpAndSettle();

    expect(find.text('Western'), findsOneWidget);
  });
}
