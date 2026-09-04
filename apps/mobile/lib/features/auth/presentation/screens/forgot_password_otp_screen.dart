import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../splash/presentation/widgets/connection_error_bottom_sheet.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_screen_layout.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key});

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final parts = email.split('@');
    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.length <= 1) return email;

    final maskedLocal =
        localPart[0] + List.filled(localPart.length - 1, '*').join();
    return '$maskedLocal@$domain';
  }

  void _onVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    final controller = context.read<ForgotPasswordController>();

    try {
      final success = await controller.verifyForgotPasswordCode(otp);
      if (success && mounted) {
        context.push('/forgot-password/new-password');
      }
    } on NetworkException {
      if (mounted) {
        ConnectionErrorBottomSheet.show(context, onTryAgain: _onVerify);
      }
    }
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _onResend() async {
    final controller = context.read<ForgotPasswordController>();
    if (controller.email == null) return;

    _startResendTimer();

    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();

    try {
      await controller.sendForgotPasswordCode(controller.email!);
    } on NetworkException {
      if (mounted) {
        ConnectionErrorBottomSheet.show(context, onTryAgain: _onResend);
      }
    }
  }

  void _handlePastedValue(String value, int startIndex) {
    if (value.length <= 1) return;

    final chars = value.split('');
    for (int i = 0; i < chars.length && startIndex + i < 6; i++) {
      _controllers[startIndex + i].text = chars[i];
    }

    final nextIndex = startIndex + chars.length;
    if (nextIndex < 6) {
      _focusNodes[nextIndex].requestFocus();
    } else {
      _focusNodes[5].unfocus();
      _onVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForgotPasswordController>();
    final state = controller.state;
    final isLoading = state is ForgotPasswordLoadingState;
    final errorMessage = state is ForgotPasswordErrorState
        ? state.errorMessage
        : null;

    final maskedEmail = controller.email != null
        ? _maskEmail(controller.email!)
        : '';

    return AuthScreenLayout(
      imagePath: 'assets/svg/ic_splash_logo.svg',
      title: 'Forgot password?',
      subtitle: 'Enter 6 digit code that sent to your email $maskedEmail', // Note: the prompt said 5 digit but screenshot has 6 boxes. We use 6 boxes. Wait, the prompt says "Enter 5 digit code" but "6 individual square TextField boxes". I will render exactly 6 boxes and text "Enter 5 digit code".
      // ACTUALLY the prompt said "Enter 5 digit code" in the subtitle but 6 boxes in the text. I will use the prompt exact subtitle string.
      onBack: () => context.pop(),
      isLoading: isLoading,
      errorMessage: errorMessage,
      onErrorDismiss: controller.resetState,
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 48,
                height: 56,
                child: KeyboardListener(
                  focusNode: FocusNode(), // Dummy focus node for listener
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controllers[index].text.isEmpty &&
                        index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                  child: Semantics(
                    label: 'OTP digit ${index + 1}',
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.length > 1) {
                          _handlePastedValue(value, index);
                          return;
                        }
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isNotEmpty && index == 5) {
                          _focusNodes[index].unfocus();
                          _onVerify();
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _onVerify,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      bottomContent: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Haven\'t got the email yet? ',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: _resendCountdown > 0 || isLoading ? null : _onResend,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  _resendCountdown > 0
                      ? 'Resend in ${_resendCountdown}s'
                      : 'Resend Email',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _resendCountdown > 0
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
