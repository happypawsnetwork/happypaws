import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/repositories/i_auth_repository.dart';

sealed class SignUpState {
  const SignUpState();
}

final class SignUpInitialState extends SignUpState {
  const SignUpInitialState();
}

final class SignUpLoadingState extends SignUpState {
  const SignUpLoadingState();
}

final class SignUpSuccessState extends SignUpState {
  const SignUpSuccessState();
}

final class SignUpErrorState extends SignUpState {
  final String errorMessage;
  const SignUpErrorState(this.errorMessage);
}

class SignUpController extends ChangeNotifier {
  final IAuthRepository _repository;

  SignUpState _state = const SignUpInitialState();
  SignUpState get state => _state;

  String? email;
  String? verificationToken;

  SignUpController(this._repository);

  void _setState(SignUpState newState) {
    _state = newState;
    notifyListeners();
  }

  void resetState() {
    _setState(const SignUpInitialState());
  }

  Future<bool> sendCode(String emailAddress) async {
    email = emailAddress;
    _setState(const SignUpLoadingState());

    try {
      final response = await _repository.sendRegistrationCode(emailAddress);
      verificationToken = response.verificationToken;
      _setState(const SignUpSuccessState());
      return true;
    } on ApiException catch (e) {
      _setState(SignUpErrorState(e.message));
      return false;
    } catch (e) {
      _setState(const SignUpErrorState('An unexpected error occurred.'));
      return false;
    }
  }

  Future<bool> verifyCode(String otpCode) async {
    if (verificationToken == null) {
      _setState(
        const SignUpErrorState(
          'Verification token is missing. Please restart sign up.',
        ),
      );
      return false;
    }

    _setState(const SignUpLoadingState());

    try {
      await _repository.verifyRegistrationCode(
        verificationToken: verificationToken!,
        otpCode: otpCode,
      );
      _setState(const SignUpSuccessState());
      return true;
    } on ApiException catch (e) {
      _setState(SignUpErrorState(e.message));
      return false;
    } catch (e) {
      _setState(const SignUpErrorState('An unexpected error occurred.'));
      return false;
    }
  }

  Future<bool> completeRegistration(String fullName, String password) async {
    if (verificationToken == null) {
      _setState(
        const SignUpErrorState(
          'Verification token is missing. Please restart sign up.',
        ),
      );
      return false;
    }

    _setState(const SignUpLoadingState());

    try {
      await _repository.completeRegistration(
        verificationToken: verificationToken!,
        fullName: fullName,
        password: password,
      );
      _setState(const SignUpSuccessState());
      return true;
    } on ApiException catch (e) {
      _setState(SignUpErrorState(e.message));
      return false;
    } catch (e) {
      _setState(const SignUpErrorState('An unexpected error occurred.'));
      return false;
    }
  }
}
