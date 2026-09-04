import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/sign_up_controller.dart';
import '../widgets/auth_screen_layout.dart';

class SignUpProfileScreen extends StatefulWidget {
  const SignUpProfileScreen({super.key});

  @override
  State<SignUpProfileScreen> createState() => _SignUpProfileScreenState();
}

class _SignUpProfileScreenState extends State<SignUpProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final name = _nameController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      _showError('Passwords do not match');
      return;
    }

    final controller = context.read<SignUpController>();
    final success = await controller.completeRegistration(name, pass);

    if (success && mounted) {
      context.go('/signup/complete');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool? obscureState,
    VoidCallback? onToggleObscure,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && (obscureState ?? true),
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (obscureState ?? true)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SignUpController>();
    final state = controller.state;

    return AuthScreenLayout(
      imagePath: 'assets/images/illus_signup_profile.png',
      title: 'Tell us a bit about yourself',
      subtitle: 'Just a few final details to secure your account and\nset up your public profile.',
      useOutfit: false,
      isLoading: state is SignUpLoadingState,
      errorMessage: state is SignUpErrorState ? state.errorMessage : null,
      onErrorDismiss: controller.resetState,
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledField(
            label: 'Your Name',
            controller: _nameController,
            hint: 'Enter your full name',
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'New Password',
            controller: _passwordController,
            hint: '••••••••••••',
            isPassword: true,
            obscureState: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            hint: '••••••••••••',
            isPassword: true,
            obscureState: _obscureConfirmPassword,
            onToggleObscure: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          const SizedBox(height: 28),
          Semantics(
            button: true,
            label: 'Create Account',
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state is SignUpLoadingState
                    ? null
                    : _handleCreateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
