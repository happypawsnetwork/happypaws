import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class SponsorProofScreen extends StatefulWidget {
  const SponsorProofScreen({super.key});

  @override
  State<SponsorProofScreen> createState() => _SponsorProofScreenState();
}

class _SponsorProofScreenState extends State<SponsorProofScreen> {
  List<String> _docs = [];

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _docs = List.from(controller.sponsorProofDocs);
  }

  void _onNext() {
    final controller = context.read<CreatePostController>();
    controller.sponsorProofDocs = List.from(_docs);
    context.push('/community/create/sponsor/photos');
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = _docs.isNotEmpty && _docs.length <= 5;

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
              onPressed: isNextEnabled ? _onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
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
