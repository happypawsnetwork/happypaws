import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class AdoptionAnimalScreen extends StatefulWidget {
  const AdoptionAnimalScreen({super.key});

  @override
  State<AdoptionAnimalScreen> createState() => _AdoptionAnimalScreenState();
}

class _AdoptionAnimalScreenState extends State<AdoptionAnimalScreen> {
  final _speciesController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _speciesController.text = controller.species;
    _nameController.text = controller.animalName;
    _descController.text = controller.body;

    _speciesController.addListener(_updateState);
    _nameController.addListener(_updateState);
    _descController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _speciesController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

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
              onPressed: _isValid
                  ? () {
                      final controller = context.read<CreatePostController>();
                      controller.species = _speciesController.text.trim();
                      controller.animalName = _nameController.text.trim();
                      controller.body = _descController.text.trim();
                      controller.title = "Adopt ${_nameController.text.trim()}";

                      if (controller.species.isNotEmpty &&
                          controller.animalName.isNotEmpty) {
                        context.push('/community/create/adoption/lifestyle');
                      }
                    }
                  : null,
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
