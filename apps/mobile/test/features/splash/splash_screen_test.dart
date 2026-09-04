import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';
import 'package:mobile/features/splash/presentation/widgets/animated_splash_logo.dart';
import 'package:mobile/features/splash/presentation/widgets/connection_error_bottom_sheet.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/core/network/api_exceptions.dart';

class FakeAuthRepository implements IAuthRepository {
  bool isOnline = true;
  bool isAuthenticated = false;

  @override
  Future<bool> checkSessionStatus() async {
    if (!isOnline) {
      throw NetworkException();
    }
    return isAuthenticated;
  }

  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async =>
      null;

  @override
  void invalidateProfileCache() {}

  @override
  Future<MobileLoginResponse> login(String email, String password) async {
    if (!isOnline) throw NetworkException();
    if (email == 'admin@happypawsnetwork.com') throw ForbiddenException();
    if (password != 'password') throw UnauthorizedException();
    isAuthenticated = true;
    return const MobileLoginResponse(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 3600,
    );
  }

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async {
    return const VerificationTokenResponse(verificationToken: 'test');
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
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 3600,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<VerificationTokenResponse> sendForgotPasswordCode(String email) async {
    return const VerificationTokenResponse(verificationToken: 'test-token');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget(
    FakeAuthRepository fakeRepo, {
    VoidCallback? onAuth,
    VoidCallback? onUnauth,
  }) {
    return MultiProvider(
      providers: [Provider<IAuthRepository>.value(value: fakeRepo)],
      child: MaterialApp(
        home: SplashScreen(
          onAuthenticated: onAuth ?? () {},
          onUnauthenticated: onUnauth ?? () {},
        ),
      ),
    );
  }

  group('SplashScreen tests', () {
    testWidgets('renders splash screen and transitions when unauthenticated', (
      WidgetTester tester,
    ) async {
      final repo = FakeAuthRepository()
        ..isOnline = true
        ..isAuthenticated = false;
      bool navigated = false;

      await tester.pumpWidget(
        createTestWidget(
          repo,
          onUnauth: () {
            navigated = true;
          },
        ),
      );

      expect(find.byType(AnimatedSplashLogo), findsOneWidget);
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
    });

    testWidgets('renders splash screen and transitions when authenticated', (
      WidgetTester tester,
    ) async {
      final repo = FakeAuthRepository()
        ..isOnline = true
        ..isAuthenticated = true;
      bool navigated = false;

      await tester.pumpWidget(
        createTestWidget(
          repo,
          onAuth: () {
            navigated = true;
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(navigated, isTrue);
    });

    testWidgets('shows connection error bottom sheet on network failure', (
      WidgetTester tester,
    ) async {
      final repo = FakeAuthRepository()..isOnline = false;

      await tester.pumpWidget(createTestWidget(repo));
      await tester.pumpAndSettle();

      expect(find.byType(ConnectionErrorBottomSheet), findsOneWidget);
      expect(find.text('Back to saving pets soon'), findsOneWidget);
    });
  });
}
