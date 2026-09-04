import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class SponsorAnimalScreen extends StatefulWidget {
  const SponsorAnimalScreen({super.key});

  @override
  State<SponsorAnimalScreen> createState() => _SponsorAnimalScreenState();
}

class _SponsorAnimalScreenState extends State<SponsorAnimalScreen> {
  final _speciesController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _speciesController.text = controller.species;
    _nameController.text = controller.animalName;
    _locationController.text = controller.locationLabel;

    _speciesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _getLocation() {
    setState(() {
      _locationController.text = 'Colombo, Sri Lanka'; // Stub
    });
  }

  void _onNext() {
    final controller = context.read<CreatePostController>();
    controller.species = _speciesController.text.trim();
    controller.animalName = _nameController.text.trim();
    controller.locationLabel = _locationController.text.trim();
    controller.lat = 6.9271; // Stub
    controller.lon = 79.8612; // Stub
    context.push('/community/create/sponsor/goal');
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = _speciesController.text.trim().isNotEmpty;

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
            child: FilledButton(
              onPressed: isNextEnabled ? _onNext : null,
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
