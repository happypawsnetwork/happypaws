import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/models/onboarding_item.dart';
import 'widgets/animated_page_indicator.dart';
import 'widgets/onboarding_page_item.dart';

/// Onboarding carousel screen displaying introductory slides with automated and manual sliding.
class OnboardingScreen extends StatefulWidget {
  final List<OnboardingItem> items;
  final Duration autoSlideDuration;

  const OnboardingScreen({
    super.key,
    this.items = OnboardingItem.defaultItems,
    this.autoSlideDuration = const Duration(seconds: 4),
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPageIndex = 0;

  void _handleContinue() {
    context.push('/signup/email');
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlideTimer();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    if (widget.items.length <= 1) return;

    _autoSlideTimer = Timer.periodic(widget.autoSlideDuration, (_) {
      if (!_pageController.hasClients) return;

      final nextIndex = (_currentPageIndex + 1) % widget.items.length;
      final transitionDuration = nextIndex == 0
          ? const Duration(milliseconds: 800)
          : const Duration(milliseconds: 600);

      _pageController.animateToPage(
        nextIndex,
        duration: transitionDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    // Reset timer interval after manual or automated slide transitions
    _startAutoSlideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                itemCount: widget.items.length,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, index) {
                  return OnboardingPageItem(item: widget.items[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
            AnimatedPageIndicator(
              controller: _pageController,
              count: widget.items.length,
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Continue',
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Sign in to existing account',
                    child: InkWell(
                      onTap: () {
                        context.push('/login');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 104),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
