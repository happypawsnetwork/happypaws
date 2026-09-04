import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../../domain/models/post.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/create_post_app_bar.dart';

class HighlightReviewScreen extends StatelessWidget {
  const HighlightReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();

    // Create a mock post for preview
    final mockPost = Post(
      id: 'preview',
      type: PostType.highlight,
      status: PostStatus.active,
      title: controller.title,
      body: controller.body,
      likeCount: 0,
      isLikedByCurrentUser: false,
      authorId: 1, // Mock author ID
      authorDisplayName: 'You (Preview)',
      authorAvatarUrl: null,
      photoCount: controller.photos.length,
      firstPhotoUrl: controller.photos.isNotEmpty
          ? controller.photos.first
          : null,
      createdAt: DateTime.now(),
      media: const [], // We don't populate media here for preview, firstPhotoUrl is enough for PostCard
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
            // The PostCard itself uses horizontal margin of 16
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
                      await controller.submitPost();
                      if (context.mounted) {
                        if (controller.state == CreatePostState.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your highlight has been posted.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          // Pop all the way back to the community feed
                          context.go('/community/create/success');
                        } else if (controller.state == CreatePostState.error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.errorMessage ?? 'Failed to post',
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
                  alpha: 0.3,
                ),
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
                      'Post highlight',
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
