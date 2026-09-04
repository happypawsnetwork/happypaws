import 'package:flutter/material.dart';

import '../../domain/repositories/i_auth_repository.dart';
import '../../../../core/network/api_exceptions.dart';

enum LoginState { idle, loading, success, error, adminBlocked }

class LoginController extends ChangeNotifier {
  final IAuthRepository _authRepository;

  LoginState _state = LoginState.idle;
  LoginState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isPasswordObscured = true;
  bool get isPasswordObscured => _isPasswordObscured;

  LoginController(this._authRepository);

  void togglePasswordVisibility() {
    _isPasswordObscured = !_isPasswordObscured;
    notifyListeners();
  }

  void clearForm() {
    _state = LoginState.idle;
    _errorMessage = null;
    _isPasswordObscured = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _state = LoginState.error;
      _errorMessage = 'Email and password are required';
      notifyListeners();
      return;
    }

    _state = LoginState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(email.trim(), password);
      _state = LoginState.success;
      notifyListeners();
    } on ForbiddenException {
      _state = LoginState.adminBlocked;
      notifyListeners();
    } on UnauthorizedException {
      _state = LoginState.error;
      _errorMessage = 'Invalid email or password.';
      notifyListeners();
    } on ApiException catch (e) {
      _state = LoginState.error;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _state = LoginState.error;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
    }
  }
}
