import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/repositories/i_auth_repository.dart';

sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

class ForgotPasswordInitialState extends ForgotPasswordState {
  const ForgotPasswordInitialState();
}

class ForgotPasswordLoadingState extends ForgotPasswordState {
  const ForgotPasswordLoadingState();
}

class ForgotPasswordSuccessState extends ForgotPasswordState {
  const ForgotPasswordSuccessState();
}

class ForgotPasswordErrorState extends ForgotPasswordState {
  final String errorMessage;
  const ForgotPasswordErrorState(this.errorMessage);
}

class ForgotPasswordController extends ChangeNotifier {
  final IAuthRepository _repository;

  ForgotPasswordState _state = const ForgotPasswordInitialState();
  ForgotPasswordState get state => _state;

  String? email;
  String? verificationToken;

  bool _isPasswordObscured = true;
  bool get isPasswordObscured => _isPasswordObscured;

  bool _isConfirmPasswordObscured = true;
  bool get isConfirmPasswordObscured => _isConfirmPasswordObscured;

  ForgotPasswordController(this._repository);

  void _setState(ForgotPasswordState newState) {
    _state = newState;
    notifyListeners();
  }

  void resetState() {
    _setState(const ForgotPasswordInitialState());
  }

  void togglePasswordVisibility() {
    _isPasswordObscured = !_isPasswordObscured;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
    notifyListeners();
  }

  Future<bool> sendForgotPasswordCode(String emailAddress) async {
    email = emailAddress;
    _setState(const ForgotPasswordLoadingState());

    try {
      final response = await _repository.sendForgotPasswordCode(emailAddress);
      verificationToken = response.verificationToken;
      _setState(const ForgotPasswordSuccessState());
      return true;
    } on NetworkException catch (_) {
      resetState();
      rethrow;
    } on ApiException catch (e) {
      _setState(ForgotPasswordErrorState(e.message));
      return false;
    } catch (e) {
      _setState(
        const ForgotPasswordErrorState('An unexpected error occurred.'),
      );
      return false;
    }
  }

  Future<bool> verifyForgotPasswordCode(String otpCode) async {
    if (verificationToken == null) {
      _setState(
        const ForgotPasswordErrorState(
          'Verification token is missing. Please restart reset password.',
        ),
      );
      return false;
    }

    _setState(const ForgotPasswordLoadingState());

    try {
      await _repository.verifyForgotPasswordCode(
        verificationToken: verificationToken!,
        otpCode: otpCode,
      );
      _setState(const ForgotPasswordSuccessState());
      return true;
    } on NetworkException catch (_) {
      resetState();
      rethrow;
    } on UnauthorizedException catch (_) {
      _setState(
        const ForgotPasswordErrorState(
          'Incorrect or expired code. Please try again.',
        ),
      );
      return false;
    } on RateLimitException catch (e) {
      _setState(ForgotPasswordErrorState(e.message));
      return false;
    } on ApiException catch (e) {
      _setState(ForgotPasswordErrorState(e.message));
      return false;
    } catch (e) {
      _setState(
        const ForgotPasswordErrorState('An unexpected error occurred.'),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    if (verificationToken == null) {
      _setState(
        const ForgotPasswordErrorState(
          'Verification token is missing. Please restart reset password.',
        ),
      );
      return false;
    }

    _setState(const ForgotPasswordLoadingState());

    try {
      await _repository.resetPassword(
        verificationToken: verificationToken!,
        newPassword: newPassword,
      );
      _setState(const ForgotPasswordSuccessState());
      return true;
    } on NetworkException catch (_) {
      resetState();
      rethrow;
    } on UnauthorizedException catch (_) {
      _setState(
        const ForgotPasswordErrorState(
          'This reset link has expired. Please start again.',
        ),
      );
      return false;
    } on ApiException catch (e) {
      _setState(ForgotPasswordErrorState(e.message));
      return false;
    } catch (e) {
      _setState(
        const ForgotPasswordErrorState('An unexpected error occurred.'),
      );
      return false;
    }
  }
}
