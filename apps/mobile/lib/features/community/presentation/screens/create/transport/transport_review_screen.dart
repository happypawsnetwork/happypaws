import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../../../controllers/create_post_controller.dart';
import '../../../../domain/models/post.dart';
import '../../../widgets/create_post_app_bar.dart';

class TransportReviewScreen extends StatelessWidget {
  const TransportReviewScreen({super.key});

  void _submit(BuildContext context) async {
    final controller = context.read<CreatePostController>();
    await controller.submitPost();

    if (context.mounted) {
      if (controller.state == CreatePostState.success) {
        context.go('/community/create/success');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your transport request has been posted.'),
          ),
        );
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
