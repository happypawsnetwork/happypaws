import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({required UserProfile user}) {
    final authRepo = _FakeAuthRepository(currentUser: user);
    final profileController = ProfileController(authRepo);

    return MultiProvider(
      providers: [
        Provider<IAuthRepository>.value(value: authRepo),
        ChangeNotifierProvider<ProfileController>.value(
          value: profileController,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            scrollController: ScrollController(),
            topPadding: 0,
          ),
        ),
      ),
    );
  }

  void setTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('Role-specific profile menu items', () {
    testWidgets('does not render Foster Care for user without foster role', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);

      const adopterUser = UserProfile(
        id: 1,
        name: 'Adopter Only',
        email: 'adopter@test.com',
        roles: [UserRole(name: 'Adopter', isVerified: true)],
      );

      await tester.pumpWidget(createTestWidget(user: adopterUser));
      await tester.pumpAndSettle();

      expect(find.text('Foster Care'), findsNothing);
    });

    testWidgets('renders Foster Care for user with foster role', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);

      const fosterUser = UserProfile(
        id: 2,
        name: 'Foster User',
        email: 'foster@test.com',
        roles: [
          UserRole(name: 'Adopter', isVerified: true),
          UserRole(name: 'Foster', isVerified: true),
        ],
      );

      await tester.pumpWidget(createTestWidget(user: fosterUser));
      await tester.pumpAndSettle();

      expect(find.text('Foster Care'), findsOneWidget);
    });

    testWidgets('renders Animal Transports only for transporter role', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);

      const transporterUser = UserProfile(
        id: 3,
        name: 'Transporter User',
        email: 'transporter@test.com',
        roles: [UserRole(name: 'Transporter', isVerified: true)],
      );

      await tester.pumpWidget(createTestWidget(user: transporterUser));
      await tester.pumpAndSettle();

      expect(find.text('Animal Transports'), findsOneWidget);
      expect(find.text('Foster Care'), findsNothing);
    });

    testWidgets('renders Sponsorships only for sponsor role', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);

      const sponsorUser = UserProfile(
        id: 4,
        name: 'Sponsor User',
        email: 'sponsor@test.com',
        roles: [UserRole(name: 'Sponsor', isVerified: true)],
      );

      await tester.pumpWidget(createTestWidget(user: sponsorUser));
      await tester.pumpAndSettle();

      expect(find.text('Sponsorships'), findsOneWidget);
      expect(find.text('Case Reviews'), findsNothing);
    });

    testWidgets('renders Case Reviews only for veterinarian role', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);

      const vetUser = UserProfile(
        id: 5,
        name: 'Vet User',
        email: 'vet@test.com',
        roles: [UserRole(name: 'Veterinarian', isVerified: true)],
      );

      await tester.pumpWidget(createTestWidget(user: vetUser));
      await tester.pumpAndSettle();

      expect(find.text('Case Reviews'), findsOneWidget);
      expect(find.text('Foster Care'), findsNothing);
    });
  });
}
