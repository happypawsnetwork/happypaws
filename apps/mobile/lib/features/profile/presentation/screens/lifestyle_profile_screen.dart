import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/interactive_toggle_card.dart';
import '../../../../core/widgets/pet_tag_cloud_field.dart';
import '../../../../core/widgets/selection_radio_card.dart';
import '../../domain/models/lifestyle_profile.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/lifestyle_profile_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/image_cropper_screen.dart';

/// Screen allowing users to inspect and update their pet adoption lifestyle preferences.
class LifestyleProfileScreen extends StatefulWidget {
  const LifestyleProfileScreen({super.key});

  @override
  State<LifestyleProfileScreen> createState() => _LifestyleProfileScreenState();
}

class _LifestyleProfileScreenState extends State<LifestyleProfileScreen> {
  String? _homeSize;
  bool _hasEnclosedYard = false;
  bool _hasChildren = false;
  String? _activityTempo;
  List<String> _existingPets = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final profileController = context.read<ProfileController>();
    final lifestyleController = context.read<LifestyleProfileController>();
    if (profileController.userProfile == null) {
      await profileController.loadProfile();
    }
    if (!mounted) return;
    await lifestyleController.loadLifestyleProfile();

    if (mounted && lifestyleController.profile != null) {
      final lp = lifestyleController.profile!;
      setState(() {
        _homeSize = lp.homeSize;
        _hasEnclosedYard = lp.hasEnclosedYard;
        _hasChildren = lp.hasChildren;
        _activityTempo = lp.activityTempo;
        _existingPets = List<String>.from(lp.existingPets);
        _isInitialized = true;
      });
    } else if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        final croppedFile = await ImageCropperScreen.cropImage(
          context,
          File(pickedFile.path),
        );
        if (croppedFile == null || !mounted) return;

        final controller = context.read<EditProfileController>();
        final success = await controller.updateAvatar(croppedFile);
        if (success && mounted) {
          await context.read<ProfileController>().loadProfile(
            forceRefresh: true,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avatar updated successfully')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                controller.errorMessage ?? 'Failed to update avatar',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change profile picture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Take photo',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final lifestyleController = context.read<LifestyleProfileController>();
    final updated = LifestyleProfile(
      homeSize: _homeSize,
      hasEnclosedYard: _hasEnclosedYard,
      hasChildren: _hasChildren,
      activityTempo: _activityTempo,
      existingPets: List<String>.from(_existingPets),
    );

    final success = await lifestyleController.saveLifestyleProfile(updated);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lifestyle profile updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lifestyleController.errorMessage ??
                  'Failed to update lifestyle profile',
            ),
          ),
        );
      }
    }
  }

  Widget _sectionHeader(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileController>().userProfile;
    final lifestyleState = context.watch<LifestyleProfileController>();
    final isSaving = lifestyleState.isSaving;
    final isLoading = lifestyleState.isLoading && !_isInitialized;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header banner ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const SizedBox(height: 245, width: double.infinity),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 180,
                        child: const Opacity(
                          opacity: 0.24,
                          child: Image(
                            image: AssetImage(
                              'assets/images/pattern_pet_paws.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 130,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage:
                                      user?.avatarUrl != null &&
                                          user!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child:
                                      user?.avatarUrl == null ||
                                          user!.avatarUrl!.isEmpty
                                      ? Text(
                                          user?.name.isNotEmpty == true
                                              ? user!.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Semantics(
                                  button: true,
                                  label: 'Change profile picture',
                                  child: GestureDetector(
                                    onTap: _showImageSourcePicker,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (user?.username != null && user!.username!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Lifestyle profile',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Set your living arrangements and activity pace to discover compatible pet adoptions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Questions ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Home size
                        _sectionHeader(
                          'Home size & space',
                          'Select the dwelling type that best matches your primary residence.',
                        ),
                        SelectionRadioCard(
                          title: 'Apartment / Flat',
                          description: 'Compact indoor living space, ideal for low to moderate energy pets.',
                          icon: Icons.apartment_rounded,
                          isSelected: _homeSize == 'Apartment',
                          onTap: () => setState(() => _homeSize = 'Apartment'),
                        ),
                        SelectionRadioCard(
                          title: 'Single house',
                          description: 'Standard detached home with dedicated living areas and rooms.',
                          icon: Icons.home_rounded,
                          isSelected: _homeSize == 'SingleHouse',
                          onTap: () =>
                              setState(() => _homeSize = 'SingleHouse'),
                        ),
                        SelectionRadioCard(
                          title: 'Estate / Acreage',
                          description: 'Large property with extensive indoor space and surrounding grounds.',
                          icon: Icons.landscape_rounded,
                          isSelected: _homeSize == 'Estate',
                          onTap: () => setState(() => _homeSize = 'Estate'),
                        ),

                        const SizedBox(height: 8),

                        // 2. Outdoor environment
                        _sectionHeader(
                          'Outdoor environment',
                          'Yard and outdoor access are essential for higher energy dogs and active pets.',
                        ),
                        InteractiveToggleCard(
                          title: 'Enclosed yard / garden space',
                          subtitle: 'Private, fenced, or walled outdoor area accessible from home.',
                          icon: Icons.grass_rounded,
                          value: _hasEnclosedYard,
                          onChanged: (val) =>
                              setState(() => _hasEnclosedYard = val),
                        ),

                        const SizedBox(height: 8),

                        // 3. Household members
                        _sectionHeader(
                          'Household members',
                          'Helps us match animals that thrive around your family.',
                        ),
                        InteractiveToggleCard(
                          title: 'Children in household',
                          subtitle:
                              'Household includes children under 12 years old.',
                          icon: Icons.family_restroom_rounded,
                          value: _hasChildren,
                          onChanged: (val) =>
                              setState(() => _hasChildren = val),
                        ),

                        const SizedBox(height: 8),

                        // 4. Activity tempo
                        _sectionHeader(
                          'Household activity tempo',
                          'Your daily routine determines the energy level of pets that will fit well.',
                        ),
                        SelectionRadioCard(
                          title: 'Relaxed & calm',
                          description: 'Quiet home, short daily walks, plenty of rest time.',
                          icon: Icons.self_improvement_rounded,
                          isSelected: _activityTempo == 'RelaxedAndCalm',
                          onTap: () =>
                              setState(() => _activityTempo = 'RelaxedAndCalm'),
                        ),
                        SelectionRadioCard(
                          title: 'Moderately active',
                          description:
                              'Regular walks and playtime, active on weekends.',
                          icon: Icons.directions_walk_rounded,
                          isSelected: _activityTempo == 'ModeratelyActive',
                          onTap: () => setState(
                            () => _activityTempo = 'ModeratelyActive',
                          ),
                        ),
                        SelectionRadioCard(
                          title: 'High energy',
                          description: 'Daily runs, hikes, or outdoor sports. Always on the move.',
                          icon: Icons.directions_run_rounded,
                          isSelected: _activityTempo == 'HighEnergy',
                          onTap: () =>
                              setState(() => _activityTempo = 'HighEnergy'),
                        ),

                        const SizedBox(height: 8),

                        // 5. Existing pets
                        _sectionHeader(
                          'Existing pets in household',
                          'Add the pets you currently have at home. Up to 10.',
                        ),
                        PetTagCloudField(
                          pets: _existingPets,
                          onChanged: (updated) =>
                              setState(() => _existingPets = updated),
                        ),

                        const SizedBox(height: 40),

                        // Save button
                        Semantics(
                          button: true,
                          label: 'Save lifestyle profile',
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isSaving ? null : _saveProfile,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Save lifestyle profile',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
