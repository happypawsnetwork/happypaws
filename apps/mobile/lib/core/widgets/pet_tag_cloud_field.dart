import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Popular animal suggestions shown for quick selection in the modal bottom sheet.
const _popularAnimals = [
  'Dog',
  'Cat',
  'Bird',
  'Rabbit',
  'Fish',
  'Hamster',
  'Guinea pig',
  'Turtle',
  'Parrot',
  'Duck',
  'Goat',
  'Horse',
];

/// Renders the current list of added pets as dismissible chips with an inline "Add animal" button.
///
/// Tapping "Add animal" opens [AddPetModalBottomSheet]. The list is capped at 10
/// entries to prevent uncontrolled list growth.
class PetTagCloudField extends StatelessWidget {
  final List<String> pets;
  final ValueChanged<List<String>> onChanged;

  const PetTagCloudField({
    super.key,
    required this.pets,
    required this.onChanged,
  });

  Future<void> _openModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddPetModalBottomSheet(currentPets: pets, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...pets.map((pet) {
              return Chip(
                label: Text(pet),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final updated = List<String>.from(pets)..remove(pet);
                  onChanged(updated);
                },
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                deleteIconColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
            if (pets.length < 10)
              ActionChip(
                avatar: const Icon(
                  Icons.pets_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text('Add animal'),
                onPressed: () => _openModal(context),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
          ],
        ),
        if (pets.length >= 10)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Maximum 10 pets reached.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet for selecting an animal type or entering an unlisted animal.
class AddPetModalBottomSheet extends StatefulWidget {
  final List<String> currentPets;
  final ValueChanged<List<String>> onChanged;

  const AddPetModalBottomSheet({
    super.key,
    required this.currentPets,
    required this.onChanged,
  });

  @override
  State<AddPetModalBottomSheet> createState() => _AddPetModalBottomSheetState();
}

class _AddPetModalBottomSheetState extends State<AddPetModalBottomSheet> {
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectAnimal(String animal) {
    final trimmed = animal.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(widget.currentPets);
    if (!current.contains(trimmed) && current.length < 10) {
      current.add(trimmed);
      widget.onChanged(current);
      HapticFeedback.lightImpact();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 10 - widget.currentPets.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add animal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining > 0
                          ? 'Select an animal type or enter an unlisted one.'
                          : 'Maximum limit reached.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Popular animal options
          const Text(
            'Popular animal types',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularAnimals.map((animal) {
              final alreadyAdded = widget.currentPets.contains(animal);
              return ActionChip(
                avatar: alreadyAdded
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.primary,
                      )
                    : null,
                label: Text(animal),
                onPressed: (alreadyAdded || remaining <= 0)
                    ? null
                    : () => _selectAnimal(animal),
                backgroundColor: alreadyAdded
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFF8FAFC),
                disabledColor: AppColors.primary.withValues(alpha: 0.08),
                labelStyle: TextStyle(
                  color: alreadyAdded
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: alreadyAdded ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: alreadyAdded
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : const Color(0xFFE2E8F0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Custom / unlisted animal entry
          const Text(
            'Not listed? Add custom animal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  enabled: remaining > 0,
                  decoration: InputDecoration(
                    hintText: 'e.g. Ferret, Hedgehog, Lizard',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _selectAnimal(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: remaining > 0
                      ? () {
                          if (_customController.text.trim().isNotEmpty) {
                            _selectAnimal(_customController.text);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
