import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../../../controllers/create_post_controller.dart';
import '../../../controllers/community_controller.dart';
import '../../../../domain/models/post.dart';
import '../../../../domain/models/vet_request_details.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/create_post_app_bar.dart';

class VetReviewScreen extends StatefulWidget {
  const VetReviewScreen({super.key});

  @override
  State<VetReviewScreen> createState() => _VetReviewScreenState();
}

class _VetReviewScreenState extends State<VetReviewScreen> {
  Future<void> _submit() async {
    final controller = context.read<CreatePostController>();

    // Safety check, ensure type is set
    if (controller.selectedType == null) {
      controller.selectType(PostType.vetRequest);
    }

    await controller.submitPost();

    if (!mounted) return;

    if (controller.state == CreatePostState.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your treatment request has been posted.'),
        ),
      );

      // Refresh community feed
      context.read<CommunityController>().loadFeed(isRefresh: true);

      // Pop all the way back to the community feed
      context.go('/community/create/success');
    } else if (controller.state == CreatePostState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Failed to post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();

    final previewPost = Post(
      id: 'preview',
      type: PostType.vetRequest,
      status: PostStatus.active,
      title:
          'Vet Request for ${controller.animalName.isEmpty ? 'Animal' : controller.animalName}',
      body: controller.body,
      likeCount: 0,
      isLikedByCurrentUser: false,
      authorId: 1, // dummy
      authorDisplayName: 'You', // dummy
      locationLabel: controller.locationLabel,
      latitude: controller.lat,
      longitude: controller.lon,
      animalSpecies: controller.species,
      animalName: controller.animalName.isNotEmpty
          ? controller.animalName
          : null,
      photoCount: controller.photos.length,
      media: [], // We won't render local file previews in the dummy card yet, just photo count
      createdAt: DateTime.now(),
      vetDetails: VetRequestDetails(
        reasonForVisit: controller.body,
        clinicName: controller.clinicName.isNotEmpty
            ? controller.clinicName
            : null,
        appointmentDate: controller.vetVisitDate,
        transportNeeded: controller.needsTransport,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review and post',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preview',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              // Ignore pointers so user can't interact with the preview like button, etc
              child: PostCard(post: previewPost),
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
              onPressed: controller.state == CreatePostState.submitting
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.state == CreatePostState.submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Post treatment request',
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
