import 'package:flutter/material.dart';

import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/user_profile.dart';

class ProfileController extends ChangeNotifier {
  final IAuthRepository _authRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  ProfileController(this._authRepository);

  Future<void> loadProfile({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _authRepository.getUserProfile(
        forceRefresh: forceRefresh,
      );
      if (_userProfile == null) {
        _errorMessage = 'Failed to load profile. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while loading your profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _userProfile = null;
    notifyListeners();
  }
}
