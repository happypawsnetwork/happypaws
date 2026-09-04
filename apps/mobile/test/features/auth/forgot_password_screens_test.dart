import 'package:mobile/features/profile/domain/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/api_exceptions.dart';
import 'package:mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_email_screen.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_otp_screen.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_new_password_screen.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_success_screen.dart';

class FakeAuthRepository implements IAuthRepository {
  bool sendCodeThrows = false;
  bool verifyCodeThrows401 = false;
  bool verifyCodeThrows429 = false;
  bool resetThrows401 = false;

  @override
  Future<bool> checkSessionStatus() async => false;
  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async =>
      null;

  @override
  void invalidateProfileCache() {}

  @override
  Future<MobileLoginResponse> login(String email, String password) async {
    return MobileLoginResponse(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresIn: 3600,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<MobileLoginResponse> completeRegistration({
    required String verificationToken,
    required String fullName,
    required String password,
  }) async {
    return MobileLoginResponse(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresIn: 3600,
    );
  }

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async {
    return VerificationTokenResponse(verificationToken: 'token');
  }

  @override
  Future<void> verifyRegistrationCode({
    required String verificationToken,
    required String otpCode,
  }) async {}

  @override
  Future<VerificationTokenResponse> sendForgotPasswordCode(String email) async {
    if (sendCodeThrows) throw NetworkException();
    return VerificationTokenResponse(verificationToken: 'test_token');
  }

  @override
  Future<void> verifyForgotPasswordCode({
    required String verificationToken,
    required String otpCode,
  }) async {
    if (verifyCodeThrows401) throw UnauthorizedException();
    if (verifyCodeThrows429) {
      throw RateLimitException('Too many attempts. Try again in 14 minutes.');
    }
  }

  @override
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {
    if (resetThrows401) throw UnauthorizedException();
  }
}

void main() {
  late FakeAuthRepository authRepository;

  setUp(() {
    authRepository = FakeAuthRepository();
  });

  Widget createTestWidget(Widget child) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (context, state) => child),
        GoRoute(
          path: '/forgot-password/otp',
          builder: (context, state) => const Scaffold(body: Text('OTP Screen')),
        ),
        GoRoute(
          path: '/forgot-password/new-password',
          builder: (context, state) =>
              const Scaffold(body: Text('New Password Screen')),
        ),
        GoRoute(
          path: '/forgot-password/success',
          builder: (context, state) =>
              const Scaffold(body: Text('Success Screen')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ForgotPasswordController(authRepository),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ForgotPasswordEmailScreen', () {
    testWidgets('renders correctly and calls controller on Continue tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const ForgotPasswordEmailScreen()),
      );

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(
        find.text('Please enter your email to reset the password.'),
        findsOneWidget,
      );

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('OTP Screen'), findsOneWidget);
    });
  });

  group('ForgotPasswordOtpScreen', () {
    testWidgets('renders and shows error banner on 401', (tester) async {
      authRepository.verifyCodeThrows401 = true;
      final controller = ForgotPasswordController(authRepository);
      controller.email = 'test@example.com';
      controller.verificationToken = 'token';

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const ForgotPasswordOtpScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(find.text('Verify Code'), findsOneWidget);

      final otpFields = find.byType(TextField);
      expect(otpFields, findsNWidgets(6));

      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '$i');
      }

      // Auto-submit should trigger verify
      await tester.pumpAndSettle();

      expect(
        find.text('Incorrect or expired code. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('ForgotPasswordNewPasswordScreen', () {
    testWidgets('validates mismatched passwords before calling API', (
      tester,
    ) async {
      final controller = ForgotPasswordController(authRepository);
      controller.verificationToken = 'token';

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) =>
                const ForgotPasswordNewPasswordScreen(),
          ),
          GoRoute(
            path: '/forgot-password/success',
            builder: (context, state) =>
                const Scaffold(body: Text('Success Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(find.text('Set a new password'), findsOneWidget);

      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsNWidgets(2));

      await tester.enterText(passwordFields.at(0), 'password123');
      await tester.enterText(passwordFields.at(1), 'password1234');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.text('Success Screen'), findsNothing);

      await tester.enterText(passwordFields.at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Success Screen'), findsOneWidget);
    });
  });

  group('ForgotPasswordSuccessScreen', () {
    testWidgets('renders and navigates to login', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ForgotPasswordSuccessScreen()),
      );

      expect(find.text('Password reset successful'), findsOneWidget);

      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
