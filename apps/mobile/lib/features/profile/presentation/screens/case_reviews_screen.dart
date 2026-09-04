import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class CaseReviewsScreen extends StatelessWidget {
  final ScrollController? scrollController;
  final VoidCallback? onBack;
  final double? topPadding;

  const CaseReviewsScreen({
    super.key,
    this.scrollController,
    this.onBack,
    this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTopPadding =
        topPadding ?? MediaQuery.of(context).padding.top + 16;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Case Reviews',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: effectiveTopPadding > 32 ? 16 : effectiveTopPadding,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No pending case reviews',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rescue cases flagged for veterinary triage confirmation and medical guidance will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
