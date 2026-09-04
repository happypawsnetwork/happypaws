import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class RescueTriageScreen extends StatelessWidget {
  const RescueTriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();
    final isLoading = controller.isAssessingUrgency;
    final level = controller.urgencyLevel ?? 'Medium';
    final reason = controller.aiTriageReason;

    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (level) {
      case 'Critical':
        bgColor = UrgencyColors.criticalBg;
        borderColor = UrgencyColors.criticalBorder;
        textColor = UrgencyColors.criticalText;
        break;
      case 'High':
        bgColor = UrgencyColors.highBg;
        borderColor = UrgencyColors.highBorder;
        textColor = UrgencyColors.highText;
        break;
      case 'Low':
        bgColor = UrgencyColors.lowBg;
        borderColor = UrgencyColors.lowBorder;
        textColor = UrgencyColors.lowText;
        break;
      default:
        bgColor = UrgencyColors.mediumBg;
        borderColor = UrgencyColors.mediumBorder;
        textColor = UrgencyColors.mediumText;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI triage assessment',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our model analyzed your report to estimate incident urgency.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Urgency: $level',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      reason,
                      style: GoogleFonts.outfit(fontSize: 14, color: textColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.push('/community/create/rescue/animal');
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
