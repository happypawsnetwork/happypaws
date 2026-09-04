import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../../../controllers/create_post_controller.dart';
import '../../../../domain/models/post.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/create_post_app_bar.dart';

class TransportReviewScreen extends StatelessWidget {
  const TransportReviewScreen({super.key});

  Future<void> _submit(BuildContext context) async {
    final controller = context.read<CreatePostController>();
    await controller.submitPost();
    if (context.mounted) {
      if (controller.state == CreatePostState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your transport request has been posted.'),
          ),
        );
        context.go('/community/create/success');
      } else if (controller.state == CreatePostState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Failed to post.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();

    final mockPost = Post(
      id: 'preview',
      type: PostType.transportRequest,
      status: PostStatus.active,
      title: controller.title,
      body: controller.body,
      likeCount: 0,
      isLikedByCurrentUser: false,
      authorId: 0,
      authorDisplayName: 'You',
      locationLabel:
          '${controller.locationLabel} → ${controller.dropoffLocationLabel}',
      animalSpecies: controller.species,
      animalName: controller.animalName,
      photoCount: controller.photos.length,
      media: const [],
      createdAt: DateTime.now(),
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
                'This is how your transport request will look in the feed.',
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
            child: controller.state == CreatePostState.submitting
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: () => _submit(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Post transport request',
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
