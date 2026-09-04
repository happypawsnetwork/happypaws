import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/post.dart';
import '../../controllers/create_post_controller.dart';
import '../../widgets/create_post_app_bar.dart';

/// Screen allowing the user to select what kind of post they want to create.
///
/// This screen resets the creation draft state and directs the user to the
/// corresponding first step of the creation wizard.
class PickTypeScreen extends StatelessWidget {
  const PickTypeScreen({super.key});

  static const List<_PostTypeOption> _options = [
    _PostTypeOption(
      type: PostType.rescueAlert,
      title: 'Rescue alert',
      description:
          'Report an animal in immediate distress to alert nearby volunteers.',
      accentColor: PostTypeColors.rescue,
      icon: Icons.emergency_rounded,
      route: '/community/create/rescue/photos',
    ),
    _PostTypeOption(
      type: PostType.fosterUpdate,
      title: 'Foster update',
      description: 'Share progress notes, recovery milestones, and photos for an animal you foster.',
      accentColor: PostTypeColors.update,
      icon: Icons.pets_rounded,
      route: '/community/create/foster-update/link-rescue',
    ),
    _PostTypeOption(
      type: PostType.adoptionListing,
      title: 'Find home',
      description: 'Create an adoption listing to help a rescue or family pet find a loving home.',
      accentColor: PostTypeColors.findHome,
      icon: Icons.home_rounded,
      route: '/community/create/adoption/animal',
    ),
    _PostTypeOption(
      type: PostType.highlight,
      title: 'Highlight',
      description: 'Share celebratory moments, adorable photos, and stories with the community.',
      accentColor: PostTypeColors.highlight,
      icon: Icons.auto_awesome_rounded,
      route: '/community/create/highlight/content',
    ),
    _PostTypeOption(
      type: PostType.transportRequest,
      title: 'Transport request',
      description: 'Request volunteer drivers to help move an animal between safe locations.',
      accentColor: PostTypeColors.transport,
      icon: Icons.directions_car_rounded,
      route: '/community/create/transport/pickup',
    ),
    _PostTypeOption(
      type: PostType.vetRequest,
      title: 'Treatment request',
      description: 'Request veterinary care, surgery, medication, or wellness clinic visits.',
      accentColor: PostTypeColors.treatment,
      icon: Icons.medical_services_rounded,
      route: '/community/create/vet/animal',
    ),
    _PostTypeOption(
      type: PostType.sponsorshipRequest,
      title: 'Sponsorship request',
      description: 'Seek funding assistance from community sponsors for urgent medical or shelter costs.',
      accentColor: PostTypeColors.sponsor,
      icon: Icons.volunteer_activism_rounded,
      route: '/community/create/sponsor/animal',
    ),
  ];

  void _handleSelectOption(BuildContext context, _PostTypeOption option) {
    final controller = context.read<CreatePostController>();
    controller.reset();
    controller.selectType(option.type);
    context.push(option.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
          itemCount: _options.length + 1,
          separatorBuilder: (context, index) {
            if (index == 0) {
              return const SizedBox(height: 20.0);
            }
            return const SizedBox(height: 12.0);
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What would you like to share?',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a category below to begin your post, alert, or request.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }

            final option = _options[index - 1];
            return Semantics(
              button: true,
              label: '\${option.title}, \${option.description}',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleSelectOption(context, option),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: option.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              option.icon,
                              color: option.accentColor,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.description,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostTypeOption {
  final PostType type;
  final String title;
  final String description;
  final Color accentColor;
  final IconData icon;
  final String route;

  const _PostTypeOption({
    required this.type,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.route,
  });
}
