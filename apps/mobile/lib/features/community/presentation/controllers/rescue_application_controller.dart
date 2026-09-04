import 'package:flutter/material.dart';

import '../../domain/repositories/i_rescue_application_repository.dart';
import '../../domain/models/rescue_application.dart';

enum RescueApplicationState { idle, loading, success, error }

class RescueApplicationController extends ChangeNotifier {
  final IRescueApplicationRepository _repository;

  RescueApplicationState _state = RescueApplicationState.idle;
  RescueApplicationState get state => _state;

  List<RescueApplication> _applicants = [];
  List<RescueApplication> get applicants => _applicants;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RescueApplicationController(this._repository);

  Future<void> submitApplication(
    String postId,
    Map<String, dynamic> data,
  ) async {
    _state = RescueApplicationState.loading;
    notifyListeners();
    try {
      await _repository.submitApplication(postId, data);
      _state = RescueApplicationState.success;
    } catch (e) {
      _state = RescueApplicationState.error;
      _errorMessage = 'Failed to submit application';
    }
    notifyListeners();
  }

  Future<void> loadApplicants(String postId) async {
    _state = RescueApplicationState.loading;
    notifyListeners();
    try {
      _applicants = await _repository.getApplicants(postId);
      _state = RescueApplicationState.success;
    } catch (e) {
      _state = RescueApplicationState.error;
      _errorMessage = 'Failed to load applicants';
    }
    notifyListeners();
  }
}
