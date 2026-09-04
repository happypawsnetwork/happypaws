import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../../domain/models/post.dart';
import '../../../../domain/models/sponsorship_details.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/create_post_app_bar.dart';

class SponsorReviewScreen extends StatefulWidget {
  const SponsorReviewScreen({super.key});

  @override
  State<SponsorReviewScreen> createState() => _SponsorReviewScreenState();
}

class _SponsorReviewScreenState extends State<SponsorReviewScreen> {
  Future<void> _submit() async {
    final controller = context.read<CreatePostController>();
    await controller.submitPost();

    if (mounted) {
      if (controller.state == CreatePostState.success) {
        context.go('/community/create/success');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your sponsorship request has been submitted.'),
          ),
        );
      } else if (controller.state == CreatePostState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Error submitting post.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();
    final isSubmitting = controller.state == CreatePostState.submitting;

    final mockPost = Post(
      id: 'preview',
      type: PostType.sponsorshipRequest,
      status: PostStatus.pendingApproval,
      title: controller.title,
      body: controller.body,
      likeCount: 0,
      isLikedByCurrentUser: false,
      authorId: 1,
      authorDisplayName: 'You',
      locationLabel: controller.locationLabel,
      animalSpecies: controller.species,
      animalName: controller.animalName,
      firstPhotoUrl: controller.photos.isNotEmpty
          ? 'https://via.placeholder.com/400x200'
          : null,
      photoCount: controller.photos.length,
      createdAt: DateTime.now(),
      media: [],
      sponsorshipDetails: SponsorshipDetails(
        goalDescription: controller.body,
        estimatedAmountLkr: controller.sponsorAmount,
        proofDocumentCount: controller.sponsorProofDocs.length,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Review and post',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'This is how your sponsorship request will look in the feed.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PostCard(post: mockPost),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your post will be visible in the community after an admin reviews it.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit for review',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
