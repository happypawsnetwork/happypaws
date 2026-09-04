import 'package:flutter/material.dart';

import '../../domain/repositories/i_transport_repository.dart';

enum TransportState { idle, loading, success, error }

class TransportController extends ChangeNotifier {
  final ITransportRepository _repository;

  TransportState _state = TransportState.idle;
  TransportState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TransportController(this._repository);

  Future<void> createTransportTask(Map<String, dynamic> data) async {
    _state = TransportState.loading;
    notifyListeners();
    try {
      await _repository.createTask(data);
      _state = TransportState.success;
    } catch (e) {
      _state = TransportState.error;
      _errorMessage = 'Failed to create transport task';
    }
    notifyListeners();
  }

  // Other methods would be here...
}
