import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/models/post.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/create_post_app_bar.dart';

class FosterUpdateReviewScreen extends StatelessWidget {
  const FosterUpdateReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();
    final isSubmitting = controller.state == CreatePostState.submitting;

    // Build dummy post for preview
    final previewPost = Post(
      id: 'preview',
      type: PostType.fosterUpdate,
      status: PostStatus.active,
      title: controller.title,
      body: controller.body,
      createdAt: DateTime.now(),
      authorId: 0,
      authorDisplayName: 'You',
      isLikedByCurrentUser: false,
      likeCount: 0,
      photoCount: controller.photos.length,
      firstPhotoUrl: controller.photos.isNotEmpty
          ? controller.photos.first
          : null,
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
                'This is how your post will look in the feed.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PostCard(post: previewPost),
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      await controller.submitPost();
                      if (context.mounted) {
                        if (controller.state == CreatePostState.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Your update has been posted.',
                                style: GoogleFonts.outfit(),
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          context.go('/community/create/success');
                          controller.reset();
                        } else if (controller.state == CreatePostState.error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.errorMessage ??
                                    'Failed to post update.',
                                style: GoogleFonts.outfit(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
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
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Post update',
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
