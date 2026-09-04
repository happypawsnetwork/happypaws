import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../domain/models/lifestyle_profile.dart';
import '../domain/models/public_user_profile.dart';
import '../domain/repositories/i_profile_repository.dart';

class ProfileRepository implements IProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  @override
  Future<void> updateName(String name) async {
    await _apiClient.put('/api/profile', body: {'name': name});
  }

  @override
  Future<void> updateTagline(String? tagline) async {
    await _apiClient.put('/api/profile/tagline', body: {'tagline': tagline});
  }

  @override
  Future<void> updateUsername(String? username) async {
    await _apiClient.put('/api/profile', body: {'username': username});
  }

  @override
  Future<void> updateReceiveMessages(bool receiveMessages) async {
    await _apiClient.put(
      '/api/profile',
      body: {'receiveMessages': receiveMessages},
    );
  }

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
    await _apiClient.put(
      '/api/profile',
      body: {
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
        'homeLatitude': homeLatitude,
        'homeLongitude': homeLongitude,
      },
    );
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    final response = await _apiClient.get(
      '/api/profile/check-username?username=$username',
    );
    return response as bool;
  }

  @override
  Future<String> updateAvatar(File image) async {
    final response = await _apiClient.multipart(
      '/api/profile/avatar',
      files: [image],
      fieldName: 'file',
    );
    return response['avatarUrl'] as String;
  }

  @override
  Future<String> sendEmailUpdateCode(String newEmail) async {
    final response = await _apiClient.post(
      '/api/profile/email/send-code',
      body: {'newEmail': newEmail},
    );
    return response['verificationToken'] as String;
  }

  @override
  Future<void> verifyEmailUpdateCode(String token, String otpCode) async {
    await _apiClient.post(
      '/api/profile/email/verify-code',
      body: {'verificationToken': token, 'otpCode': otpCode},
    );
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiClient.post(
      '/api/profile/password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<LifestyleProfile> getLifestyleProfile() async {
    final response = await _apiClient.get('/api/profile/lifestyle');
    return LifestyleProfile.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<LifestyleProfile> updateLifestyleProfile(
    LifestyleProfile profile,
  ) async {
    final response = await _apiClient.put(
      '/api/profile/lifestyle',
      body: profile.toJson(),
    );
    return LifestyleProfile.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> toggleRoleVisibility(String roleName, bool isVisible) async {
    await _apiClient.put(
      '/api/profile/roles/visibility',
      body: {'roleName': roleName, 'isVisible': isVisible},
    );
  }

  @override
  Future<PublicUserProfile> getPublicProfile(int userId) async {
    final response = await _apiClient.get('/api/profile/public/$userId');
    return PublicUserProfile.fromJson(response as Map<String, dynamic>);
  }
}
