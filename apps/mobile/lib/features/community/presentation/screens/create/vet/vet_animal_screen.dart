import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class VetAnimalScreen extends StatefulWidget {
  const VetAnimalScreen({super.key});

  @override
  State<VetAnimalScreen> createState() => _VetAnimalScreenState();
}

class _VetAnimalScreenState extends State<VetAnimalScreen> {
  late TextEditingController _speciesController;
  late TextEditingController _animalNameController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _speciesController = TextEditingController(text: controller.species);
    _animalNameController = TextEditingController(text: controller.animalName);
    _locationController = TextEditingController(text: controller.locationLabel);
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _animalNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onNext() {
    final species = _speciesController.text.trim();
    if (species.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Species is required')));
      return;
    }

    final controller = context.read<CreatePostController>();
    controller.species = species;
    controller.animalName = _animalNameController.text.trim();
    controller.locationLabel = _locationController.text.trim();

    context.push('/community/create/vet/details');
  }

  void _autofillGps() {
    // Stub for GPS
    final controller = context.read<CreatePostController>();
    controller.lat = 6.9271;
    controller.lon = 79.8612;
    setState(() {
      _locationController.text = 'Colombo, Sri Lanka';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About the animal',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _speciesController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Species *',
                hintText: 'e.g., Dog, Cat',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _animalNameController,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Animal name',
                hintText: 'Leave blank if unknown',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Where is the animal located?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: AppColors.primary),
                  onPressed: _autofillGps,
                ),
              ),
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
              onPressed: _onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
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
