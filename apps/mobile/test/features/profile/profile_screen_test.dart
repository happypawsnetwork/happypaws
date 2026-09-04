import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_colors.dart';
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

  group('ProfileScreen tests', () {
    const testUser = UserProfile(
      id: 1,
      name: 'Nethmina Gunasekara',
      email: 'nethmina@example.com',
      tagline: 'Animal rescuer',
      roles: [UserRole(name: 'Volunteer', isVerified: false)],
    );

    testWidgets('renders profile header without edit icon button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(user: testUser));
      await tester.pumpAndSettle();

      expect(find.text('Nethmina Gunasekara'), findsOneWidget);
      expect(find.text('"Animal rescuer"'), findsOneWidget);

      // Verify no edit icon inside the profile header
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('renders profile header with paw pattern background image', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(user: testUser));
      await tester.pumpAndSettle();

      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image ==
                const AssetImage('assets/images/pattern_pet_paws.jpg'),
      );
      expect(imageFinder, findsOneWidget);

      final opacityFinder = find.ancestor(
        of: imageFinder,
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, equals(0.24));
    });

    testWidgets(
      'renders My Profile list tile above Notifications with accent color and light variant bg',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(user: testUser));
        await tester.pumpAndSettle();

        final myProfileFinder = find.widgetWithText(ListTile, 'My Profile');
        final notificationsFinder = find.widgetWithText(
          ListTile,
          'Notifications',
        );

        expect(myProfileFinder, findsOneWidget);
        expect(notificationsFinder, findsOneWidget);

        // Verify My Profile is positioned above Notifications vertically
        final myProfileOffset = tester.getTopLeft(myProfileFinder);
        final notificationsOffset = tester.getTopLeft(notificationsFinder);
        expect(myProfileOffset.dy, lessThan(notificationsOffset.dy));

        // Verify icon is person_rounded and uses accent color
        final personIconFinder = find.byIcon(Icons.person_rounded);
        expect(personIconFinder, findsWidgets);

        final iconWidget = tester.widget<Icon>(
          find.descendant(
            of: myProfileFinder,
            matching: find.byIcon(Icons.person_rounded),
          ),
        );
        expect(iconWidget.color, equals(AppColors.accent));

        // Verify container background is light variant of accent color
        final containerFinder = find.descendant(
          of: myProfileFinder,
          matching: find.byType(Container),
        );
        final containerWidget = tester.widget<Container>(containerFinder.first);
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(
          decoration.color,
          equals(AppColors.accent.withValues(alpha: 0.1)),
        );
      },
    );

    testWidgets(
      'renders Get Verified menu item below My Profile and above Notifications with blue icon and low opacity bg',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(user: testUser));
        await tester.pumpAndSettle();

        final myProfileFinder = find.widgetWithText(ListTile, 'My Profile');
        final getVerifiedFinder = find.widgetWithText(ListTile, 'Get Verified');
        final notificationsFinder = find.widgetWithText(
          ListTile,
          'Notifications',
        );

        expect(myProfileFinder, findsOneWidget);
        expect(getVerifiedFinder, findsOneWidget);
        expect(notificationsFinder, findsOneWidget);

        // Verify vertical order: My Profile < Get Verified < Notifications
        final myProfileDy = tester.getTopLeft(myProfileFinder).dy;
        final getVerifiedDy = tester.getTopLeft(getVerifiedFinder).dy;
        final notificationsDy = tester.getTopLeft(notificationsFinder).dy;

        expect(myProfileDy, lessThan(getVerifiedDy));
        expect(getVerifiedDy, lessThan(notificationsDy));

        // Verify icon is verified_rounded and has blue color
        const expectedBlue = Color(0xFF0064E0);
        final iconWidget = tester.widget<Icon>(
          find.descendant(
            of: getVerifiedFinder,
            matching: find.byIcon(Icons.verified_rounded),
          ),
        );
        expect(iconWidget.color, equals(expectedBlue));

        // Verify icon bg is low-opacity rounded square
        final containerFinder = find.descendant(
          of: getVerifiedFinder,
          matching: find.byType(Container),
        );
        final containerWidget = tester.widget<Container>(containerFinder.first);
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.color, equals(expectedBlue.withValues(alpha: 0.1)));
        expect(decoration.borderRadius, equals(BorderRadius.circular(10)));
      },
    );
    testWidgets('renders avatar with a ring in accent color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(user: testUser));
      await tester.pumpAndSettle();

      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsOneWidget);

      final ringContainerFinder = find.ancestor(
        of: avatarFinder,
        matching: find.byType(Container),
      );
      expect(ringContainerFinder, findsWidgets);

      final ringWidget = tester.widget<Container>(ringContainerFinder.first);
      final decoration = ringWidget.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.color, equals(AppColors.accent));
    });
  });
}
