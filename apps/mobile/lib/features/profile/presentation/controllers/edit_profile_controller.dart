import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/repositories/i_profile_repository.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';

class EditProfileController extends ChangeNotifier {
  final IProfileRepository _profileRepository;
  final IAuthRepository _authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EditProfileController(this._profileRepository, this._authRepository);

  Future<bool> updateName(String newName) async {
    _setLoading(true);
    try {
      await _profileRepository.updateName(newName);
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTagline(String? newTagline) async {
    _setLoading(true);
    try {
      await _profileRepository.updateTagline(newTagline);
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUsername(String? newUsername) async {
    _setLoading(true);
    try {
      await _profileRepository.updateUsername(newUsername);
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReceiveMessages(bool receiveMessages) async {
    _setLoading(true);
    try {
      await _profileRepository.updateReceiveMessages(receiveMessages);
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateLocationAndAddress({
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    _setLoading(true);
    try {
      await _profileRepository.updateLocationAndAddress(
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        homeLatitude: homeLatitude,
        homeLongitude: homeLongitude,
      );
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    try {
      return await _profileRepository.checkUsernameAvailable(username);
    } catch (e) {
      return false; // On network error, assume unavailable to prevent false positives
    }
  }

  Future<bool> updateAvatar(File image) async {
    _setLoading(true);
    try {
      await _profileRepository.updateAvatar(image);
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> sendEmailUpdateCode(String newEmail) async {
    _setLoading(true);
    try {
      final token = await _profileRepository.sendEmailUpdateCode(newEmail);
      return token;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmailUpdateCode(String token, String otpCode) async {
    _setLoading(true);
    try {
      await _profileRepository.verifyEmailUpdateCode(token, otpCode);
      _authRepository.invalidateProfileCache();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _profileRepository.changePassword(oldPassword, newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleRoleVisibility(String roleName, bool isVisible) async {
    _setLoading(true);
    try {
      await _profileRepository.toggleRoleVisibility(roleName, isVisible);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}
