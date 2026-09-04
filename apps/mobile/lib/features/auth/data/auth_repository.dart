import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/storage/secure_token_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../profile/domain/models/user_profile.dart';
import '../domain/models/auth_models.dart';
import '../domain/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final ApiClient _apiClient;
  final SecureTokenService _tokenService;
  final _log = AppLogger('AuthRepository');

  UserProfile? _cachedProfile;

  AuthRepository(this._apiClient, this._tokenService);

  @override
  Future<bool> checkSessionStatus() async {
    _log.info('Checking session status and API connectivity...');
    try {
      await _apiClient.get('/api/auth/me');
      _log.info('Session is valid');
      return true;
    } on UnauthorizedException {
      _log.info('No valid session found (Unauthenticated)');
      return false;
    }
    // NetworkException and other exceptions will bubble up naturally
  }

  @override
  Future<MobileLoginResponse> login(String email, String password) async {
    _log.info('Attempting login for $email');
    final response = await _apiClient.post(
      '/api/auth/mobile/login',
      body: {
        'email': email,
        'password': password,
        'fcmToken':
            '', // Can be updated when push notifications are implemented
        'deviceType':
            1, // 0 = Unknown, 1 = Android, 2 = iOS (assuming 1 for now)
      },
    );

    final loginResponse = MobileLoginResponse.fromJson(response);
    await _tokenService.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );

    _log.info('Login successful, tokens saved');
    return loginResponse;
  }

  @override
  Future<VerificationTokenResponse> sendRegistrationCode(String email) async {
    _log.info('Sending registration code to $email');
    final response = await _apiClient.post(
      '/api/auth/register/send-code',
      body: {'email': email},
    );
    _log.info('Successfully received verification token for $email');
    return VerificationTokenResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> verifyRegistrationCode({
    required String verificationToken,
    required String otpCode,
  }) async {
    _log.info('Verifying OTP code...');
    await _apiClient.post(
      '/api/auth/register/verify-code',
      body: {'verificationToken': verificationToken, 'otpCode': otpCode},
    );
    _log.info('OTP verification successful');
  }

  @override
  Future<MobileLoginResponse> completeRegistration({
    required String verificationToken,
    required String fullName,
    required String password,
  }) async {
    _log.info('Completing registration for user: $fullName');
    final response = await _apiClient.post(
      '/api/auth/register/complete',
      body: {
        'verificationToken': verificationToken,
        'fullName': fullName,
        'password': password,
        'deviceType': 0, // 0 = Android based on typical enums, or leave null. The backend allows null.
      },
    );

    final data = MobileLoginResponse.fromJson(response as Map<String, dynamic>);

    _log.info('Registration complete. Saving tokens to secure storage.');
    await _tokenService.saveTokens(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
    );

    return data;
  }

  @override
  Future<VerificationTokenResponse> sendForgotPasswordCode(String email) async {
    _log.info('Sending forgot password code to $email');
    final response = await _apiClient.post(
      '/api/auth/password/forgot/send-code',
      body: {'email': email},
    );
    _log.info(
      'Successfully received verification token for forgot password $email',
    );
    return VerificationTokenResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> verifyForgotPasswordCode({
    required String verificationToken,
    required String otpCode,
  }) async {
    _log.info('Verifying forgot password OTP code...');
    await _apiClient.post(
      '/api/auth/password/forgot/verify-code',
      body: {'verificationToken': verificationToken, 'otpCode': otpCode},
    );
    _log.info('Forgot password OTP verification successful');
  }

  @override
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  }) async {
    _log.info('Resetting password...');
    await _apiClient.post(
      '/api/auth/password/forgot/reset',
      body: {
        'verificationToken': verificationToken,
        'newPassword': newPassword,
      },
    );
    _log.info('Password reset successful');
  }

  @override
  Future<void> logout() async {
    _log.info('Logging out user, revoking tokens');
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          '/api/auth/revoke',
          body: {'refreshToken': refreshToken},
        );
        _log.debug('Tokens revoked successfully on backend');
      }
    } catch (e, st) {
      _log.warning('Failed to revoke tokens on backend during logout', e, st);
    }
    await _tokenService.clearTokens();
    invalidateProfileCache();
    _log.info('Local tokens cleared');
  }

  @override
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) {
      _log.debug('Returning cached user profile');
      return _cachedProfile;
    }

    _log.info('Fetching user profile from /api/auth/me');
    try {
      final response = await _apiClient.get('/api/auth/me');
      _cachedProfile = UserProfile.fromJson(response as Map<String, dynamic>);
      return _cachedProfile;
    } catch (e, st) {
      _log.error('Failed to fetch user profile', e, st);
      return null;
    }
  }

  @override
  void invalidateProfileCache() {
    _log.debug('Invalidating user profile cache');
    _cachedProfile = null;
  }
}
