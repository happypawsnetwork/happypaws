import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class RescuePhotosScreen extends StatefulWidget {
  const RescuePhotosScreen({super.key});

  @override
  State<RescuePhotosScreen> createState() => _RescuePhotosScreenState();
}

class _RescuePhotosScreenState extends State<RescuePhotosScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();
    final canGoNext = controller.photos.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: Container(
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
              onPressed: canGoNext
                  ? () {
                      controller.assessRescueUrgency();
                      context.push('/community/create/rescue/triage');
                    }
                  : null,
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
