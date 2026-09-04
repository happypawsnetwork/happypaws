import 'package:flutter/material.dart';

import '../../domain/models/lifestyle_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';

/// Manages lifestyle preference state and synchronizes choices with the remote profile endpoints.
class LifestyleProfileController extends ChangeNotifier {
  final IProfileRepository _profileRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LifestyleProfile? _profile;
  LifestyleProfile? get profile => _profile;

  LifestyleProfileController(this._profileRepository);

  /// Retrieves the current lifestyle profile from the backend.
  Future<void> loadLifestyleProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileRepository.getLifestyleProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends the updated lifestyle configuration to the API.
  Future<bool> saveLifestyleProfile(LifestyleProfile updatedProfile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileRepository.updateLifestyleProfile(
        updatedProfile,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
