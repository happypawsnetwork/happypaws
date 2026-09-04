import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class SponsorPhotosScreen extends StatefulWidget {
  const SponsorPhotosScreen({super.key});

  @override
  State<SponsorPhotosScreen> createState() => _SponsorPhotosScreenState();
}

class _SponsorPhotosScreenState extends State<SponsorPhotosScreen> {
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _photos = List.from(controller.photos);
  }

  void _onNext() {
    final controller = context.read<CreatePostController>();
    controller.photos = List.from(_photos);
    context.push('/community/create/sponsor/review');
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _onNext,
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
