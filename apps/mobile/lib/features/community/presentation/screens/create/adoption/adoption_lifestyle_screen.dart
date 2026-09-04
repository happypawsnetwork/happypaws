import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/interactive_toggle_card.dart';
import '../../../../../../core/widgets/pet_tag_cloud_field.dart';
import '../../../../../../core/widgets/selection_radio_card.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class AdoptionLifestyleScreen extends StatelessWidget {
  const AdoptionLifestyleScreen({super.key});

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
    final controller = context.watch<CreatePostController>();

    return Scaffold(
      appBar: const CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What kind of home does this animal need?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'These requirements help us match your post with the most compatible adopters.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // 1. Minimum home size required
            _sectionHeader(
              'Minimum home size required',
              'Select the smallest home type where this animal can thrive.',
            ),
            SelectionRadioCard(
              title: 'Apartment / Flat',
              description: 'Comfortable in compact indoor living spaces.',
              icon: Icons.apartment_rounded,
              isSelected: controller.lifestyleHomeSize == 'Apartment',
              onTap: () => controller.lifestyleHomeSize = 'Apartment',
            ),
            SelectionRadioCard(
              title: 'Single house',
              description: 'Needs a standard home with dedicated indoor areas.',
              icon: Icons.home_rounded,
              isSelected: controller.lifestyleHomeSize == 'SingleHouse',
              onTap: () => controller.lifestyleHomeSize = 'SingleHouse',
            ),
            SelectionRadioCard(
              title: 'Estate / Acreage',
              description: 'Needs a large property with open space to roam.',
              icon: Icons.landscape_rounded,
              isSelected: controller.lifestyleHomeSize == 'Estate',
              onTap: () => controller.lifestyleHomeSize = 'Estate',
            ),

            const SizedBox(height: 8),

            // 2. Enclosed yard required
            _sectionHeader(
              'Outdoor environment',
              'Does this animal need access to a safe enclosed outdoor space?',
            ),
            InteractiveToggleCard(
              title: 'Requires enclosed yard / garden',
              subtitle: 'Adopter must have a fenced or walled outdoor area.',
              icon: Icons.grass_rounded,
              value: controller.lifestyleRequiresEnclosedYard,
              onChanged: (val) =>
                  controller.lifestyleRequiresEnclosedYard = val,
            ),

            const SizedBox(height: 8),

            // 3. Good with children
            _sectionHeader(
              'Good with children',
              'Is this animal safe and comfortable around young children?',
            ),
            InteractiveToggleCard(
              title: 'Good with children',
              subtitle: 'Comfortable around children under 12 years old.',
              icon: Icons.family_restroom_rounded,
              value: controller.lifestyleGoodWithChildren,
              onChanged: (val) => controller.lifestyleGoodWithChildren = val,
            ),

            const SizedBox(height: 8),

            // 4. Required activity tempo
            _sectionHeader(
              'Required activity tempo',
              'What activity level does the ideal adopter household need?',
            ),
            SelectionRadioCard(
              title: 'Relaxed & calm',
              description: 'Low-energy home. Short walks and quiet indoors suit this animal.',
              icon: Icons.self_improvement_rounded,
              isSelected: controller.lifestyleActivityTempo == 'RelaxedAndCalm',
              onTap: () => controller.lifestyleActivityTempo = 'RelaxedAndCalm',
            ),
            SelectionRadioCard(
              title: 'Moderately active',
              description:
                  'Regular walks and playtime. Average active household.',
              icon: Icons.directions_walk_rounded,
              isSelected:
                  controller.lifestyleActivityTempo == 'ModeratelyActive',
              onTap: () =>
                  controller.lifestyleActivityTempo = 'ModeratelyActive',
            ),
            SelectionRadioCard(
              title: 'High energy',
              description:
                  'Needs daily runs, hikes, or highly active outdoor time.',
              icon: Icons.directions_run_rounded,
              isSelected: controller.lifestyleActivityTempo == 'HighEnergy',
              onTap: () => controller.lifestyleActivityTempo = 'HighEnergy',
            ),

            const SizedBox(height: 8),

            // 5. Good with pets
            _sectionHeader(
              'Good with pets',
              'Select the pet species this animal is compatible with.',
            ),
            PetTagCloudField(
              pets: controller.lifestyleGoodWithPets,
              onChanged: (updated) =>
                  controller.lifestyleGoodWithPets = updated,
            ),

            const SizedBox(height: 40),

            // Continue button
            Semantics(
              button: true,
              label: 'Continue to add photos',
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    context.push('/community/create/adoption/photos');
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
