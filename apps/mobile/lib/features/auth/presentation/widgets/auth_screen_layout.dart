import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Reusable layout wrapper matching the Happy Paws onboarding and auth design system.
class AuthScreenLayout extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final Widget formContent;
  final Widget? bottomContent;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onErrorDismiss;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool useOutfit;

  const AuthScreenLayout({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.formContent,
    this.bottomContent,
    this.isLoading = false,
    this.errorMessage,
    this.onErrorDismiss,
    this.showBackButton = true,
    this.onBack,
    this.useOutfit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top navigation bar with circular back button
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    top: 12.0,
                    right: 20.0,
                  ),
                  child: Row(
                    children: [
                      if (showBackButton)
                        Semantics(
                          button: true,
                          label: 'Back',
                          child: InkWell(
                            onTap:
                                onBack ??
                                () => Navigator.of(context).maybePop(),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                size: 28,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                Center(
                                  child:
                                      imagePath.toLowerCase().endsWith('.svg')
                                      ? SvgPicture.asset(
                                          imagePath,
                                          height: 210,
                                          fit: BoxFit.contain,
                                          excludeFromSemantics: true,
                                        )
                                      : Image.asset(
                                          imagePath,
                                          height: 210,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.medium,
                                          excludeFromSemantics: true,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  height: 210,
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 64,
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                );
                                              },
                                        ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: useOutfit
                                      ? GoogleFonts.outfit(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF303036),
                                          letterSpacing: -0.5,
                                          height: 1.2,
                                        )
                                      : const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF303036),
                                          letterSpacing: -0.5,
                                          height: 1.2,
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: useOutfit
                                      ? GoogleFonts.outfit(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                          height: 1.45,
                                        )
                                      : const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                          height: 1.45,
                                        ),
                                ),
                                const SizedBox(height: 28),
                                if (errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Color(0xFFDC2626),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            errorMessage!,
                                            style: useOutfit
                                                ? GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFF991B1B,
                                                    ),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w500,
                                                  )
                                                : const TextStyle(
                                                    color: Color(0xFF991B1B),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                          ),
                                        ),
                                        if (onErrorDismiss != null)
                                          GestureDetector(
                                            onTap: onErrorDismiss,
                                            child: const Icon(
                                              Icons.close,
                                              color: Color(0xFFDC2626),
                                              size: 18,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                formContent,
                                if (bottomContent != null) ...[
                                  const SizedBox(height: 20),
                                  bottomContent!,
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
