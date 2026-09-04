import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/sign_up_controller.dart';
import '../widgets/auth_screen_layout.dart';

class SignUpOtpScreen extends StatefulWidget {
  const SignUpOtpScreen({super.key});

  @override
  State<SignUpOtpScreen> createState() => _SignUpOtpScreenState();
}

class _SignUpOtpScreenState extends State<SignUpOtpScreen> {
  static const int _otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _resendTimer;
  int _resendCountdown = 30;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    setState(() => _resendCountdown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final otp = _otpCode;
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit code'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final controller = context.read<SignUpController>();
    final success = await controller.verifyCode(otp);

    if (success && mounted) {
      context.push('/signup/profile');
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;

    final controller = context.read<SignUpController>();
    if (controller.email != null) {
      final success = await controller.sendCode(controller.email!);
      if (success && mounted) {
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
        _startTimer();
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= _otpLength) {
        _focusNodes[_otpLength - 1].unfocus();
        _handleVerify();
      } else {
        _focusNodes[digits.length.clamp(0, _otpLength - 1)].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otpCode.length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SignUpController>();
    final state = controller.state;

    return AuthScreenLayout(
      imagePath: 'assets/images/illus_signup_verify.png',
      title: 'Verify your email address',
      subtitle: "We've sent a 6-digit code to verify your\nemail address",
      useOutfit: false,
      isLoading: state is SignUpLoadingState,
      errorMessage: state is SignUpErrorState ? state.errorMessage : null,
      onErrorDismiss: controller.resetState,
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (index) {
              final isFilled = _controllers[index].text.isNotEmpty;

              return SizedBox(
                width: 48,
                height: 56,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controllers[index].text.isEmpty &&
                        index > 0) {
                      _focusNodes[index - 1].requestFocus();
                      _controllers[index - 1].clear();
                    }
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isFilled
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: isFilled ? 2 : 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    onChanged: (val) => _onDigitChanged(index, val),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          Semantics(
            button: true,
            label: 'Verify',
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state is SignUpLoadingState ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomContent: TextButton(
        onPressed: _resendCountdown == 0 ? _handleResend : null,
        child: Text(
          _resendCountdown > 0
              ? 'Resend code in ${_resendCountdown}s'
              : 'Resend code',
          style: TextStyle(
            color: _resendCountdown > 0
                ? const Color(0xFF94A3B8)
                : AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
