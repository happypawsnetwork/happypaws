import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../../domain/models/post.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/create_post_app_bar.dart';

class RescueReviewScreen extends StatelessWidget {
  const RescueReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();

    final mockPost = Post(
      id: 'preview',
      type: PostType.rescueAlert,
      status: PostStatus.active,
      title: 'Rescue needed: ${controller.species}',
      body: controller.body,
      likeCount: 0,
      isLikedByCurrentUser: false,
      authorId: 0,
      authorDisplayName: 'You',
      photoCount: controller.photos.length,
      createdAt: DateTime.now(),
      firstPhotoUrl: controller.photos.isNotEmpty
          ? controller.photos.first
          : null,
      animalSpecies: controller.species,
      animalName: controller.animalName,
      locationLabel: controller.locationLabel,
      urgencyLevel: controller.urgencyLevel,
      aiTriageReason: controller.aiTriageReason,
      media: [],
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
                'This is how your rescue alert will look in the feed.',
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
            child: FilledButton(
              onPressed: controller.state == CreatePostState.submitting
                  ? null
                  : () async {
                      controller.title = 'Rescue needed: ${controller.species}';
                      await controller.submitPost();
                      if (context.mounted) {
                        if (controller.state == CreatePostState.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your rescue alert has been posted.',
                              ),
                            ),
                          );
                          context.go('/community/create/success');
                        } else if (controller.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(controller.errorMessage!)),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.state == CreatePostState.submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Post rescue',
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
