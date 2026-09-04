import 'dart:io';

import '../models/lifestyle_profile.dart';
import '../models/public_user_profile.dart';

abstract class IProfileRepository {
  Future<void> updateName(String name);
  Future<void> updateTagline(String? tagline);
  Future<void> updateUsername(String? username);
  Future<void> updateReceiveMessages(bool receiveMessages);
  Future<void> updateLocationAndAddress({
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? homeLatitude,
    double? homeLongitude,
  });
  Future<bool> checkUsernameAvailable(String username);
  Future<String> updateAvatar(File image);
  Future<String> sendEmailUpdateCode(String newEmail);
  Future<void> verifyEmailUpdateCode(String token, String otpCode);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<LifestyleProfile> getLifestyleProfile();
  Future<LifestyleProfile> updateLifestyleProfile(LifestyleProfile profile);
  Future<void> toggleRoleVisibility(String roleName, bool isVisible);
  Future<PublicUserProfile> getPublicProfile(int userId);
}
