import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class RescueAnimalScreen extends StatefulWidget {
  const RescueAnimalScreen({super.key});

  @override
  State<RescueAnimalScreen> createState() => _RescueAnimalScreenState();
}

class _RescueAnimalScreenState extends State<RescueAnimalScreen> {
  late TextEditingController _speciesController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _speciesController = TextEditingController(text: controller.species);
    _nameController = TextEditingController(text: controller.animalName);
    _descController = TextEditingController(text: controller.body);
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<CreatePostController>();
      controller.species = _speciesController.text.trim();
      controller.animalName = _nameController.text.trim();
      controller.body = _descController.text.trim();
      context.push('/community/create/rescue/location');
    }
  }

  @override
  Widget build(BuildContext context) {
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
