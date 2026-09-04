import 'package:mobile/features/profile/domain/models/user_profile.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/network/api_exceptions.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/auth/presentation/controllers/sign_up_controller.dart';
import 'package:mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/sign_up_email_screen.dart';
import 'package:mobile/features/auth/presentation/screens/sign_up_otp_screen.dart';
import 'package:mobile/features/auth/presentation/screens/sign_up_profile_screen.dart';
import 'package:mobile/features/auth/presentation/screens/registration_success_screen.dart';

class FakeAuthRepository implements IAuthRepository {
  bool shouldThrowUnauthorized = false;
  Completer<MobileLoginResponse>? loginCompleter;

  @override
  Future<bool> checkSessionStatus() async => false;
  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async =>
      null;

  @override
  void invalidateProfileCache() {}

  @override
  Future<MobileLoginResponse> login(String email, String password) async {
    if (loginCompleter != null) {
      return loginCompleter!.future;
    }
    if (shouldThrowUnauthorized) {
      throw UnauthorizedException();
    }
    return const MobileLoginResponse(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 3600,
    );
  }

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async {
    return const VerificationTokenResponse(verificationToken: 'test-token');
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
      accessToken: 'access',
      refreshToken: 'refresh',
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

  Widget createTestWidget(Widget child, [FakeAuthRepository? repo]) {
    final fakeRepo = repo ?? FakeAuthRepository();
    return MultiProvider(
      providers: [
        Provider<IAuthRepository>.value(value: fakeRepo),
        ChangeNotifierProvider(create: (_) => SignUpController(fakeRepo)),
        ChangeNotifierProvider(create: (_) => LoginController(fakeRepo)),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Auth screens render correctly', () {
    testWidgets('renders LoginScreen with inputs and buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Your Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('clears error SnackBar immediately on login retry', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeAuthRepository()..shouldThrowUnauthorized = true;
      await tester.pumpWidget(createTestWidget(const LoginScreen(), fakeRepo));

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid email or password.'), findsOneWidget);

      final completer = Completer<MobileLoginResponse>();
      fakeRepo.loginCompleter = completer;

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.completeError(UnauthorizedException());
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('renders SignUpEmailScreen with image and inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SignUpEmailScreen()));
      expect(find.text("Let's get started"), findsOneWidget);
      expect(find.text('Send Code'), findsOneWidget);
    });

    testWidgets('renders SignUpOtpScreen with image and inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SignUpOtpScreen()));
      expect(find.text('Verify your email address'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
    });

    testWidgets('renders SignUpProfileScreen with image and inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SignUpProfileScreen()));
      expect(find.text('Tell us a bit about yourself'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('renders RegistrationSuccessScreen with image and button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const RegistrationSuccessScreen()),
      );
      expect(find.text("You're all set!"), findsOneWidget);
      expect(find.text('Go to Dashboard'), findsOneWidget);
    });
  });
}
