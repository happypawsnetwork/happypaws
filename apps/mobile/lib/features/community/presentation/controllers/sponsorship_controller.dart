import 'package:flutter/material.dart';

import '../../domain/repositories/i_sponsorship_repository.dart';

enum SponsorshipState { idle, loading, success, error }

class SponsorshipController extends ChangeNotifier {
  final ISponsorshipRepository _repository;

  SponsorshipState _state = SponsorshipState.idle;
  SponsorshipState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SponsorshipController(this._repository);

  Future<void> createSponsorship(Map<String, dynamic> data) async {
    _state = SponsorshipState.loading;
    notifyListeners();
    try {
      await _repository.createSponsorship(data);
      _state = SponsorshipState.success;
    } catch (e) {
      _state = SponsorshipState.error;
      _errorMessage = 'Failed to create sponsorship post';
    }
    notifyListeners();
  }
}
