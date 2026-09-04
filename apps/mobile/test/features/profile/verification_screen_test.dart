import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mobile/features/profile/presentation/screens/verification_screen.dart';
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

  testWidgets(
    'renders VerificationScreen with title, back button, and content',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VerificationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Get Verified'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      // Verify Scaffold has white background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Verify verified badge icon is rendered
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // Verify key content sections
      expect(find.text('Identity verification'), findsOneWidget);
      expect(find.text('What you need'), findsOneWidget);
      expect(find.text('Start verification'), findsOneWidget);
    },
  );

  testWidgets('back button pops the current route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const VerificationScreen(),
                    ),
                  );
                },
                child: const Text('Open verification'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();
    expect(find.text('Identity verification'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Identity verification'), findsNothing);
    expect(find.text('Open verification'), findsOneWidget);
  });

  group('VerificationScreen address prompt flow', () {
    Widget buildRouterApp({required UserProfile user}) {
      final authRepo = _FakeAuthRepository(currentUser: user);
      final profileController = ProfileController(authRepo);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const VerificationScreen(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) {
              final openAddress =
                  state.uri.queryParameters['openAddress'] == 'true';
              return Scaffold(
                body: Text('Edit Profile Screen (openAddress: $openAddress)'),
              );
            },
          ),
          GoRoute(
            path: '/verification/role-select',
            builder: (context, state) =>
                const Scaffold(body: Text('Role Selection Screen')),
          ),
        ],
      );

      return ChangeNotifierProvider<ProfileController>.value(
        value: profileController,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'shows address required dialog when home address is incomplete, and cancel dismisses it',
      (WidgetTester tester) async {
        const incompleteUser = UserProfile(
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          roles: [],
          addressLine1: '123 Galle Road',
          city: null, // missing city and province
          state: null,
        );

        await tester.pumpWidget(buildRouterApp(user: incompleteUser));
        await tester.pumpAndSettle();

        // Tap "Start verification"
        await tester.ensureVisible(find.text('Start verification'));
        await tester.tap(find.text('Start verification'));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.text('Home address required'), findsOneWidget);
        expect(
          find.text(
            'Please enter your home address, province, and city before starting identity verification.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Go to settings'), findsOneWidget);

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog dismissed, still on verification screen
        expect(find.text('Home address required'), findsNothing);
        expect(find.text('Identity verification'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Go to settings navigates to edit profile with openAddress=true',
      (WidgetTester tester) async {
        const noAddressUser = UserProfile(
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          roles: [],
        );

        await tester.pumpWidget(buildRouterApp(user: noAddressUser));
        await tester.pumpAndSettle();

        // Tap "Start verification"
        await tester.ensureVisible(find.text('Start verification'));
        await tester.tap(find.text('Start verification'));
        await tester.pumpAndSettle();

        expect(find.text('Home address required'), findsOneWidget);

        // Tap "Go to settings"
        await tester.tap(find.text('Go to settings'));
        await tester.pumpAndSettle();

        // Navigated to edit profile with openAddress: true
        expect(
          find.text('Edit Profile Screen (openAddress: true)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'navigates directly to role-select when home address is complete',
      (WidgetTester tester) async {
        const completeUser = UserProfile(
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          roles: [],
          addressLine1: '123 Galle Road',
          city: 'Colombo',
          state: 'Western',
        );

        await tester.pumpWidget(buildRouterApp(user: completeUser));
        await tester.pumpAndSettle();

        // Tap "Start verification"
        await tester.ensureVisible(find.text('Start verification'));
        await tester.tap(find.text('Start verification'));
        await tester.pumpAndSettle();

        // Direct navigation to role select, no dialog
        expect(find.text('Home address required'), findsNothing);
        expect(find.text('Role Selection Screen'), findsOneWidget);
      },
    );
  });
}
