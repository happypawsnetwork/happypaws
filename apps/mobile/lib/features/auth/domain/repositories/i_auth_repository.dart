import '../../../profile/domain/models/user_profile.dart';
import '../models/auth_models.dart';

abstract interface class IAuthRepository {
  /// Pings the API to check network connectivity and session validity.
  /// Returns `true` if a valid session exists, `false` if unauthenticated.
  /// Throws an exception if the network/API is unreachable.
  Future<bool> checkSessionStatus();

  Future<MobileLoginResponse> login(String email, String password);

  Future<VerificationTokenResponse> sendRegistrationCode(String email);
  Future<void> verifyRegistrationCode({
    required String verificationToken,
    required String otpCode,
  });
  Future<MobileLoginResponse> completeRegistration({
    required String verificationToken,
    required String fullName,
    required String password,
  });

  Future<VerificationTokenResponse> sendForgotPasswordCode(String email);
  Future<void> verifyForgotPasswordCode({
    required String verificationToken,
    required String otpCode,
  });
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
  });

  /// Explicitly logs out the user and revokes tokens
  Future<void> logout();

  /// Retrieves the current user's profile, optionally bypassing the cache
  Future<UserProfile?> getUserProfile({bool forceRefresh = false});

  /// Invalidates the local user profile cache
  void invalidateProfileCache();
}
